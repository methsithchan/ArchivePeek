import AppKit

let outputDirectory = URL(fileURLWithPath: "ArchivePeek/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func s(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
    value * scale
}

func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func circle(_ rect: CGRect) -> NSBezierPath {
    NSBezierPath(ovalIn: rect)
}

func drawIcon(size: Int) -> NSImage {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    let scale = CGFloat(size) / 1024.0
    let canvas = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))

    NSColor.clear.setFill()
    canvas.fill()

    let backgroundRect = canvas.insetBy(dx: s(72, scale), dy: s(72, scale))
    let backgroundPath = roundedRect(backgroundRect, s(210, scale))

    let backgroundGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 0.87, green: 0.92, blue: 0.97, alpha: 1.0)
    ])!
    backgroundGradient.draw(in: backgroundPath, angle: 90)

    NSColor.white.withAlphaComponent(0.88).setStroke()
    backgroundPath.lineWidth = s(7, scale)
    backgroundPath.stroke()

    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -s(24, scale)),
        blur: s(42, scale),
        color: NSColor.black.withAlphaComponent(0.22).cgColor
    )

    let trayRect = CGRect(x: s(245, scale), y: s(220, scale), width: s(534, scale), height: s(468, scale))
    let trayPath = roundedRect(trayRect, s(82, scale))
    let trayGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.05, green: 0.48, blue: 0.92, alpha: 1.0),
        NSColor(calibratedRed: 0.02, green: 0.32, blue: 0.72, alpha: 1.0)
    ])!
    trayGradient.draw(in: trayPath, angle: -90)

    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    let lidRect = CGRect(x: s(208, scale), y: s(592, scale), width: s(608, scale), height: s(166, scale))
    let lidPath = roundedRect(lidRect, s(58, scale))
    let lidGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.22, green: 0.65, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 0.03, green: 0.43, blue: 0.88, alpha: 1.0)
    ])!
    lidGradient.draw(in: lidPath, angle: 90)

    NSColor.white.withAlphaComponent(0.34).setStroke()
    lidPath.lineWidth = s(5, scale)
    lidPath.stroke()

    let slotRect = CGRect(x: s(336, scale), y: s(642, scale), width: s(352, scale), height: s(34, scale))
    NSColor.white.withAlphaComponent(0.95).setFill()
    roundedRect(slotRect, s(17, scale)).fill()

    let zipX = s(486, scale)
    let toothWidth = s(58, scale)
    let toothHeight = s(24, scale)
    let toothGap = s(22, scale)
    let firstY = s(520, scale)

    for index in 0..<6 {
        let xOffset = index.isMultiple(of: 2) ? s(-30, scale) : s(30, scale)
        let toothRect = CGRect(
            x: zipX + xOffset,
            y: firstY - CGFloat(index) * (toothHeight + toothGap),
            width: toothWidth,
            height: toothHeight
        )
        NSColor.white.withAlphaComponent(index < 4 ? 0.92 : 0.78).setFill()
        roundedRect(toothRect, s(10, scale)).fill()
    }

    let pullRect = CGRect(x: s(461, scale), y: s(547, scale), width: s(102, scale), height: s(102, scale))
    NSColor.white.withAlphaComponent(0.94).setStroke()
    let pullPath = circle(pullRect)
    pullPath.lineWidth = s(24, scale)
    pullPath.stroke()

    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -s(9, scale)),
        blur: s(18, scale),
        color: NSColor.black.withAlphaComponent(0.18).cgColor
    )

    let lensRect = CGRect(x: s(596, scale), y: s(278, scale), width: s(208, scale), height: s(208, scale))
    let lensPath = circle(lensRect)
    NSColor.white.withAlphaComponent(0.90).setFill()
    lensPath.fill()

    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    let innerLensRect = lensRect.insetBy(dx: s(28, scale), dy: s(28, scale))
    NSColor(calibratedRed: 0.82, green: 0.93, blue: 1.00, alpha: 0.72).setFill()
    circle(innerLensRect).fill()

    NSColor.white.withAlphaComponent(0.85).setStroke()
    let highlight = NSBezierPath()
    highlight.lineWidth = s(14, scale)
    highlight.lineCapStyle = .round
    highlight.move(to: CGPoint(x: s(662, scale), y: s(418, scale)))
    highlight.line(to: CGPoint(x: s(714, scale), y: s(444, scale)))
    highlight.stroke()

    let handlePath = NSBezierPath()
    handlePath.lineWidth = s(40, scale)
    handlePath.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.94).setStroke()
    handlePath.move(to: CGPoint(x: s(760, scale), y: s(322, scale)))
    handlePath.line(to: CGPoint(x: s(834, scale), y: s(248, scale)))
    handlePath.stroke()

    let subtleBottom = CGRect(x: s(330, scale), y: s(266, scale), width: s(266, scale), height: s(34, scale))
    NSColor.white.withAlphaComponent(0.20).setFill()
    roundedRect(subtleBottom, s(17, scale)).fill()

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmap)
    return image
}

for (filename, size) in sizes {
    let image = drawIcon(size: size)
    guard let bitmap = image.representations.first as? NSBitmapImageRep,
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(filename)")
    }

    try png.write(to: outputDirectory.appendingPathComponent(filename))
}

print("Generated \(sizes.count) app icon files")
