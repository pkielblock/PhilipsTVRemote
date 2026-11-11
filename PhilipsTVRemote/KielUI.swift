//  KielUI.swift — Kiel UI v1.0 for SwiftUI (iOS 17+)
//
//  Same tokens as kiel-ui.css: 8-point grid, solid surfaces, one accent,
//  green only for money in / healthy, red only for negative or broken.
//
//  NO ACRYLIC: never use .ultraThinMaterial, .regularMaterial, .glassEffect
//  or any blur. Every surface is a solid Kiel color with a 1 px Kiel.line stroke.
//
//  Drop this file into any target. Fonts use SF Pro (system); sizes follow the grid.
//
//  LANGUAGES: every app ships in English (en) and Brazilian Portuguese (pt-BR).
//  Put all copy in a String Catalog (Localizable.xcstrings) with English keys,
//  never build sentences from pieces, and format numbers, money and dates with
//  the current locale (MoneyText below does). Currency is always BRL.

import SwiftUI
import UIKit

// MARK: - Color helpers

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: alpha))
    }
    /// Adapts to light / dark mode automatically.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Tokens

enum Kiel {
    // Surfaces
    static let bg          = Color(light: 0xF4F5F7, dark: 0x0A0B0D)
    static let surface     = Color(light: 0xFFFFFF, dark: 0x111215)
    static let raised      = Color(light: 0xF8F9FA, dark: 0x16181C)
    static let hover       = Color(light: 0xEFF1F4, dark: 0x1C1E23)
    static let line        = Color(light: 0xE5E7EB, dark: 0x212329)
    static let lineStrong  = Color(light: 0xD4D7DD, dark: 0x2C2F36)
    // Text
    static let text        = Color(light: 0x0E1013, dark: 0xECEDEF)
    static let text2       = Color(light: 0x4A4F59, dark: 0xA1A5AE)
    static let text3       = Color(light: 0x636873, dark: 0x878C96)
    // Accent + meaning
    static let accent      = Color(light: 0x2F5FE8, dark: 0x3D6BF5)
    static let accentText  = Color(light: 0x2550CC, dark: 0x8EAAFF)
    static let pos         = Color(light: 0x0A7A4B, dark: 0x4AD295)
    static let neg         = Color(light: 0xC2382A, dark: 0xFF7D6E)
    static let warn        = Color(light: 0x946000, dark: 0xF2B44A)
    static let onAccent    = Color.white

    /// Data series — always in this order. More than 7: group the rest as series[7].
    static let series: [Color] = [
        Color(hex: 0x5B8CFF), Color(hex: 0x2CC4B4), Color(hex: 0xA68BFA), Color(hex: 0xF472B6),
        Color(hex: 0xF2B44A), Color(hex: 0x98DB5C), Color(hex: 0x5FC8E8), Color(hex: 0x7A7F89)
    ]

    /// App identity colors (icons, launch screens).
    enum App {
        static let rack    = Color(hex: 0x3D6BF5)
        static let lights  = Color(hex: 0xF2B44A)
        static let remote  = Color(hex: 0x7356F5)
        static let fynance = Color(hex: 0x13A05F)
    }

    /// Light temperatures for the Lights app.
    enum LightTemp: String, CaseIterable, Identifiable {
        case warm = "Warm", neutral = "Neutral", cold = "Cold"
        var id: String { rawValue }
        var color: Color {
            switch self {
            case .warm:    return Color(hex: 0xF7C77A)
            case .neutral: return Color(hex: 0xF5E9D6)
            case .cold:    return Color(hex: 0xCFE0FF)
            }
        }
    }

    /// 8-point grid. s1 and s3 are the compact half-steps.
    enum Space {
        static let s1: CGFloat = 4,  s2: CGFloat = 8,  s3: CGFloat = 12, s4: CGFloat = 16
        static let s6: CGFloat = 24, s8: CGFloat = 32, s10: CGFloat = 40, s12: CGFloat = 48, s16: CGFloat = 64
    }

    enum Radius {
        static let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 12, lg: CGFloat = 16, xl: CGFloat = 24
    }

    enum Size {
        static let controlSM: CGFloat = 32, controlMD: CGFloat = 40, controlLG: CGFloat = 48
        static let key: CGFloat = 56          // remote keys, touch targets
        static let tileMinHeight: CGFloat = 136
    }

    /// Font sizes step by 2; line spacing lands on multiples of 4.
    enum Font {
        static let caption    = SwiftUI.Font.system(size: 12, weight: .medium)
        static let footnote   = SwiftUI.Font.system(size: 14)
        static let body       = SwiftUI.Font.system(size: 16)
        static let bodyStrong = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let headline   = SwiftUI.Font.system(size: 18, weight: .semibold)
        static let title      = SwiftUI.Font.system(size: 20, weight: .semibold)
        static let h1         = SwiftUI.Font.system(size: 24, weight: .semibold)
        static let largeTitle = SwiftUI.Font.system(size: 32, weight: .bold)
        static func money(_ size: CGFloat) -> SwiftUI.Font { .system(size: size, weight: .semibold).monospacedDigit() }
        static let eyebrow    = SwiftUI.Font.system(size: 12, weight: .medium, design: .monospaced)
    }

    /// Motion tokens — mirror the CSS ones.
    enum Motion {
        static let micro    = Animation.easeOut(duration: 0.12)           // hover, color
        static let standard = Animation.snappy(duration: 0.2)             // toggles, tabs
        static let expand   = Animation.smooth(duration: 0.32)            // expand, sheets
        static let page     = Animation.spring(response: 0.45, dampingFraction: 0.9)
        static let press    = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let chart    = Animation.easeOut(duration: 0.8)
    }
}

// MARK: - Surfaces

struct KielCardModifier: ViewModifier {
    var padding: CGFloat = Kiel.Space.s4
    var radius: CGFloat = Kiel.Radius.xl
    var stroke: Color = Kiel.line

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Kiel.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(stroke, lineWidth: 1))
    }
}

extension View {
    /// Solid card. Never a material.
    func kielCard(padding: CGFloat = Kiel.Space.s4, radius: CGFloat = Kiel.Radius.xl, stroke: Color = Kiel.line) -> some View {
        modifier(KielCardModifier(padding: padding, radius: radius, stroke: stroke))
    }

    /// Fade + rise on appear, staggered by index (max 6 steps).
    func kielEnter(index: Int = 0) -> some View {
        modifier(KielEnter(delay: Double(min(index, 6)) * 0.06))
    }
}

struct KielEnter: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
            .onAppear { withAnimation(Kiel.Motion.page.delay(delay)) { shown = true } }
    }
}

// MARK: - Buttons

struct KielButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, ghost, danger }
    enum Size { case small, medium, large
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 56
            }
        }
    }
    var kind: Kind = .secondary
    var size: Size = .medium
    var capsule: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: capsule ? size.height / 2 : Kiel.Radius.sm, style: .continuous)
        configuration.label
            .font(size == .large ? Kiel.Font.bodyStrong : Kiel.Font.footnote.weight(.medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .large ? Kiel.Space.s6 : Kiel.Space.s4)
            .frame(minHeight: size.height)
            .background(configuration.isPressed ? pressedBackground : background, in: shape)
            .overlay(shape.stroke(kind == .secondary ? Kiel.line : .clear, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Kiel.Motion.press, value: configuration.isPressed)
            .contentShape(shape)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Kiel.onAccent
        case .secondary: return Kiel.text
        case .ghost: return Kiel.text2
        case .danger: return Kiel.neg
        }
    }
    private var background: Color {
        switch kind {
        case .primary: return Kiel.accent
        case .secondary: return Kiel.raised
        case .ghost: return .clear
        case .danger: return Kiel.neg.opacity(0.12)
        }
    }
    private var pressedBackground: Color {
        switch kind {
        case .primary: return Kiel.accent.opacity(0.85)
        case .secondary, .ghost: return Kiel.hover
        case .danger: return Kiel.neg.opacity(0.2)
        }
    }
}

/// Remote-control key: capsule, springy press, light haptic.
struct KielKeyStyle: ButtonStyle {
    var height: CGFloat = 64
    var tint: Color = Kiel.text

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Kiel.Font.footnote.weight(.medium))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(configuration.isPressed ? Kiel.hover : Kiel.raised, in: Capsule())
            .overlay(Capsule().stroke(Kiel.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(Kiel.Motion.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
            .contentShape(Capsule())
    }
}

/// Icon + label key used on the TV remote (Adjust, Search, Guide…).
struct RemoteKey: View {
    let title: String?
    let systemImage: String
    var tint: Color = Kiel.text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Kiel.Space.s1) {
                Image(systemName: systemImage).font(.system(size: 20, weight: .medium))
                if let title { Text(title).font(Kiel.Font.caption) }
            }
        }
        .buttonStyle(KielKeyStyle(height: title == nil ? 64 : 72, tint: tint))
        .accessibilityLabel(title ?? systemImage)
    }
}

// MARK: - Status

struct StatusDot: View {
    var color: Color = Kiel.pos
    /// Pulse only for things that are live or broken.
    var live: Bool = false
    @State private var ping = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if live && !reduceMotion {
                Circle().fill(color)
                    .scaleEffect(ping ? 2.8 : 1)
                    .opacity(ping ? 0 : 0.55)
            }
            Circle().fill(color)
        }
        .frame(width: 8, height: 8)
        .onAppear {
            guard live else { return }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { ping = true }
        }
    }
}

struct KielBadge: View {
    enum Tone { case neutral, pos, warn, neg, accent }
    let text: String
    var tone: Tone = .neutral

    var body: some View {
        HStack(spacing: 6) {
            if tone != .neutral { Circle().fill(fg).frame(width: 6, height: 6) }
            Text(text).font(Kiel.Font.caption)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, Kiel.Space.s2)
        .frame(height: 24)
        .background(bg, in: RoundedRectangle(cornerRadius: Kiel.Radius.sm, style: .continuous))
    }
    private var fg: Color {
        switch tone {
        case .neutral: return Kiel.text2
        case .pos: return Kiel.pos
        case .warn: return Kiel.warn
        case .neg: return Kiel.neg
        case .accent: return Kiel.accentText
        }
    }
    private var bg: Color {
        switch tone {
        case .neutral: return Kiel.raised
        case .pos: return Kiel.pos.opacity(0.12)
        case .warn: return Kiel.warn.opacity(0.13)
        case .neg: return Kiel.neg.opacity(0.12)
        case .accent: return Kiel.accent.opacity(0.16)
        }
    }
}

/// 0…1 meter. Color follows the threshold rule: < 50 % green, < 80 % amber, else red.
struct KielMeter: View {
    let value: Double
    var mark: Double? = nil        // reference line, e.g. 0.5 for "30 % of income" on a 0–60 scale
    var neutralColor: Color? = nil // override when thresholds don't apply
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Kiel.hover)
                Capsule().fill(neutralColor ?? color)
                    .frame(width: geo.size.width * (shown ? min(max(value, 0), 1) : 0))
                if let mark {
                    RoundedRectangle(cornerRadius: 1).fill(Kiel.text2)
                        .frame(width: 2, height: 16)
                        .offset(x: geo.size.width * mark - 1)
                }
            }
        }
        .frame(height: 8)
        .onAppear { withAnimation(Kiel.Motion.chart) { shown = true } }
        .accessibilityValue(Text("\(Int(value * 100)) percent"))
    }
    private var color: Color { value >= 0.8 ? Kiel.neg : (value >= 0.5 ? Kiel.warn : Kiel.pos) }
}

// MARK: - Money

/// BRL amount with smaller currency and cents, formatted for the locale:
/// "R$ 6.797,56" in pt-BR, "R$6,797.56" in en.
/// income: green with "+"; spend: text color with "−"; balance: red when negative.
struct MoneyText: View {
    enum Kind { case neutral, income, spend, balance }
    let value: Double
    var size: CGFloat = 28
    var kind: Kind = .neutral
    var locale: Locale = .current

    var body: some View {
        let parts = Self.split(abs(value), locale: locale)
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(sign + "R$").font(.system(size: size * 0.5, weight: .medium))
            Text(parts.int).font(Kiel.Font.money(size)).kerning(-size * 0.03)
                + Text(parts.cents).font(.system(size: size * 0.56, weight: .medium).monospacedDigit())
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(value, format: .currency(code: "BRL").locale(locale)))
    }

    private var sign: String {
        switch kind {
        case .income: return "+"
        case .spend: return "−"
        case .balance, .neutral: return value < 0 ? "−" : ""
        }
    }
    private var color: Color {
        switch kind {
        case .income: return Kiel.pos
        case .balance: return value < 0 ? Kiel.neg : Kiel.text
        case .spend, .neutral: return Kiel.text
        }
    }
    static func split(_ v: Double, locale: Locale) -> (int: String, cents: String) {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let s = f.string(from: NSNumber(value: v)) ?? "0"
        let sep = Character(f.decimalSeparator ?? ".")
        guard let i = s.lastIndex(of: sep) else { return (s, "") }
        return (String(s[..<i]), String(s[i...]))
    }
}

// MARK: - Service icon (Netflix, Pi-hole, a bank…)

/// Always the official icon of the service. Sources, in order:
/// 1. icon pack (dashboard-icons for self-hosted apps, Simple Icons for brands)
/// 2. the site's apple-touch-icon / favicon, fetched and cached by your server
/// 3. monogram fallback
struct ServiceIcon: View {
    let name: String
    var url: URL? = nil
    var size: CGFloat = 40
    /// true when the icon has its own background (Netflix, Spotify); false for transparent glyphs.
    var fillsTile: Bool = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
        ZStack {
            Kiel.raised
            AsyncImage(url: url, transaction: Transaction(animation: Kiel.Motion.standard)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: fillsTile ? .fill : .fit)
                        .padding(fillsTile ? 0 : size * 0.15)
                        .transition(.opacity)
                default:
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(Kiel.text2)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.stroke(Kiel.line, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

// MARK: - Lists

struct KielRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: Kiel.Space.s3) {
            leading
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(Kiel.Font.body.weight(.medium)).foregroundStyle(Kiel.text).lineLimit(1)
                if let subtitle { Text(subtitle).font(Kiel.Font.caption).foregroundStyle(Kiel.text3).lineLimit(1) }
            }
            Spacer(minLength: Kiel.Space.s2)
            trailing
        }
        .padding(.vertical, Kiel.Space.s2)
        .frame(minHeight: Kiel.Size.controlLG)
        .contentShape(Rectangle())
    }
}

struct SectionHeader: View {
    let title: String
    var action: (title: String, run: () -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(Kiel.Font.title).foregroundStyle(Kiel.text)
            Spacer()
            if let action { Button(action.title, action: action.run).font(Kiel.Font.footnote.weight(.medium)).foregroundStyle(Kiel.accentText) }
        }
    }
}

// MARK: - Lights

/// Lamp or group tile: bulb in the light's real color, power button, name, status.
struct LampTile: View {
    let name: String
    let isOn: Bool
    var brightness: Int = 100
    var temp: Kiel.LightTemp = .cold
    var isSelected: Bool = false
    let onToggle: () -> Void
    var onOpen: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 28))
                    .foregroundStyle(isOn ? temp.color : Kiel.text3)
                    .contentTransition(.symbolEffect(.replace))
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: "power").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isOn ? Kiel.onAccent : Kiel.text3)
                        .frame(width: 56, height: 56)
                        .background(isOn ? Kiel.accent : Kiel.raised, in: Circle())
                }
                .buttonStyle(PressScale())
                .sensoryFeedback(.selection, trigger: isOn)
                .accessibilityLabel(isOn ? "Turn off \(name)" : "Turn on \(name)")
            }
            Spacer(minLength: Kiel.Space.s4)
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(Kiel.Font.headline).foregroundStyle(Kiel.text).lineLimit(1)
                    Text(isOn ? "\(temp.rawValue) · \(brightness)%" : "Off")
                        .font(Kiel.Font.footnote).foregroundStyle(Kiel.text3)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: Kiel.Size.tileMinHeight)
        .kielCard(padding: Kiel.Space.s4, radius: Kiel.Radius.xl, stroke: isSelected ? Kiel.accent : Kiel.line)
        .animation(Kiel.Motion.standard, value: isOn)
    }
}

/// Large brightness bar: the fill is the control.
struct BrightnessBar: View {
    @Binding var value: Double   // 0...1
    var tint: Color = Kiel.LightTemp.warm.color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Kiel.raised)
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint)
                    .frame(width: max(56, geo.size.width * value))
                Image(systemName: "sun.max.fill").foregroundStyle(Color(hex: 0x111215)).padding(.leading, Kiel.Space.s4)
            }
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Kiel.line, lineWidth: 1))
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                value = min(max(g.location.x / geo.size.width, 0.01), 1)
            })
        }
        .frame(height: 56)
        .animation(Kiel.Motion.micro, value: value)
        .sensoryFeedback(.selection, trigger: Int(value * 10))
        .accessibilityElement()
        .accessibilityLabel("Brightness")
        .accessibilityValue("\(Int(value * 100)) percent")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: value = min(1, value + 0.1)
            case .decrement: value = max(0.01, value - 0.1)
            default: break
            }
        }
    }
}

// MARK: - TV remote

struct RemoteStatusBar: View {
    let connected: Bool
    let message: String   // "Connected" or "Sent · OK"
    let volume: Int

    var body: some View {
        HStack(spacing: Kiel.Space.s3) {
            StatusDot(color: connected ? Kiel.pos : Kiel.text3, live: connected)
            Text(message).font(Kiel.Font.footnote).foregroundStyle(Kiel.text2)
                .contentTransition(.opacity)
            Spacer()
            Image(systemName: "speaker.wave.2").foregroundStyle(Kiel.text3)
            Text("\(volume)").font(Kiel.Font.footnote.weight(.semibold)).monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Kiel.Space.s4)
        .frame(height: Kiel.Size.controlLG)
        .background(Kiel.surface, in: Capsule())
        .overlay(Capsule().stroke(Kiel.line, lineWidth: 1))
        .animation(Kiel.Motion.standard, value: message)
    }
}

enum DPadKey { case up, down, left, right, ok }

struct DPad: View {
    var size: CGFloat = 272
    let onPress: (DPadKey) -> Void

    var body: some View {
        ZStack {
            Circle().fill(Kiel.surface).overlay(Circle().stroke(Kiel.line, lineWidth: 1))
            VStack { arrow("chevron.up", .up); Spacer(); arrow("chevron.down", .down) }.padding(Kiel.Space.s2)
            HStack { arrow("chevron.left", .left); Spacer(); arrow("chevron.right", .right) }.padding(Kiel.Space.s2)
            Button { onPress(.ok) } label: {
                Text("OK").font(.system(size: 22, weight: .semibold)).foregroundStyle(Kiel.text)
                    .frame(width: size * 0.38, height: size * 0.38)
                    .background(Kiel.raised, in: Circle())
                    .overlay(Circle().stroke(Kiel.lineStrong, lineWidth: 1))
            }
            .buttonStyle(PressScale(scale: 0.9))
        }
        .frame(width: size, height: size)
    }

    private func arrow(_ symbol: String, _ key: DPadKey) -> some View {
        Button { onPress(key) } label: {
            Image(systemName: symbol).font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Kiel.accentText)
                .frame(width: 72, height: 64)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScale(scale: 0.85))
        .accessibilityLabel(String(describing: key))
    }
}

/// Generic spring press for custom buttons.
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Kiel.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Kiel UI") {
    ScrollView {
        VStack(alignment: .leading, spacing: Kiel.Space.s6) {
            Text("Lights").font(Kiel.Font.largeTitle).foregroundStyle(Kiel.text)
            HStack(spacing: Kiel.Space.s3) {
                Button { } label: { Label("All on", systemImage: "lightbulb.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(KielButtonStyle(kind: .secondary, size: .large, capsule: true))
                Button { } label: { Label("All off", systemImage: "lightbulb.slash").frame(maxWidth: .infinity) }
                    .buttonStyle(KielButtonStyle(kind: .secondary, size: .large, capsule: true))
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Kiel.Space.s3), GridItem(.flexible())], spacing: Kiel.Space.s3) {
                LampTile(name: "Abajur Cama", isOn: true, brightness: 80, temp: .warm, onToggle: {}).kielEnter(index: 0)
                LampTile(name: "Abajur PC", isOn: false, onToggle: {}).kielEnter(index: 1)
            }
            MoneyText(value: -1646.01, size: 48, kind: .balance)
            KielMeter(value: 0.506)
            HStack { KielBadge(text: String(localized: "Paid"), tone: .pos); KielBadge(text: String(localized: "Pending"), tone: .warn); KielBadge(text: String(localized: "Overdue"), tone: .neg) }
            RemoteStatusBar(connected: true, message: "Connected", volume: 25)
            DPad { _ in }.frame(maxWidth: .infinity)
        }
        .padding(Kiel.Space.s4)
    }
    .background(Kiel.bg)
    .preferredColorScheme(.dark)
}
