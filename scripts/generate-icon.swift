#!/usr/bin/env swift
import AppKit
import Foundation

/// Generate the full macOS app icon set with AppKit alone.
/// Run on macOS: swift scripts/generate-icon.swift
let destination = URL(fileURLWithPath: "Lunarium/Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func star(_ center: NSPoint, _ outer: CGFloat, _ inner: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4 + .pi / 2
        let r = i.isMultiple(of: 2) ? outer : inner
        let point = NSPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        if i == 0 { p.move(to: point) } else { p.line(to: point) }
    }
    p.close()
    return p
}

func drawIcon() {
    let tile = NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944),
                            xRadius: 228, yRadius: 228)
    NSGradient(starting: color(36, 44, 115), ending: color(8, 14, 41))!
        .draw(in: tile, angle: -45)

    color(150, 128, 255, alpha: 0.32).setStroke()
    tile.lineWidth = 7
    tile.stroke()

    // Subtle, translucent moonlight across the indigo background.
    let halo = NSBezierPath(ovalIn: NSRect(x: 125, y: 140, width: 720, height: 720))
    NSGradient(starting: color(94, 87, 248, alpha: 0.20),
               ending: color(94, 87, 248, alpha: 0.0))!
        .draw(in: halo, relativeCenterPosition: NSPoint(x: -0.2, y: 0.15))

    // A hand-shaped crescent keeps the mark legible at 16px.
    let moon = NSBezierPath()
    moon.move(to: NSPoint(x: 671, y: 865))
    moon.curve(to: NSPoint(x: 252, y: 530),
               controlPoint1: NSPoint(x: 475, y: 878),
               controlPoint2: NSPoint(x: 278, y: 728))
    moon.curve(to: NSPoint(x: 569, y: 158),
               controlPoint1: NSPoint(x: 221, y: 309),
               controlPoint2: NSPoint(x: 378, y: 166))
    moon.curve(to: NSPoint(x: 841, y: 297),
               controlPoint1: NSPoint(x: 691, y: 153),
               controlPoint2: NSPoint(x: 782, y: 213))
    moon.curve(to: NSPoint(x: 505, y: 343),
               controlPoint1: NSPoint(x: 740, y: 236),
               controlPoint2: NSPoint(x: 594, y: 249))
    moon.curve(to: NSPoint(x: 545, y: 762),
               controlPoint1: NSPoint(x: 392, y: 461),
               controlPoint2: NSPoint(x: 419, y: 658))
    moon.curve(to: NSPoint(x: 671, y: 865),
               controlPoint1: NSPoint(x: 584, y: 793),
               controlPoint2: NSPoint(x: 628, y: 832))
    moon.close()

    let moonShadow = NSShadow()
    moonShadow.shadowColor = color(107, 91, 255, alpha: 0.65)
    moonShadow.shadowBlurRadius = 25
    moonShadow.set()
    NSGradient(colorsAndLocations:
        (color(241, 228, 255), 0.0),
        (color(171, 156, 255), 0.26),
        (color(94, 203, 255), 0.57),
        (color(108, 117, 255), 0.8),
        (color(230, 169, 255), 1.0)
    )!.draw(in: moon, angle: -35)
    NSShadow().set()

    color(229, 219, 255, alpha: 0.65).setStroke()
    moon.lineWidth = 5
    moon.stroke()

    let sparkle = star(NSPoint(x: 713, y: 627), 90, 15)
    let starGlow = NSShadow()
    starGlow.shadowColor = color(143, 140, 255, alpha: 0.9)
    starGlow.shadowBlurRadius = 24
    starGlow.set()
    NSColor.white.setFill()
    sparkle.fill()
    NSShadow().set()

    color(171, 183, 255, alpha: 0.7).setFill()
    NSBezierPath(ovalIn: NSRect(x: 761, y: 808, width: 10, height: 10)).fill()
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size,
                                        pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                                        hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Cannot create \(size)px icon.")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    drawIcon()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(size)px icon")
    }
    try data.write(to: destination.appendingPathComponent("icon-\(size).png"))
}
print("Generated Lunarium icon assets in \(destination.path)")
