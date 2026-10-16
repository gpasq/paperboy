// Renders Resources/AppIcon.icns: a sunrise landscape with a peeled-back paper corner.
// Run: swift scripts/make-icon.swift
import AppKit

let size: CGFloat = 1024
let content = NSRect(x: 100, y: 100, width: 824, height: 824)   // macOS icon grid
let radius: CGFloat = 185

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func render() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let squircle = NSBezierPath(roundedRect: content, xRadius: radius, yRadius: radius)

    // Drop shadow + paper sheet underneath.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 24
    shadow.set()
    color(0xF6F2EA).setFill()
    squircle.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Fold geometry: corner C folds over line A–B onto C'.
    let fold: CGFloat = 270
    let a = NSPoint(x: content.maxX - fold, y: content.minY)
    let b = NSPoint(x: content.maxX, y: content.minY + fold)
    let cPrime = NSPoint(x: content.maxX - fold, y: content.minY + fold)

    // Photo, clipped to the squircle minus the folded corner.
    NSGraphicsContext.saveGraphicsState()
    let photoClip = NSBezierPath()
    photoClip.move(to: NSPoint(x: content.minX - 1, y: content.minY - 1))
    photoClip.line(to: NSPoint(x: a.x, y: a.y - 1))
    photoClip.line(to: NSPoint(x: b.x + 1, y: b.y))
    photoClip.line(to: NSPoint(x: content.maxX + 1, y: content.maxY + 1))
    photoClip.line(to: NSPoint(x: content.minX - 1, y: content.maxY + 1))
    photoClip.close()
    squircle.addClip()
    photoClip.addClip()
    drawScene()
    NSGraphicsContext.restoreGraphicsState()

    // Re-cover the paper corner, overlapping the fold line to hide the photo's anti-aliased edge.
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    let corner = NSBezierPath()
    corner.move(to: NSPoint(x: a.x - 3, y: a.y - 1))
    corner.line(to: NSPoint(x: content.maxX + 1, y: content.minY - 1))
    corner.line(to: NSPoint(x: b.x + 1, y: b.y + 3))
    corner.close()
    color(0xF6F2EA).setFill()
    corner.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Folded flap (back of the paper) with a soft shadow on the photo.
    let flap = NSBezierPath()
    flap.move(to: NSPoint(x: a.x - 2, y: a.y))
    flap.line(to: NSPoint(x: b.x, y: b.y + 2))
    flap.curve(to: cPrime, controlPoint1: NSPoint(x: b.x - 70, y: b.y + 8),
               controlPoint2: NSPoint(x: cPrime.x + 40, y: cPrime.y + 20))
    flap.curve(to: a, controlPoint1: NSPoint(x: cPrime.x - 20, y: cPrime.y - 40),
               controlPoint2: NSPoint(x: a.x - 8, y: a.y + 70))
    flap.close()
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    let flapShadow = NSShadow()
    flapShadow.shadowColor = .black.withAlphaComponent(0.45)
    flapShadow.shadowOffset = NSSize(width: -10, height: 10)
    flapShadow.shadowBlurRadius = 28
    flapShadow.set()
    color(0xFFFFFF).setFill()
    flap.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    flap.addClip()
    NSGradient(colors: [color(0xD9D2C5), color(0xF3EEE4), color(0xFFFFFF)],
               atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
        .draw(from: NSPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2), to: cPrime, options: [])
    NSGraphicsContext.restoreGraphicsState()

    // Subtle top highlight on the whole icon.
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    NSGradient(colors: [.white.withAlphaComponent(0.18), .white.withAlphaComponent(0)])!
        .draw(in: NSRect(x: content.minX, y: content.midY + 120, width: content.width, height: content.height / 2 - 120), angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawScene() {
    let horizon: CGFloat = 430
    // Sky.
    NSGradient(colors: [color(0x1E2A78), color(0x6A3D9A), color(0xD9547A), color(0xF7944D), color(0xFDD38A)],
               atLocations: [0, 0.3, 0.6, 0.85, 1], colorSpace: .sRGB)!
        .draw(in: NSRect(x: 0, y: horizon - 40, width: size, height: size - horizon + 40), angle: -90)

    // Sun with glow.
    let sun = NSPoint(x: 512, y: 520)
    NSGradient(colors: [color(0xFFE9A8, 0.75), color(0xFFB36B, 0.0)])!
        .draw(fromCenter: sun, radius: 0, toCenter: sun, radius: 300, options: [])
    let disc = NSBezierPath(ovalIn: NSRect(x: sun.x - 115, y: sun.y - 115, width: 230, height: 230))
    NSGraphicsContext.saveGraphicsState()
    disc.addClip()
    NSGradient(colors: [color(0xFFF6D6), color(0xFFC86B)])!
        .draw(in: disc.bounds, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Mountain ranges, back to front.
    func range(_ points: [(CGFloat, CGFloat)], _ top: NSColor, _ bottom: NSColor) {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: 0, y: 0))
        for (x, y) in points { p.line(to: NSPoint(x: x, y: y)) }
        p.line(to: NSPoint(x: size, y: 0))
        p.close()
        p.lineJoinStyle = .round
        NSGraphicsContext.saveGraphicsState()
        p.addClip()
        NSGradient(colors: [top, bottom])!.draw(in: p.bounds, angle: -90)
        NSGraphicsContext.restoreGraphicsState()
    }
    range([(0, 470), (170, 600), (290, 520), (420, 650), (560, 500), (700, 610), (840, 520), (1024, 580)],
          color(0x9A4F8C), color(0x6B3A7D))
    range([(0, 380), (130, 470), (250, 400), (380, 540), (470, 470), (620, 560), (760, 430), (900, 500), (1024, 440)],
          color(0x4B2C6E), color(0x2C1C52))
    // Lake.
    NSGradient(colors: [color(0x3A3F88), color(0x161C4A)])!
        .draw(in: NSRect(x: 0, y: 0, width: size, height: 370), angle: -90)
    // Sun reflection streaks.
    let glints: [UInt32] = [0xFFDCA3, 0xF6B98C, 0xD9938F, 0xA77396]
    for (i, w) in [CGFloat(200), 150, 104, 64].enumerated() {
        color(glints[i]).setFill()
        NSBezierPath(roundedRect: NSRect(x: 512 - w / 2, y: 340 - CGFloat(i) * 34, width: w, height: 13),
                     xRadius: 6.5, yRadius: 6.5).fill()
    }
    // Foreground shore.
    range([(0, 200), (150, 236), (320, 196), (520, 176), (1024, 160)], color(0x1A1238), color(0x0E0A24))
}

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let master = render()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try! master.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("Resources/AppIcon.png"))

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        master.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try! p.run(); p.waitUntilExit()
print("Wrote Resources/AppIcon.icns")
