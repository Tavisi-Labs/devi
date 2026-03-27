// MARK: - Models/ShareCardRenderer.swift
// Uses SwiftUI ImageRenderer (iOS 16+) to render ShareCardView into a shareable Image.

import SwiftUI

@MainActor
enum ShareCardRenderer {

    /// Renders a daily panchang card as a SwiftUI Image suitable for ShareLink.
    /// Returns nil if rendering fails.
    static func renderDailyCard(
        panchang: DailyPanchang,
        city: UserCity,
        navratriDay: NavratriDay?,
        theme: DeviTheme
    ) -> Image? {
        let view = ShareCardView(
            panchang: panchang,
            city: city,
            navratriDay: navratriDay,
            theme: theme
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0  // Already at 1080x1920 — no extra scaling needed
        renderer.proposedSize = .init(width: 1080, height: 1920)

        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }

    /// Renders and returns transferable data for ShareLink.
    /// Uses PNG format for high quality.
    static func renderAsTransferable(
        panchang: DailyPanchang,
        city: UserCity,
        navratriDay: NavratriDay?,
        theme: DeviTheme
    ) -> ShareableCardImage? {
        let view = ShareCardView(
            panchang: panchang,
            city: city,
            navratriDay: navratriDay,
            theme: theme
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = .init(width: 1080, height: 1920)

        guard let uiImage = renderer.uiImage,
              let pngData = uiImage.pngData() else { return nil }
        return ShareableCardImage(pngData: pngData)
    }
}

/// Transferable wrapper for sharing card images via ShareLink.
struct ShareableCardImage: Transferable {
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData
        }
    }
}
