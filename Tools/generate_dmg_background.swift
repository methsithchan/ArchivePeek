import AppKit

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift generate_dmg_background.swift <output-path>")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = CGSize(width: 800, height: 480)

func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawAppMark(in rect: CGRect) {
    let body = roundedRect(rect.insetBy(dx: 9, dy: 12), 28)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.06, green: 0.52, blue: 0.94, alpha: 1.0),
        NSColor(calibratedRed: 0.02, green: 0.34, blue: 0.74, alpha: 1.0)
    ])!.draw(in: body, angle: -90)

    let lid = roundedRect(CGRect(x: rect.minX, y: rect.midY + 6, width: rect.width, height: 42), 16)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.28, green: 0.72, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 0.08, green: 0.48, blue: 0.90, alpha: 1.0)
    ])!.draw(in: lid, angle: 90)

    NSColor.white.withAlphaComponent(0.95).setFill()
    roundedRect(CGRect(x: rect.minX + 31, y: rect.midY + 25, width: 78, height: 8), 4).fill()

    for index in 0..<5 {
        let x = rect.midX - 8 + (index.isMultiple(of: 2) ? -10 : 10)
        roundedRect(CGRect(x: x, y: rect.midY - 8 - CGFloat(index * 17), width: 25, height: 8), 4).fill()
    }

    NSColor.white.withAlphaComponent(0.92).setStroke()
    let lens = NSBezierPath(ovalIn: CGRect(x: rect.maxX - 42, y: rect.minY + 26, width: 48, height: 48))
    lens.lineWidth = 12
    lens.stroke()

    let handle = NSBezierPath()
    handle.lineCapStyle = .round
    handle.lineWidth = 13
    handle.move(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 31))
    handle.line(to: CGPoint(x: rect.maxX + 24, y: rect.minY + 3))
    handle.stroke()
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
bitmap.size = size

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let canvas = CGRect(origin: .zero, size: size)
NSGradient(colors: [
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.18, alpha: 1.0),
    NSColor(calibratedRed: 0.03, green: 0.08, blue: 0.15, alpha: 1.0)
])!.draw(in: canvas, angle: -35)

let glow = NSBezierPath(ovalIn: CGRect(x: -170, y: 250, width: 520, height: 360))
NSColor(calibratedRed: 0.00, green: 0.48, blue: 1.00, alpha: 0.20).setFill()
glow.fill()

let panel = roundedRect(CGRect(x: 38, y: 38, width: 724, height: 404), 28)
NSColor.white.withAlphaComponent(0.075).setFill()
panel.fill()
NSColor.white.withAlphaComponent(0.11).setStroke()
panel.lineWidth = 1
panel.stroke()

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 44, weight: .semibold),
    .foregroundColor: NSColor.white
]
("ArchivePeek" as NSString).draw(at: CGPoint(x: 72, y: 354), withAttributes: titleAttributes)

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 17, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.70)
]
("Drag ArchivePeek to Applications" as NSString).draw(at: CGPoint(x: 75, y: 323), withAttributes: subtitleAttributes)

drawAppMark(in: CGRect(x: 136, y: 158, width: 124, height: 124))

let appLabelAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.92)
]
("ArchivePeek" as NSString).draw(at: CGPoint(x: 124, y: 111), withAttributes: appLabelAttributes)

let folderRect = CGRect(x: 547, y: 164, width: 132, height: 108)
let folderBack = roundedRect(CGRect(x: folderRect.minX + 4, y: folderRect.maxY - 38, width: 58, height: 32), 10)
NSColor(calibratedRed: 0.34, green: 0.72, blue: 1.0, alpha: 1.0).setFill()
folderBack.fill()
let folderBody = roundedRect(folderRect, 18)
NSGradient(colors: [
    NSColor(calibratedRed: 0.42, green: 0.80, blue: 1.0, alpha: 1.0),
    NSColor(calibratedRed: 0.20, green: 0.57, blue: 0.93, alpha: 1.0)
])!.draw(in: folderBody, angle: 90)

let appStoreA = NSBezierPath()
appStoreA.lineWidth = 7
appStoreA.lineCapStyle = .round
NSColor.white.withAlphaComponent(0.42).setStroke()
appStoreA.move(to: CGPoint(x: folderRect.midX - 28, y: folderRect.midY - 10))
appStoreA.line(to: CGPoint(x: folderRect.midX + 28, y: folderRect.midY - 10))
appStoreA.move(to: CGPoint(x: folderRect.midX - 4, y: folderRect.midY - 22))
appStoreA.line(to: CGPoint(x: folderRect.midX + 25, y: folderRect.midY + 33))
appStoreA.move(to: CGPoint(x: folderRect.midX + 4, y: folderRect.midY - 22))
appStoreA.line(to: CGPoint(x: folderRect.midX - 25, y: folderRect.midY + 33))
appStoreA.stroke()

("Applications" as NSString).draw(at: CGPoint(x: 557, y: 111), withAttributes: appLabelAttributes)

let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
NSColor(calibratedRed: 0.52, green: 0.78, blue: 1.0, alpha: 0.88).setStroke()
arrow.move(to: CGPoint(x: 319, y: 221))
arrow.curve(to: CGPoint(x: 479, y: 221), controlPoint1: CGPoint(x: 371, y: 270), controlPoint2: CGPoint(x: 430, y: 172))
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 482, y: 221))
arrowHead.line(to: CGPoint(x: 445, y: 244))
arrowHead.line(to: CGPoint(x: 445, y: 198))
arrowHead.close()
NSColor(calibratedRed: 0.52, green: 0.78, blue: 1.0, alpha: 0.88).setFill()
arrowHead.fill()

let noteAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.46)
]
("After copying, open ArchivePeek once to enable the Quick Look extension." as NSString)
    .draw(at: CGPoint(x: 72, y: 62), withAttributes: noteAttributes)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render DMG background")
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL)
print("Generated \(outputURL.path)")
