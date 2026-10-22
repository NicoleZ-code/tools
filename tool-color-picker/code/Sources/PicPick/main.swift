import AppKit
import SwiftUI

@main
struct PicPickApp: App {
    var body: some Scene {
        WindowGroup {
            ColorPickerView()
                .frame(width: 360, height: 375)
        }
        .windowResizability(.contentSize)
        .windowStyle(.automatic)
    }
}

@MainActor
final class PickerModel: ObservableObject {
    @Published var color = Color(red: 0.31, green: 0.48, blue: 0.91)
    @Published var hex = "#4F7AF0"
    @Published var rgb = "RGB(79, 122, 240)"
    @Published var format = "HEX"
    @Published var history: [String] = []
    @Published var isPicking = false
    @Published var copied = false
    @Published var hue: Double = 0.07
    @Published var saturation: Double = 0.78
    @Published var brightness: Double = 0.82

    private var copyReset: DispatchWorkItem?

    func pick() {
        guard !isPicking else { return }
        isPicking = true
        NSColorSampler().show { [weak self] sampled in
            guard let self else { return }
            self.isPicking = false
            guard let sampled, let converted = sampled.usingColorSpace(.deviceRGB) else { return }
            self.setColor(red: converted.redComponent, green: converted.greenComponent, blue: converted.blueComponent)
        }
    }

    func setColor(red: CGFloat, green: CGFloat, blue: CGFloat) {
        let r = Int((red * 255).rounded()), g = Int((green * 255).rounded()), b = Int((blue * 255).rounded())
        hex = String(format: "#%02X%02X%02X", r, g, b)
        rgb = "RGB(\(r), \(g), \(b))"
        color = Color(red: Double(red), green: Double(green), blue: Double(blue))
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0
        NSColor(red: red, green: green, blue: blue, alpha: 1).usingColorSpace(.deviceRGB)?.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        hue = Double(h); saturation = Double(s); brightness = Double(v)
        history.removeAll { $0 == hex }
        history.insert(hex, at: 0)
        history = Array(history.prefix(8))
    }

    func choose(_ value: String) {
        guard value.count == 7,
              let r = UInt8(value.dropFirst().prefix(2), radix: 16),
              let g = UInt8(value.dropFirst(3).prefix(2), radix: 16),
              let b = UInt8(value.dropFirst(5).prefix(2), radix: 16) else { return }
        setColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255)
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(format == "HEX" ? hex : rgb, forType: .string)
        copied = true
        copyReset?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.copied = false }
        copyReset = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: task)
    }
}

struct ColorPickerView: View {
    @StateObject private var model = PickerModel()
    @FocusState private var fieldFocused: Bool

    private let ink = Color(red: 0.16, green: 0.17, blue: 0.19)
    private let muted = Color(red: 0.56, green: 0.57, blue: 0.59)
    private let accent = Color(red: 0.18, green: 0.20, blue: 0.23)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                PickerLogo().frame(width: 18, height: 18)
                Text("Color Picker")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.27, blue: 0.39))
                Spacer()
            }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .padding(.top, 4)
            colorField
            controls.padding(.top, 8)
            codeRow.padding(.top, 5)
            Text(model.format).font(.system(size: 10)).foregroundStyle(muted)
                .frame(maxWidth: .infinity).padding(.top, 2)
            Divider().padding(.top, 4)
            recentPanel.padding(.top, 5)
            footer.padding(.top, 8)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .background(.white)
        .foregroundStyle(ink)
        .onChange(of: model.hue) { _ in applyHSB() }
        .onChange(of: model.saturation) { _ in applyHSB() }
        .onChange(of: model.brightness) { _ in applyHSB() }
    }

    private var colorField: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle().fill(LinearGradient(colors: [.white, Color(hue: model.hue, saturation: 0.8, brightness: 0.95), .black], startPoint: .topLeading, endPoint: .bottomLeading))
            Circle().stroke(.white, lineWidth: 1.5).background(Circle().stroke(.black.opacity(0.35), lineWidth: 0.5))
                .frame(width: 13, height: 13).offset(x: -76, y: 51)
        }
        .frame(height: 130).clipped().clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button(action: model.pick) { Image(systemName: "eyedropper").font(.system(size: 16)).frame(width: 25, height: 28) }
                .buttonStyle(.plain).help("Pick Screen Color")
            Circle().fill(model.color).frame(width: 29, height: 29).overlay(Circle().stroke(.black.opacity(0.08), lineWidth: 1))
            VStack(spacing: 6) {
                Slider(value: $model.hue, in: 0...1).tint(.clear).overlay {
                    LinearGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], startPoint: .leading, endPoint: .trailing)
                        .frame(height: 7).clipShape(Capsule()).allowsHitTesting(false)
                }
                Slider(value: $model.saturation, in: 0...1).tint(model.color)
            }
        }
    }

    private var codeRow: some View {
        HStack(spacing: 5) {
            TextField("HEX", text: $model.hex).font(.system(size: 12, weight: .semibold, design: .monospaced))
                .textFieldStyle(.plain).multilineTextAlignment(.center).focused($fieldFocused)
                .onSubmit { model.choose(model.hex); fieldFocused = false }
                .padding(6).frame(height: 29).overlay(RoundedRectangle(cornerRadius: 4).stroke(.gray.opacity(0.45), lineWidth: 0.8))
            Button(action: model.copy) {
                Image(systemName: model.copied ? "checkmark" : "doc.on.doc").font(.system(size: 12)).frame(width: 28, height: 28)
            }.buttonStyle(.plain).help(model.copied ? "Copied" : "Copy Color")
            Picker("Format", selection: $model.format) { Text("HEX").tag("HEX"); Text("RGB").tag("RGB") }
                .labelsHidden().frame(width: 56)
        }
    }

    private var recentPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack { Text("Recent Colors").font(.system(size: 11, weight: .medium)); Spacer(); Text("Up to 8").font(.system(size: 9)).foregroundStyle(muted) }
            if model.history.isEmpty {
                HStack(spacing: 7) {
                    ForEach(["#E53935", "#8E24AA", "#3949AB", "#00897B", "#FDD835", "#FB8C00", "#5E35B1", "#546E7A"], id: \.self) { value in
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: value)).frame(width: 15, height: 15)
                    }
                }.padding(.vertical, 2)
            } else {
                HStack(spacing: 10) {
                    ForEach(model.history, id: \.self) { value in
                        Button { model.choose(value) } label: {
                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: value))
                                .frame(width: 17, height: 17).overlay(RoundedRectangle(cornerRadius: 3).stroke(.black.opacity(0.07), lineWidth: 1))
                        }
                        .buttonStyle(.plain).help(value)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Image(systemName: "info.circle").foregroundStyle(muted)
            Text("Multi-Display · Click a screen color to pick").foregroundStyle(muted)
            Spacer()
            Button(model.isPicking ? "Picking…" : "Pick Screen Color") { model.pick() }
                .buttonStyle(.borderedProminent).controlSize(.small).tint(accent).disabled(model.isPicking)
        }.font(.system(size: 9))
    }

    private func applyHSB() {
        let c = NSColor(hue: model.hue, saturation: model.saturation, brightness: model.brightness, alpha: 1)
        model.setColor(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent)
    }
}

struct PickerLogo: View {
    private let ring = AngularGradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red], center: .center)
    var body: some View {
        ZStack {
            Circle().stroke(ring, lineWidth: 4)
            Image(systemName: "eyedropper").font(.system(size: 10, weight: .bold))
                .rotationEffect(.degrees(-38)).foregroundStyle(Color(red: 0.13, green: 0.21, blue: 0.30))
        }
    }
}

extension Color {
    init(hex: String) {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 0xff) / 255,
                  green: Double((value >> 8) & 0xff) / 255,
                  blue: Double(value & 0xff) / 255)
    }
}
