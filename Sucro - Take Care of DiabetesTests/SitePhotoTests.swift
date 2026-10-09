//
//  SitePhotoTests.swift
//  Sucro - Take Care of Diabetes Tests
//
//  Site photos: re-encoding picked images and keeping them in Core Data.
//

import Testing
import Foundation
import CoreData
import UIKit
@testable import Sucro___Take_Care_of_Diabetes

private func png(width: Int, height: Int) -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let size = CGSize(width: width, height: height)
    return UIGraphicsImageRenderer(size: size, format: format).pngData { context in
        UIColor.systemPurple.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}

private func pixelSize(_ data: Data?) -> CGSize? {
    guard let data, let image = UIImage(data: data)?.cgImage else { return nil }
    return CGSize(width: image.width, height: image.height)
}

@Suite("Site photo")
struct SitePhotoTests {
    @Test func largePhotoIsDownscaledKeepingAspectRatio() throws {
        let encoded = try #require(SitePhoto.encode(png(width: 4000, height: 3000)))
        #expect(pixelSize(encoded) == CGSize(width: 1600, height: 1200))
        // JPEG, not the original PNG.
        #expect(encoded.starts(with: [0xFF, 0xD8]))
    }

    @Test func portraitPhotoIsLimitedByItsHeight() {
        #expect(pixelSize(SitePhoto.encode(png(width: 1500, height: 3200))) == CGSize(width: 750, height: 1600))
    }

    @Test func smallPhotoKeepsItsSize() {
        #expect(pixelSize(SitePhoto.encode(png(width: 640, height: 480))) == CGSize(width: 640, height: 480))
    }

    @Test func nonImageDataIsRejected() {
        #expect(SitePhoto.encode(Data("not an image".utf8)) == nil)
        #expect(SitePhoto.encode(Data()) == nil)
    }
}

@Suite("Site photo storage", .serialized)
@MainActor
struct SitePhotoStorageTests {
    @Test func photoSurvivesSaveChangeAndRemoval() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SucroPhotoTest-\(UUID().uuidString).sqlite")
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
            }
        }
        let container = PersistenceController(storeURL: url).container
        let context = container.viewContext

        let photo = try #require(SitePhoto.encode(png(width: 2000, height: 2000)))
        let site = SiteChange(context: context)
        site.id = UUID()
        site.timestamp = Date()
        site.location = SiteLocation.abdomenLeft.rawValue
        site.photo = photo
        try context.save()

        let id = site.objectID
        // Drops everything in memory so the photo is read back from the store.
        func reload() throws -> SiteChange {
            context.reset()
            return try #require(try context.existingObject(with: id) as? SiteChange)
        }
        #expect(try reload().photo == photo)

        let replacement = try #require(SitePhoto.encode(png(width: 300, height: 200)))
        var stored = try reload()
        stored.photo = replacement
        try context.save()
        #expect(try reload().photo == replacement)

        stored = try reload()
        stored.photo = nil
        try context.save()
        #expect(try reload().photo == nil)
    }
}
