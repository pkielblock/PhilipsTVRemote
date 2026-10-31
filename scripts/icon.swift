// Draws the app icon: a remote in white line art, its OK button in the accent blue, the power button a white dot.
// Writes PhilipsTVRemote/Assets.xcassets/AppIcon.appiconset/icon-1024.png.  Run: swift scripts/icon.swift
import AppKit
import SwiftUI

let accent = Color(red: 0x34 / 255, green: 0x6b / 255, blue: 0xf1 / 255)

struct Icon: View {
    var body: some View {
        // iOS: full-bleed opaque square, the system applies the mask.
        ZStack {
            LinearGradient(colors: [Color(white: 0.09), Color(white: 0.02)], startPoint: .top, endPoint: .bottom)
            Canvas { ctx, _ in
                let line = GraphicsContext.Shading.color(.white.opacity(0.55))
                let style = StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                let body = CGRect(x: 387, y: 252, width: 250, height: 520)
                ctx.stroke(Path(roundedRect: body, cornerRadius: 72, style: .continuous), with: line, style: style)
                // D-pad ring around the OK button.
                ctx.stroke(Path(ellipseIn: CGRect(x: 512 - 88, y: 470 - 88, width: 176, height: 176)), with: line, style: style)
                ctx.fill(Path(ellipseIn: CGRect(x: 512 - 38, y: 470 - 38, width: 76, height: 76)), with: .color(accent))
                // Volume and channel rockers.
                for x in [462.0, 562.0] {
                    ctx.stroke(Path(roundedRect: CGRect(x: x - 22, y: 610, width: 44, height: 104), cornerRadius: 22), with: line, style: style)
                }
                // Power.
                ctx.fill(Path(ellipseIn: CGRect(x: 512 - 17, y: 318 - 17, width: 34, height: 34)), with: .color(.white))
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let image = MainActor.assumeIsolated { ImageRenderer(content: Icon()).cgImage! }
// Redraw without alpha: App Store rejects icons with an alpha channel.
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
let out = root.appending(path: "PhilipsTVRemote/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
try NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: out)
assert(NSImage(contentsOf: out)?.size == NSSize(width: 1024, height: 1024))
print(out.path)
