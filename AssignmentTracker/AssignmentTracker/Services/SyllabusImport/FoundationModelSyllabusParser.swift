import Foundation
import FoundationModels

/// Detects syllabus items with Apple's on-device language model (guided generation).
///
/// The model only copies what the syllabus says, including each date exactly as written;
/// `SyllabusDateResolver` then turns that text into dates. Keeping date arithmetic out of the
/// model means it can't invent a date, and every resolution is deterministic and tested.
nonisolated struct FoundationModelSyllabusParser {
    enum Unavailable: Error, Equatable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case other

        var explanation: String {
            switch self {
            case .deviceNotEligible: "This device doesn’t support Apple Intelligence"
            case .appleIntelligenceNotEnabled: "Apple Intelligence is turned off"
            case .modelNotReady: "The Apple Intelligence model is still downloading"
            case .other: "Apple Intelligence isn’t available right now"
            }
        }
    }

    /// Characters per request. The on-device context window is about 4,096 tokens and has to
    /// hold the instructions, the schema and the answer too.
    static let chunkSize = 2_200

    static var availability: Result<Void, Unavailable> {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .success(())
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .failure(.deviceNotEligible)
            case .appleIntelligenceNotEnabled: return .failure(.appleIntelligenceNotEnabled)
            case .modelNotReady: return .failure(.modelNotReady)
            @unknown default: return .failure(.other)
            }
        }
    }

    struct ChunkFailure: Error {}

    /// Reads the syllabus in chunks. A chunk that fails (a guardrail, or a response too long
    /// for the context window) is split and retried, and if it still fails it's skipped, so one
    /// bad passage can't discard what the other chunks found. Throws only if every chunk failed,
    /// or `CancellationError` if the task is cancelled.
    /// `progress` gets (chunks done, total chunks).
    @concurrent
    func parse(
        _ text: String, progress: @Sendable (Int, Int) async -> Void = { _, _ in }
    ) async throws -> (items: [DetectedItem], termStartText: String?) {
        var items: [DetectedItem] = []
        var termStartText: String?
        let chunks = Self.chunks(of: text)
        var failures = 0

        for (index, chunk) in chunks.enumerated() {
            try Task.checkCancellation()
            await progress(index, chunks.count)
            do {
                for generated in try await Self.generate(chunk) {
                    if termStartText == nil, !generated.firstDayOfClasses.isEmpty {
                        termStartText = generated.firstDayOfClasses
                    }
                    items += generated.items.compactMap { Self.detectedItem(from: $0, source: chunk) }
                }
            } catch {
                // A cancelled import isn't a failed chunk; stop rather than read the rest.
                if error is CancellationError || Task.isCancelled { throw CancellationError() }
                failures += 1
            }
        }
        await progress(chunks.count, chunks.count)
        if failures == chunks.count { throw ChunkFailure() }
        return (items, termStartText)
    }

    /// One request, split in half and retried when the passage is too long for the model or
    /// trips a guardrail, so the rest of the passage still gets read.
    private static func generate(_ chunk: String, depth: Int = 0) async throws -> [GeneratedSyllabus] {
        // A fresh session per request keeps each one inside the context window.
        let session = LanguageModelSession(instructions: instructions)
        do {
            let response = try await session.respond(
                to: "Syllabus text:\n\n\(chunk)",
                generating: GeneratedSyllabus.self,
                options: GenerationOptions(samplingMode: .greedy)
            )
            return [response.content]
        } catch let error as LanguageModelSession.GenerationError where depth < 2 && error.isWorthSplitting {
            let halves = halve(chunk)
            guard halves.count == 2 else { throw ChunkFailure() }
            var results: [GeneratedSyllabus] = []
            for half in halves {
                try Task.checkCancellation()
                results += (try? await generate(half, depth: depth + 1)) ?? []
            }
            if results.isEmpty { throw ChunkFailure() }
            return results
        }
    }

    private static func halve(_ chunk: String) -> [String] {
        let lines = chunk.components(separatedBy: .newlines)
        guard lines.count >= 2 else { return [chunk] }
        let middle = lines.count / 2
        return [lines[..<middle].joined(separator: "\n"), lines[middle...].joined(separator: "\n")]
    }

    private static let instructions = """
        You extract graded work from a college course syllabus. List EVERY assignment, homework, \
        problem set, worksheet, discussion post, journal, essay, paper, lab, quiz, exam, project, \
        presentation, milestone and required reading that has a due date or scheduled date. \
        Schedule tables use " | " between columns: one row can hold several items, so list each \
        one separately with that row's date. Do not stop early or summarize; include every item. \
        Skip lecture topics, holidays, office hours and policies. \
        Copy titles and dates exactly as written. Never calculate or guess dates.
        """

    /// Splits at line breaks. Each chunk after the first repeats the latest "Week N" header and
    /// date heading ("Friday, October 9") so the lines under them keep their date.
    static func chunks(of text: String) -> [String] {
        let finder = SyllabusDateResolver()
        var chunks: [String] = []
        var current = ""
        var lastWeekHeader: String?
        var lastDateHeading: String?
        for line in text.components(separatedBy: .newlines).flatMap(pieces(of:)) {
            if current.count + line.count > chunkSize, !current.isEmpty {
                chunks.append(current)
                current = [lastWeekHeader, lastDateHeading].compactMap { $0.map { "\($0)\n" } }.joined()
            }
            if line.range(of: #"^\s*(week|wk\.?)\s*\d"#, options: [.regularExpression, .caseInsensitive]) != nil {
                lastWeekHeader = line
                lastDateHeading = nil
            } else if RuleBasedSyllabusParser.dateHeading(in: line, finder: finder) != nil {
                lastDateHeading = line
            }
            current += line + "\n"
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { chunks.append(current) }
        return chunks
    }

    /// A line longer than a chunk (a paragraph with no line breaks) split at sentence ends, or
    /// at spaces when a sentence is too long too, since `generate` can only halve at line breaks.
    static func pieces(of line: String) -> [String] {
        guard line.count > chunkSize else { return [line] }
        var pieces: [String] = []
        var current = ""
        for word in line.split(separator: " ") {
            if !current.isEmpty, current.count + word.count + 1 > chunkSize {
                pieces.append(current)
                current = ""
            }
            current += current.isEmpty ? String(word) : " \(word)"
            // Past halfway, end the piece at the next sentence end.
            if word.hasSuffix("."), current.count > chunkSize / 2 {
                pieces.append(current)
                current = ""
            }
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces
    }

    /// Drops items the source text doesn't back up, so a hallucinated title can't slip through.
    static func detectedItem(from item: GeneratedItem, source: String) -> DetectedItem? {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.count >= 2 else { return nil }
        let normalizedTitle = RuleBasedSyllabusParser.normalized(title)
        let normalizedSource = RuleBasedSyllabusParser.normalized(source)
        let sourceWords = Set(normalizedSource.split(separator: " ").map(String.init))
        let words = normalizedTitle.split(separator: " ").filter { $0.count > 2 }
        if words.isEmpty {
            // "PS 3", "HW 1": too short to check word by word, so they must appear as written.
            guard !normalizedTitle.isEmpty, " \(normalizedSource) ".contains(" \(normalizedTitle) ") else { return nil }
        } else {
            // Whole words, so "lab" doesn't match inside "syllabus".
            let found = words.filter { sourceWords.contains(String($0)) }
            guard Double(found.count) / Double(words.count) >= 0.5 else { return nil }
        }

        let dateText = item.dateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawWeight = item.weight.trimmingCharacters(in: .whitespacesAndNewlines)
        var weight = rawWeight.isEmpty ? nil : RuleBasedSyllabusParser.weight(in: rawWeight) ?? rawWeight
        if let stated = weight, !lineStates(weight: stated, for: title, in: source) {
            weight = nil
        }
        return DetectedItem(
            title: title,
            kind: item.kind.assignmentKind,
            dateText: dateText.isEmpty ? nil : dateText,
            dateFoundInSource: dateText.isEmpty || sourceBacks(dateText: dateText, in: source),
            weight: weight,
            notes: item.details.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// True when every number, month and weekday in the model's date also appears in the source.
    /// Its parts can sit on different lines ("Week 3" header, "Fri: Quiz 1"), so they're checked
    /// separately; a reworded ("10/12" → "Oct 12") or invented date fails.
    static func sourceBacks(dateText: String, in source: String) -> Bool {
        let sourceNumbers = Set(numbers(in: source))
        let sourceNames = Set(RuleBasedSyllabusParser.normalized(source).split(separator: " ").compactMap(calendarName))
        let words = RuleBasedSyllabusParser.normalized(dateText).split(separator: " ")
        return numbers(in: dateText).allSatisfy(sourceNumbers.contains)
            && words.compactMap(calendarName).allSatisfy(sourceNames.contains)
    }

    /// Digit runs as numbers, so "09" matches "9" and "31st" matches "31".
    private static func numbers(in text: String) -> [Int] {
        text.split { !$0.isNumber }.compactMap { Int($0) }
    }

    /// The three-letter stem of a month or weekday name or abbreviation ("october", "oct",
    /// "thurs" → "oct", "oct", "thu"). Other words ("monitor") give nil.
    private static func calendarName(_ word: Substring) -> String? {
        guard word.count >= 3, calendarNames.contains(where: { $0.hasPrefix(word) }) else { return nil }
        return String(word.prefix(3))
    }

    private static let calendarNames = [
        "january", "february", "march", "april", "may", "june", "july", "august", "september",
        "october", "november", "december",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
    ]

    /// True when a single line names the item and gives the weight. The model tends to copy a
    /// category's total ("Problem Sets (5) … 25%") onto every member.
    static func lineStates(weight: String, for title: String, in source: String) -> Bool {
        let number = weight.filter { $0.isNumber || $0 == "." }
        let normalizedTitle = RuleBasedSyllabusParser.normalized(title)
        guard !number.isEmpty, !normalizedTitle.isEmpty else { return false }
        return source.components(separatedBy: .newlines).contains { line in
            line.contains(number) && RuleBasedSyllabusParser.normalized(line).contains(normalizedTitle)
        }
    }
}

@Generable(description: "Graded work found in part of a course syllabus")
nonisolated struct GeneratedSyllabus {
    @Guide(description: "The first day of classes exactly as written, for example 'August 31, 2026'. Empty if this text doesn't say.")
    var firstDayOfClasses: String

    @Guide(description: "Every assignment, quiz, exam, project and reading in this text, in order")
    var items: [GeneratedItem]
}

@Generable
nonisolated struct GeneratedItem {
    @Guide(description: "Short title as written, for example 'Problem Set 3' or 'Midterm Exam'")
    var title: String

    var kind: GeneratedKind

    @Guide(description: "The due or scheduled date copied exactly as written, including any week number, weekday, range and time, for example 'Week 3, Friday', 'Oct 12–14' or 'Dec 4 at 5 PM'. Empty if no date is given.")
    var dateText: String

    @Guide(description: "Grade weight or points as written, for example '15%' or '50 points'. Empty if not given.")
    var weight: String

    @Guide(description: "A few words of useful detail such as location or format. Usually empty.")
    var details: String
}

@Generable
nonisolated enum GeneratedKind {
    case assignment, exam, quiz, project, reading

    var assignmentKind: AssignmentKind {
        switch self {
        case .assignment: .assignment
        case .exam: .exam
        case .quiz: .quiz
        case .project: .project
        case .reading: .reading
        }
    }
}

private extension LanguageModelSession.GenerationError {
    /// Errors a shorter passage can avoid: too long for the context window, or a guardrail
    /// tripped by one part of it.
    var isWorthSplitting: Bool {
        switch self {
        case .exceededContextWindowSize, .guardrailViolation: true
        default: false
        }
    }
}
