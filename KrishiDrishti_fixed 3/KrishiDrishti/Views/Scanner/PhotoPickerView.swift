// Views/Scanner/PhotoPickerView.swift
// KrishiDrishti — PHPickerViewController wrapper (handles HEIC, iCloud, Live Photos)

import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter          = .images
        config.selectionLimit  = 1
        // Request full-size decoded image, not raw asset data
        // This bypasses the public.data / public.jpeg export issue entirely
        config.preferredAssetRepresentationMode = .compatible

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}

    // MARK: - Coordinator
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard let result = results.first else { return }

            let provider = result.itemProvider

            // --- Strategy 1: load as UIImage directly (fastest, works for local assets) ---
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async { self?.parent.onImage(image) }
                        return
                    }
                    // Strategy 1 failed — fall through to Strategy 2
                    self?.loadViaFileRepresentation(provider: provider)
                }
            } else {
                loadViaFileRepresentation(provider: provider)
            }
        }

        // --- Strategy 2: load as file URL (handles iCloud, HEIC, Live Photo) ---
        private func loadViaFileRepresentation(provider: NSItemProvider) {
            // Try JPEG first, then HEIC, then PNG, then any image
            let types: [String] = [
                "public.jpeg",
                "public.heic",
                "public.heif",
                "public.png",
                "public.image"
            ]

            loadNext(types: types, index: 0, provider: provider)
        }

        private func loadNext(types: [String], index: Int, provider: NSItemProvider) {
            guard index < types.count else {
                print("PhotoPickerView: all type strategies exhausted")
                return
            }
            let type = types[index]
            guard provider.hasItemConformingToTypeIdentifier(type) else {
                loadNext(types: types, index: index + 1, provider: provider)
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, error in
                if let error = error {
                    print("PhotoPickerView: strategy '\(type)' failed: \(error.localizedDescription)")
                    self?.loadNext(types: types, index: index + 1, provider: provider)
                    return
                }
                guard let url = url,
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    self?.loadNext(types: types, index: index + 1, provider: provider)
                    return
                }
                DispatchQueue.main.async { self?.parent.onImage(image) }
            }
        }
    }
}
