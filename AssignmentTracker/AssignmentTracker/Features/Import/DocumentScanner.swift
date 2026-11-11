import SwiftUI
import VisionKit

/// The system document camera. Calls `onFinish` with the scanned pages, or an empty array
/// if the person cancels. Calls `onError` (then `onFinish` with an empty array) if the camera fails.
struct DocumentScanner: UIViewControllerRepresentable {
    let onFinish: ([CGImage]) -> Void
    var onError: (Error) -> Void = { _ in }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish, onError: onError) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: ([CGImage]) -> Void
        let onError: (Error) -> Void

        init(onFinish: @escaping ([CGImage]) -> Void, onError: @escaping (Error) -> Void) {
            self.onFinish = onFinish
            self.onError = onError
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            onFinish((0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0).cgImage })
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onFinish([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onError(error)
            onFinish([])
        }
    }
}
