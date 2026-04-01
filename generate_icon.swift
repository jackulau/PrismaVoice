#!/usr/bin/env swift
import AppKit

// Generate a PrismaVoice app icon: gradient background with microphone symbol
let sizes: [(CGFloat, String)] = [
    (1024, "icon_512x512@2x"),
    (512, "icon_512x512"),
    (512, "icon_256x256@2x"),
    (256, "icon_256x256"),
    (256, "icon_128x128@2x"),
    (128, "icon_128x128"),
    (64, "icon_32x32@2x"),
    (32, "icon_32x32"),
    (32, "icon_16x16@2x"),
    (16, "icon_16x16"),
]

let iconsetPath = "/tmp/PrismaVoice.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22

    // Rounded rect clip
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    // Gradient background: purple → blue → teal (prism colors)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.55, green: 0.22, blue: 0.88, alpha: 1.0),  // Purple
        NSColor(red: 0.25, green: 0.35, blue: 0.95, alpha: 1.0),  // Blue
        NSColor(red: 0.15, green: 0.75, blue: 0.85, alpha: 1.0),  // Teal
    ])!
    gradient.draw(in: rect, angle: -45)

    // Draw microphone symbol using SF Symbols
    let fontSize = size * 0.45
    let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .medium)
    if let micImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let micSize = micImage.size
        let x = (size - micSize.width) / 2
        let y = (size - micSize.height) / 2 - size * 0.02
        let micRect = NSRect(x: x, y: y, width: micSize.width, height: micSize.height)

        // Draw white mic by compositing
        let tinted = NSImage(size: micSize)
        tinted.lockFocus()
        micImage.draw(in: NSRect(origin: .zero, size: micSize))
        NSColor.white.set()
        NSRect(origin: .zero, size: micSize).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.draw(in: micRect, from: .zero, operation: .sourceOver, fraction: 0.95)
    }

    // Draw subtle sound waves
    let waveColor = NSColor.white.withAlphaComponent(0.4)
    waveColor.setStroke()
    for i in 1...3 {
        let waveRadius = size * (0.22 + Double(i) * 0.06)
        let wavePath = NSBezierPath()
        let centerX = size / 2
        let centerY = size / 2
        let startAngle: CGFloat = -40
        let endAngle: CGFloat = 40
        wavePath.appendArc(withCenter: NSPoint(x: centerX + size * 0.12, y: centerY),
                          radius: waveRadius,
                          startAngle: startAngle, endAngle: endAngle)
        wavePath.lineWidth = max(size * 0.02, 1.5)
        wavePath.lineCapStyle = .round
        wavePath.stroke()
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        continue
    }
    try! pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

// Convert iconset to icns
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", "/tmp/PrismaVoice.icns"]
try! process.run()
process.waitUntilExit()

print("Icon generated at /tmp/PrismaVoice.icns")

// Also save the 1024x1024 as a standalone PNG for the repo
try! FileManager.default.copyItem(atPath: "\(iconsetPath)/icon_512x512@2x.png",
                                   toPath: "/tmp/PrismaVoice-icon.png")
print("PNG saved at /tmp/PrismaVoice-icon.png")
