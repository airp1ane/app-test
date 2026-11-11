import Foundation
import SwiftData
import Testing
@testable import AssignmentTracker

@MainActor
struct SyllabusImportModelTests {
    @Test func saveAddsCheckedItemsAndMarksPastOnesDone() throws {
        let container = try ModelContainer(for: ModelContainer.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let course = Course(name: "Psychology", color: .purple, sortIndex: 0)
        context.insert(course)

        let model = SyllabusImportModel(course: course, calendar: Fixtures.calendar, referenceDate: Fixtures.today)
        model.candidates = ImportCandidateBuilder.candidates(
            from: [
                DetectedItem(title: "Discussion Post 1", kind: .assignment, dateText: "Sep 8"),
                DetectedItem(title: "Exam 1", kind: .exam, dateText: "Oct 15", weight: "20%"),
                DetectedItem(title: "Book review", kind: .assignment, dateText: nil),
            ],
            resolver: model.resolver, existing: []
        )
        #expect(model.includedCount == 2)
        #expect(model.pastIncludedCount == 1)

        #expect(model.save(in: context) == 2)
        let saved = try context.fetch(FetchDescriptor<Assignment>(sortBy: [SortDescriptor(\.dueDate)]))
        #expect(saved.map(\.title) == ["Discussion Post 1", "Exam 1"])
        #expect(saved[0].isCompleted)
        #expect(!saved[1].isCompleted)
        #expect(saved[1].priority == .high)
        #expect(saved.allSatisfy { $0.course === course })
    }

    @Test func skipAllUnchecksOnlyPastItems() {
        let model = SyllabusImportModel(calendar: Fixtures.calendar, referenceDate: Fixtures.today)
        model.candidates = ImportCandidateBuilder.candidates(
            from: [
                DetectedItem(title: "Quiz 1", kind: .quiz, dateText: "Sep 10"),
                DetectedItem(title: "Quiz 2", kind: .quiz, dateText: "Oct 10"),
            ],
            resolver: model.resolver, existing: []
        )
        model.setPastIncluded(false)
        #expect(model.candidates.map(\.isIncluded) == [false, true])
    }

    /// An undated item matches an existing one on title alone; once the term start gives it
    /// a date on another day, it's no longer a duplicate and becomes checked.
    @Test func settingTermStartClearsAStaleDuplicate() throws {
        let (container, model) = try modelWithExistingQuiz(due: Fixtures.date(2026, 10, 20, 9, 0))
        #expect(model.candidates[0].duplicateOf == "Quiz 1")
        #expect(!model.candidates[0].isIncluded)

        model.termStart = Fixtures.fallStart
        #expect(model.candidates[0].dueDate == Fixtures.date(2026, 10, 8, 23, 59))
        #expect(model.candidates[0].duplicateOf == nil)
        #expect(model.candidates[0].isIncluded)
        _ = container
    }

    @Test func settingTermStartKeepsASameDayDuplicateUnchecked() throws {
        let (container, model) = try modelWithExistingQuiz(due: Fixtures.date(2026, 10, 8, 9, 0))
        model.termStart = Fixtures.fallStart
        #expect(model.candidates[0].duplicateOf == "Quiz 1")
        #expect(!model.candidates[0].isIncluded)
        _ = container
    }

    @Test func untitledAddedItemIsDiscardedButNamedOneIsKept() {
        let model = SyllabusImportModel(calendar: Fixtures.calendar, referenceDate: Fixtures.today)
        let blank = model.addCandidate()
        let named = model.addCandidate()
        model.candidates[1].title = "Lab report"
        #expect(model.includedCount == 2)

        model.discardIfUntitled(blank)
        model.discardIfUntitled(named)
        #expect(model.candidates.map(\.title) == ["Lab report"])
        #expect(model.candidates[0].id == named)
    }

    /// A course with an existing "Quiz 1", and an undated "Week 6, Thursday" candidate for it.
    private func modelWithExistingQuiz(due: Date) throws -> (ModelContainer, SyllabusImportModel) {
        let container = try ModelContainer(for: ModelContainer.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let course = Course(name: "Psychology", color: .purple, sortIndex: 0)
        context.insert(course)
        let existing = Assignment(title: "Quiz 1", dueDate: due)
        context.insert(existing)
        existing.course = course

        let model = SyllabusImportModel(course: course, calendar: Fixtures.calendar, referenceDate: Fixtures.today)
        model.candidates = ImportCandidateBuilder.candidates(
            from: [DetectedItem(title: "Quiz 1", kind: .quiz, dateText: "Week 6, Thursday")],
            resolver: model.resolver,
            existing: [ExistingAssignment(title: "Quiz 1", dueDate: due)]
        )
        return (container, model)
    }
}

/// Regression tests for the review list using the model's clock and calendar (ac3abe2).
@MainActor
struct ImportReferenceDateTests {
    private func model(at reference: Date) -> SyllabusImportModel {
        SyllabusImportModel(calendar: Fixtures.calendar, referenceDate: reference)
    }

    private func candidate(due: Date) -> ImportCandidate {
        var candidate = ImportCandidateBuilder.candidates(
            from: [DetectedItem(title: "Quiz", kind: .quiz, dateText: nil)],
            resolver: model(at: Fixtures.today).resolver, existing: []
        )[0]
        candidate.dueDate = due
        return candidate
    }

    @Test func pastIsJudgedAgainstTheModelsDayNotTheRealClock() {
        // The reference day is in the past compared with the real clock, so the old
        // `candidate.isPast()` (which used .now) called everything past.
        let model = model(at: Fixtures.date(2026, 9, 29, 10, 0))
        #expect(!model.isPast(candidate(due: Fixtures.date(2026, 9, 30, 9, 0))))
        #expect(!model.isPast(candidate(due: Fixtures.date(2026, 9, 29, 8, 0))))
        #expect(model.isPast(candidate(due: Fixtures.date(2026, 9, 28, 23, 59))))
    }

    @Test func sheetOpenedJustBeforeMidnightKeepsItsOwnDay() {
        // Opened at 23:30; the list may be rebuilt after midnight, but the import day stays put.
        let model = model(at: Fixtures.date(2026, 9, 29, 23, 30))
        #expect(!model.isPast(candidate(due: Fixtures.date(2026, 9, 29, 0, 30))))
        #expect(model.isPast(candidate(due: Fixtures.date(2026, 9, 28, 20, 0))))
        #expect(model.startOfReferenceDay == Fixtures.date(2026, 9, 29))
    }

    @Test func termStartDefaultIsStartOfTheReferenceDayInTheModelsCalendar() {
        let model = model(at: Fixtures.date(2026, 1, 15, 22, 0))
        #expect(model.startOfReferenceDay == Fixtures.calendar.startOfDay(for: Fixtures.date(2026, 1, 15, 22, 0)))
        #expect(model.startOfReferenceDay != Calendar.current.startOfDay(for: .now))
    }
}

/// Regression tests for newline-only text in the candidate editor (89b955f).
struct CandidateTextTests {
    @Test func newlineOnlyAndSpaceOnlyTextIsBlank() {
        #expect(CandidateText.isBlank(""))
        #expect(CandidateText.isBlank("   "))
        #expect(CandidateText.isBlank("\n"))
        #expect(CandidateText.isBlank(" \n\t\r\n "))
    }

    @Test func realTextIsNotBlank() {
        #expect(!CandidateText.isBlank("Quiz 1"))
        #expect(!CandidateText.isBlank("\n Quiz \n"))
    }
}
