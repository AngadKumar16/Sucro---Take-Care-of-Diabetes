//
//  BodyMap.swift
//  Sucro - Take Care of Diabetes
//
//  Infusion sites on a printed body outline. Shows the current site, when
//  each other site was last used, and the one that has rested longest.
//  On the front view the person's left side is on the right of the screen,
//  as when facing someone; the back view is the other way round.
//

import SwiftUI

enum BodySide: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"
    var id: String { rawValue }

    var sites: [SiteLocation] {
        switch self {
        case .front: [.armLeft, .armRight, .abdomenLeft, .abdomenCenter, .abdomenRight, .thighLeft, .thighRight]
        case .back: [.armLeft, .armRight, .buttocksLeft, .buttocksRight]
        }
    }

    static func showing(_ location: SiteLocation?) -> BodySide {
        switch location {
        case .buttocksLeft, .buttocksRight: .back
        default: .front
        }
    }
}

extension SiteLocation {
    /// Where the site sits on the 100 × 290 outline, for this side.
    func point(on side: BodySide) -> CGPoint? {
        // Front: the person's left is on the viewer's right.
        let mirror = side == .front
        func x(_ personLeft: Double) -> Double { mirror ? 100 - personLeft : personLeft }
        switch self {
        case .armLeft: return CGPoint(x: x(8), y: 100)
        case .armRight: return CGPoint(x: x(92), y: 100)
        case .abdomenLeft where side == .front: return CGPoint(x: x(30), y: 122)
        case .abdomenRight where side == .front: return CGPoint(x: x(70), y: 122)
        case .abdomenCenter where side == .front: return CGPoint(x: 50, y: 112)
        case .thighLeft where side == .front: return CGPoint(x: x(32), y: 198)
        case .thighRight where side == .front: return CGPoint(x: x(68), y: 198)
        case .buttocksLeft where side == .back: return CGPoint(x: x(32), y: 172)
        case .buttocksRight where side == .back: return CGPoint(x: x(68), y: 172)
        default: return nil
        }
    }

    /// "Left abdomen" rather than the stored "Abdomen Left".
    var spokenName: String {
        switch self {
        case .abdomenLeft: "Left abdomen"
        case .abdomenRight: "Right abdomen"
        case .abdomenCenter: "Center abdomen"
        case .thighLeft: "Left thigh"
        case .thighRight: "Right thigh"
        case .armLeft: "Left arm"
        case .armRight: "Right arm"
        case .buttocksLeft: "Left buttock"
        case .buttocksRight: "Right buttock"
        case .other: "Other site"
        }
    }

    /// The site that has rested longest, never the current one.
    static func suggested(current: SiteLocation?, history: [SiteLocation: Date]) -> SiteLocation {
        let candidates = allCases.filter { $0 != .other && $0 != .abdomenCenter && $0 != current }
        return candidates.min { (history[$0] ?? .distantPast) < (history[$1] ?? .distantPast) } ?? .abdomenLeft
    }
}

/// The outline itself, in a 100 × 290 box.
struct BodyOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 100, sy = rect.height / 290
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.addEllipse(in: CGRect(origin: p(36, 2), size: CGSize(width: 28 * sx, height: 30 * sy)))
        let outline: [(Double, Double)] = [
            (24, 40), (76, 40), (90, 46), (100, 118), (86, 122), (80, 74), (78, 128), (82, 196), (78, 286),
            (60, 286), (54, 214), (50, 214), (46, 286), (28, 286), (22, 196), (26, 128), (24, 74), (18, 122), (0, 118), (10, 46)
        ]
        path.move(to: p(outline[0].0, outline[0].1))
        for point in outline.dropFirst() { path.addLine(to: p(point.0, point.1)) }
        path.closeSubpath()
        return path
    }
}

struct BodyMap: View {
    let side: BodySide
    let current: SiteLocation?
    let history: [SiteLocation: Date]
    var suggested: SiteLocation?
    /// When set, tapping a site picks it.
    var selection: Binding<SiteLocation>?
    var now = Date()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                BodyOutline()
                    .stroke(Theme.vermilion.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .offset(x: 2, y: 1.5)
                BodyOutline()
                    .fill(Theme.ink.opacity(0.04))
                BodyOutline()
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: 2, lineJoin: .round))

                ForEach(side.sites, id: \.self) { site in
                    if let point = site.point(on: side) {
                        marker(for: site)
                            .position(x: point.x / 100 * size.width, y: point.y / 290 * size.height)
                    }
                }
            }
        }
        .aspectRatio(100 / 290, contentMode: .fit)
    }

    @ViewBuilder
    private func marker(for site: SiteLocation) -> some View {
        let isCurrent = site == current
        let isSuggested = site == suggested
        let isSelected = selection?.wrappedValue == site
        let dot = ZStack {
            if isCurrent {
                Circle().fill(Theme.vermilion).frame(width: 20, height: 20)
                Circle().strokeBorder(Theme.vermilion, lineWidth: 1.5).frame(width: 30, height: 30)
            } else if isSuggested {
                Circle().fill(Theme.green.opacity(0.18)).frame(width: 22, height: 22)
                Circle().strokeBorder(Theme.green, style: StrokeStyle(lineWidth: 2.4, dash: [3, 3])).frame(width: 22, height: 22)
            } else {
                Circle().fill(Theme.card).frame(width: 18, height: 18)
                Circle().strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 1.5, dash: history[site] == nil ? [2, 3] : [])).frame(width: 18, height: 18)
            }
            if isSelected {
                Circle().strokeBorder(Theme.ink, lineWidth: 2.5).frame(width: 36, height: 36)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(.circle)

        if let selection {
            Button { selection.wrappedValue = site } label: { dot }
                .buttonStyle(.plain)
                .accessibilityLabel(label(for: site))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .sensoryFeedback(.selection, trigger: isSelected)
        } else {
            dot.accessibilityHidden(true)
        }
    }

    private func label(for site: SiteLocation) -> String {
        var parts = [site.spokenName]
        if site == current { parts.append("current site") }
        if site == suggested { parts.append("rested longest") }
        if let used = history[site], site != current {
            parts.append("last used \(used.formatted(.relative(presentation: .named)))")
        } else if history[site] == nil {
            parts.append("not used yet")
        }
        return parts.joined(separator: ", ")
    }
}

/// The key under a body map.
struct BodyMapKey: View {
    var body: some View {
        HStack(spacing: 14) {
            key(Circle().fill(Theme.vermilion), "Now")
            key(Circle().strokeBorder(Theme.green, style: StrokeStyle(lineWidth: 2, dash: [3, 3])), "Rested longest")
            key(Circle().strokeBorder(Theme.ink, lineWidth: 1.5), "Used")
        }
        .font(.caption)
        .foregroundStyle(Theme.soft)
        .accessibilityHidden(true)
    }

    private func key(_ shape: some View, _ text: String) -> some View {
        HStack(spacing: 4) {
            shape.frame(width: 12, height: 12)
            Text(text)
        }
    }
}
