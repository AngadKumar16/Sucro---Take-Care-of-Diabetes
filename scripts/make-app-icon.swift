// Draws the app icon (light, dark, tinted) at 1024 px.
// Run: swift scripts/make-app-icon.swift DiabetesCare/Resources/Assets.xcassets/AppIcon.appiconset

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor { CGColor(colorSpace: space, components: [r, g, b, a])! }

// Glucose drop: round bottom, pointed top. Center x 512.
func dropPath() -> CGPath {
    let p = CGMutablePath()
    let cx = 512.0, bottomY = 250.0, r = 215.0   // CG origin bottom-left
    let cy = bottomY + r
    let tipY = cy + r * 1.62
    p.move(to: CGPoint(x: cx, y: tipY))
    p.addCurve(to: CGPoint(x: cx + r, y: cy), control1: CGPoint(x: cx + r * 0.35, y: tipY - r * 0.55), control2: CGPoint(x: cx + r, y: cy + r * 0.62))
    p.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: 0, endAngle: .pi, clockwise: true)
    p.addCurve(to: CGPoint(x: cx, y: tipY), control1: CGPoint(x: cx - r, y: cy + r * 0.62), control2: CGPoint(x: cx - r * 0.35, y: tipY - r * 0.55))
    p.closeSubpath()
    return p
}

// A leaf from `base` pointing at `angle` (radians), length L, width W.
func leaf(base: CGPoint, angle: Double, length L: Double, width W: Double) -> CGPath {
    let p = CGMutablePath()
    let tip = CGPoint(x: base.x + cos(angle) * L, y: base.y + sin(angle) * L)
    let n = angle + .pi / 2
    let mid = CGPoint(x: base.x + cos(angle) * L * 0.5, y: base.y + sin(angle) * L * 0.5)
    p.move(to: base)
    p.addQuadCurve(to: tip, control: CGPoint(x: mid.x + cos(n) * W, y: mid.y + sin(n) * W))
    p.addQuadCurve(to: base, control: CGPoint(x: mid.x - cos(n) * W, y: mid.y - sin(n) * W))
    return p
}

enum Variant { case light, dark, tinted }

func render(_ v: Variant, to url: URL) {
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let full = CGRect(x: 0, y: 0, width: size, height: size)

    // Background
    switch v {
    case .light:
        let g = CGGradient(colorsSpace: space, colors: [color(0.20, 0.55, 0.38), color(0.11, 0.40, 0.27)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    case .dark:
        let g = CGGradient(colorsSpace: space, colors: [color(0.10, 0.16, 0.13), color(0.05, 0.08, 0.07)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    case .tinted:
        ctx.setFillColor(color(0, 0, 0)); ctx.fill(full)
    }

    // Center the drop + sprout and keep them inside the icon mask.
    ctx.translateBy(x: 512, y: 512)
    ctx.scaleBy(x: 0.82, y: 0.82)
    ctx.translateBy(x: -512, y: -625)

    let cream: CGColor, leafA: CGColor, leafB: CGColor, stem: CGColor, shine: CGColor
    switch v {
    case .light: cream = color(0.98, 0.96, 0.90); leafA = color(0.62, 0.86, 0.52); leafB = color(0.50, 0.78, 0.42); stem = color(0.50, 0.78, 0.42); shine = color(1, 1, 1, 0.55)
    case .dark: cream = color(0.36, 0.72, 0.52); leafA = color(0.70, 0.90, 0.58); leafB = color(0.58, 0.84, 0.48); stem = color(0.58, 0.84, 0.48); shine = color(1, 1, 1, 0.30)
    case .tinted: cream = color(0.92, 0.92, 0.92); leafA = color(1, 1, 1); leafB = color(0.80, 0.80, 0.80); stem = color(0.80, 0.80, 0.80); shine = color(1, 1, 1, 0.5)
    }

    // Soft shadow under the drop (light only).
    if v == .light {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: color(0, 0.1, 0.05, 0.35))
        ctx.addPath(dropPath()); ctx.setFillColor(cream); ctx.fillPath()
        ctx.restoreGState()
    } else {
        ctx.addPath(dropPath()); ctx.setFillColor(cream); ctx.fillPath()
    }

    // Highlight on the drop.
    ctx.saveGState()
    ctx.setStrokeColor(shine); ctx.setLineWidth(26); ctx.setLineCap(.round)
    ctx.addArc(center: CGPoint(x: 512, y: 465), radius: 150, startAngle: .pi * 0.95, endAngle: .pi * 1.28, clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()

    // Sprout from the tip: stem and two leaves.
    let tip = CGPoint(x: 512, y: 465 + 215 * 1.62)
    let top = CGPoint(x: 512, y: tip.y + 70)
    ctx.setStrokeColor(stem); ctx.setLineWidth(22); ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: 512, y: tip.y - 10)); ctx.addLine(to: top); ctx.strokePath()
    ctx.addPath(leaf(base: top, angle: .pi * 0.80, length: 150, width: 56)); ctx.setFillColor(leafB); ctx.fillPath()
    ctx.addPath(leaf(base: top, angle: .pi * 0.22, length: 170, width: 60)); ctx.setFillColor(leafA); ctx.fillPath()

    let image = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
render(.light, to: out.appending(path: "AppIcon.png"))
render(.dark, to: out.appending(path: "AppIcon-Dark.png"))
render(.tinted, to: out.appending(path: "AppIcon-Tinted.png"))
print("ok")
