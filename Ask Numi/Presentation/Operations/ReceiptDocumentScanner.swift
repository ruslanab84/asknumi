//
//  ReceiptDocumentScanner.swift
//  Ask Numi
//

import AVFoundation
import SwiftUI
import VisionKit

struct CapturedReceipt: Identifiable {
    let id = UUID()
    let images: [UIImage]
}

struct ReceiptDocumentScanner: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onScan: (CapturedReceipt) -> Void
    let onFailure: () -> Void

    @MainActor
    static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    static func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: ReceiptDocumentScanner

        init(parent: ReceiptDocumentScanner) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            parent.dismiss()
            parent.onScan(CapturedReceipt(images: images))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.dismiss()
            parent.onFailure()
        }
    }
}
