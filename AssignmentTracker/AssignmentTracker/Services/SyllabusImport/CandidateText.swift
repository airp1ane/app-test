import Foundation

/// Text rules shared by the editor's Done, Cancel and weight checks.
nonisolated enum CandidateText {
    /// Empty once spaces and line breaks are ignored, so a pasted newline-only title is blank too.
    static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
