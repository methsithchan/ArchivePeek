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

func scaled(_ value: CGFloat, _ scale: CGFloat) -> CGFloat {
    value * scale
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let scale = CGFloat(size) / 1024.0
    let canvas = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))

    NSColor.clear.setFill()
    canvas.fill()

    let bodyRect = canvas.insetBy(dx: scaled(82, scale), dy: scaled(82, scale))
    let bodyPath = roundedRect(bodyRect, radius: scaled(220, scale))
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.02, green: 0.50, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 0.28, green: 0.34, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 0.75, green: 0.22, blue: 0.92, alpha: 1.0)
    ])!
    gradient.draw(in: bodyPath, angle: -45)

    NSGraphicsContext.current?.cgContext.setShadow(
        offset: CGSize(width: 0, height: -scaled(18, scale)),
        blur: scaled(34, scale),
        color: NSColor.black.withAlphaComponent(0.20).cgColor
    )

    let trayRect = CGRect(
        x: scaled(300, scale),
        y: scaled(276, scale),
        width: scaled(424, scale),
        height: scaled(472, scale)
    )
    let trayPath = roundedRect(trayRect, radius: scaled(64, scale))
    NSColor.white.setFill()
    trayPath.fill()

    NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

    let lidRect = CGRect(
        x: scaled(264, scale),
        y: scaled(596, scale),
        width: scaled(496, scale),
        height: scaled(156, scale)
    )
    let lidPath = roundedRect(lidRect, radius: scaled(48, scale))
    NSColor.white.setFill()
    lidPath.fill()

    NSColor(calibratedRed: 0.10, green: 0.48, blue: 0.98, alpha: 1.0).setFill()
    roundedRect(
        CGRect(x: scaled(360, scale), y: scaled(612, scale), width: scaled(304, scale), height: scaled(36, scale)),
        radius: scaled(18, scale)
    ).fill()

    NSColor(calibratedRed: 0.45, green: 0.35, blue: 0.98, alpha: 1.0).setFill()
    roundedRect(
        CGRect(x: scaled(418, scale), y: scaled(534, scale), width: scaled(188, scale), height: scaled(34, scale)),
        radius: scaled(17, scale)
    ).fill()

    NSColor(calibratedRed: 0.92, green: 0.95, blue: 1.00, alpha: 1.0).setFill()
    roundedRect(
        CGRect(x: scaled(348, scale), y: scaled(376, scale), width: scaled(328, scale), height: scaled(50, scale)),
        radius: scaled(25, scale)
    ).fill()

    NSColor.white.withAlphaComponent(0.22).setStroke()
    bodyPath.lineWidth = scaled(8, scale)
    bodyPath.stroke()

    return image
}

for (filename, size) in sizes {
    let image = drawIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(filename)")
    }

    try png.write(to: outputDirectory.appendingPathComponent(filename))
}

print("Generated \(sizes.count) app icon files")
