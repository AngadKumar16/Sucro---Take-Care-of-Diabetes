//
//  SitePhotoSection.swift
//  Sucro - Take Care of Diabetes
//
//  Photo of an infusion site, shared by the add and edit forms.
//

import SwiftUI
import PhotosUI
import UIKit

struct SitePhotoSection: View {
    @Binding var photo: Data?

    @State private var item: PhotosPickerItem?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        Section {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(.rect(cornerRadius: 8))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Site photo")
                    .accessibilityIdentifier("sitePhoto")
            }
            PhotosPicker(selection: $item, matching: .images) {
                HStack {
                    Label(photo == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                    if isLoading {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isLoading)
            if photo != nil {
                Button("Remove Photo", role: .destructive) {
                    item = nil
                    photo = nil
                }
            }
        } header: {
            Text("Photo")
        } footer: {
            if loadFailed {
                Text("That photo couldn't be loaded. Try another one.")
            }
        }
        .listRowBackground(Theme.card)
        // `task(id:)` cancels a load still running when another photo is picked.
        .task(id: item) { await load(item) }
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        defer { isLoading = false }
        let data = try? await item.loadTransferable(type: Data.self)
        guard !Task.isCancelled else { return }
        if let data, let encoded = SitePhoto.encode(data) {
            photo = encoded
            loadFailed = false
        } else {
            loadFailed = true
        }
    }
}

enum SitePhoto {
    /// Longest side of a stored photo, in pixels. Plenty to see the site,
    /// and keeps a 12 MP original from adding megabytes to the store.
    static let maxPixels: CGFloat = 1600

    /// Downscales and re-encodes picked image data as JPEG. `nil` if the
    /// data isn't an image.
    static func encode(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let scale = min(1, maxPixels / max(pixels.width, pixels.height))
        guard scale < 1 else { return image.jpegData(compressionQuality: 0.8) }
        let target = CGSize(width: (pixels.width * scale).rounded(), height: (pixels.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
