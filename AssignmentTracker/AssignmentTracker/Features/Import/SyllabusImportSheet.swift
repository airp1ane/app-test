import PhotosUI
import SwiftData
import SwiftUI
import VisionKit

/// Step one of syllabus import: pick the class, then a file, photos or a scan.
/// Pushes the review screen once items have been detected.
struct SyllabusImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.sortIndex) private var courses: [Course]

    @State private var model: SyllabusImportModel
    @State private var isPickingFile = false
    @State private var isScanning = false
    @State private var isAddingCourse = false
    @State private var photoSelection: [PhotosPickerItem] = []
    /// The import in flight; cancelled when the sheet closes.
    @State private var importTask: Task<Void, Never>?

    init(course: Course? = nil) {
        _model = State(initialValue: SyllabusImportModel(course: course))
    }

    private var isWorking: Bool {
        if case .working = model.phase { true } else { false }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pick the class, then its syllabus. The app finds the assignments, quizzes, exams and readings for you to review. Everything is read on this iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader("Class")
                        CourseChips(courses: courses, selection: $model.course) {
                            isAddingCourse = true
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader("Syllabus")
                        SyllabusSourceCard(
                            photoSelection: $photoSelection,
                            isEnabled: model.course != nil,
                            onChooseFile: { isPickingFile = true },
                            onScan: { isScanning = true }
                        )
                        Text(model.course == nil
                             ? "Choose a class first."
                             : "PDF, Word (.docx), text or photos · up to \(ByteCountFormatter.string(fromByteCount: SyllabusTextExtractor.maxFileSize, countStyle: .file))")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .padding(.horizontal, 4)
                    }

                    if let error = model.error {
                        ErrorCard(error: error)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .animation(.snappy, value: model.error)
            }
            .background { DuskBackground() }
            .overlay {
                if case .working(let message) = model.phase {
                    WorkingOverlay(message: message)
                }
            }
            .disabled(isWorking)
            .navigationTitle("Import Syllabus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        importTask?.cancel()
                        dismiss()
                    } label: { Label("Cancel", appIcon: .close) }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { model.phase == .reviewing },
                set: { if !$0 { model.startOver() } }
            )) {
                ImportReviewView(model: model) { dismiss() }
            }
            .fileImporter(isPresented: $isPickingFile, allowedContentTypes: SyllabusTextExtractor.supportedTypes) { result in
                switch result {
                case .success(let url):
                    startImport { await model.importFile(url) }
                case .failure(let error):
                    model.error = .unreadable(error.localizedDescription)
                }
            }
            .onChange(of: photoSelection) { _, items in
                guard !items.isEmpty else { return }
                photoSelection = []
                startImport {
                    model.prepareForPhotos(count: items.count)
                    var photos: [Data] = []
                    var failedCount = 0
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            photos.append(data)
                        } else {
                            failedCount += 1
                        }
                    }
                    // Some photos failing to load (for example an iCloud download) still lets the
                    // rest through; only when none load is there nothing to import.
                    guard !photos.isEmpty else {
                        guard !Task.isCancelled else { return }
                        model.error = .unreadable(failedCount == 1
                            ? "The photo couldn’t be loaded. It may still be downloading from iCloud."
                            : "None of the \(failedCount) photos could be loaded. They may still be downloading from iCloud.")
                        model.phase = .choosingSource
                        return
                    }
                    await model.importPhotos(photos)
                }
            }
            .fullScreenCover(isPresented: $isScanning) {
                DocumentScanner { images in
                    isScanning = false
                    guard !images.isEmpty else { return }
                    startImport { await model.importScan(images) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isAddingCourse) {
                CourseEditorSheet { model.course = $0 }
            }
        }
        .interactiveDismissDisabled(isWorking || model.phase == .reviewing)
        .onDisappear { importTask?.cancel() }
    }

    /// Runs one import at a time.
    private func startImport(_ work: @escaping @MainActor () async -> Void) {
        guard importTask == nil, !isWorking else { return }
        importTask = Task {
            await work()
            importTask = nil
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) { SyllabusImportSheet() }
        .modelContainer(.preview)
}
