// Generates LinkRouter's app icon (.iconset PNGs) and the README banner.
// Run from the repo root:  swift scripts/generate-assets.swift
// Then:                    iconutil -c icns build/LinkRouter.iconset -o LinkRouter/LinkRouter.icns

import AppKit
import UniformTypeIdentifiers

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func makeContext(_ w: Int, _ h: Int) -> CGContext {
    CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func savePNG(_ ctx: CGContext, to url: URL) {
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

// The routing mark, defined in the 18x18 menu-icon design space (y-down, center 9,9).
// Drawn here with a transform, so icon and menu glyph stay geometrically identical.
func drawGlyph(_ ctx: CGContext, center: CGPoint, unit: CGFloat, color: CGColor) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.scaleBy(x: unit, y: -unit) // flip: design space is y-down, CG is y-up
    ctx.translateBy(x: -9, y: -9)

    ctx.setStrokeColor(color)
    ctx.setFillColor(color)
    ctx.setLineWidth(1.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // node
    ctx.fillEllipse(in: CGRect(x: 4 - 1.55, y: 9 - 1.55, width: 3.1, height: 3.1))

    let path = CGMutablePath()
    path.move(to: CGPoint(x: 6.1, y: 9))
    path.addLine(to: CGPoint(x: 8.2, y: 9))
    path.move(to: CGPoint(x: 8.2, y: 9))
    path.addCurve(to: CGPoint(x: 12.2, y: 5.8), control1: CGPoint(x: 10.2, y: 9), control2: CGPoint(x: 10.2, y: 5.8))
    path.addLine(to: CGPoint(x: 13.2, y: 5.8))
    path.move(to: CGPoint(x: 8.2, y: 9))
    path.addCurve(to: CGPoint(x: 12.2, y: 12.2), control1: CGPoint(x: 10.2, y: 9), control2: CGPoint(x: 10.2, y: 12.2))
    path.addLine(to: CGPoint(x: 13.2, y: 12.2))
    path.move(to: CGPoint(x: 13, y: 4))
    path.addLine(to: CGPoint(x: 14.8, y: 5.8))
    path.addLine(to: CGPoint(x: 13, y: 7.6))
    path.move(to: CGPoint(x: 13, y: 10.4))
    path.addLine(to: CGPoint(x: 14.8, y: 12.2))
    path.addLine(to: CGPoint(x: 13, y: 14))
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()
}

// macOS app icon: gradient squircle on the standard 1024 grid (824pt shape, 100pt margin).
func drawAppIcon(_ ctx: CGContext, size: CGFloat, origin: CGPoint = .zero) {
    let s = size / 1024
    ctx.saveGState()
    ctx.translateBy(x: origin.x, y: origin.y)

    let rect = CGRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let shape = CGPath(roundedRect: rect, cornerWidth: 185 * s, cornerHeight: 185 * s, transform: nil)
    ctx.addPath(shape)
    ctx.clip()

    let grad = CGGradient(
        colorsSpace: sRGB,
        colors: [rgb(0x2563EB), rgb(0x6366F1)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: 512 * s, y: 100 * s),
        end: CGPoint(x: 512 * s, y: 924 * s),
        options: []
    )

    drawGlyph(ctx, center: CGPoint(x: 512 * s, y: 512 * s), unit: 44 * s, color: rgb(0xFFFFFF))
    ctx.restoreGState()
}

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)

// --- .iconset ---
let iconset = root.appendingPathComponent("build/LinkRouter.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let ctx = makeContext(px, px)
        drawAppIcon(ctx, size: CGFloat(px))
        let suffix = scale == 2 ? "@2x" : ""
        savePNG(ctx, to: iconset.appendingPathComponent("icon_\(base)x\(base)\(suffix).png"))
    }
}
print("iconset written to \(iconset.path)")

// --- README banner (2560x840 @2x) ---
let bw = 2560, bh = 840
let banner = makeContext(bw, bh)
let bg = CGGradient(
    colorsSpace: sRGB,
    colors: [rgb(0x0B1120), rgb(0x111B36)] as CFArray,
    locations: [0, 1]
)!
banner.drawLinearGradient(bg, start: .zero, end: CGPoint(x: 0, y: bh), options: [])
drawAppIcon(banner, size: 700, origin: CGPoint(x: 130, y: 70))

NSGraphicsContext.current = NSGraphicsContext(cgContext: banner, flipped: false)
let title = NSAttributedString(string: "LinkRouter", attributes: [
    .font: NSFont.systemFont(ofSize: 176, weight: .bold),
    .foregroundColor: NSColor.white,
])
title.draw(at: CGPoint(x: 900, y: 430))
let tagline = NSAttributedString(string: "Route every link to the browser you choose.", attributes: [
    .font: NSFont.systemFont(ofSize: 66, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.85),
])
tagline.draw(at: CGPoint(x: 906, y: 320))
let meta = NSAttributedString(string: "Free & open source · GPL-3.0 · macOS 13+", attributes: [
    .font: NSFont.systemFont(ofSize: 48, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.55),
])
meta.draw(at: CGPoint(x: 906, y: 220))
NSGraphicsContext.current = nil

savePNG(banner, to: root.appendingPathComponent("images/linkrouter.png"))
print("banner written to images/linkrouter.png")
