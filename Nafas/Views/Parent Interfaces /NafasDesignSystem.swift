//
//  NafasDesignSystem.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.
//

import SwiftUI

// MARK: - Color tokens  (names match Assets.xcassets exactly)
extension Color {
    // Brand
    static let nafasPrimary        = Color("Primary")        // Light #1F6FEB  Dark #4D8EF5
    static let nafasPrimaryLight   = Color("PrimaryLight")   // Light #E8F1FD  Dark #1A2A4A
    // Backgrounds
    static let nafasBackground     = Color("Background")     // Light #F5F9FF  Dark #0D1117
    static let nafasSurface        = Color("Surface")        // Light #FFFFFF  Dark #161B22
    static let nafasSurfaceElev    = Color("SurfaceElevated")// Light #FFFFFF  Dark #1E2530
    // Text
    static let nafasTextPrimary    = Color("TextPrimary")    // Light #0D1B2A  Dark #E6EDF3
    static let nafasTextMuted      = Color("TextMuted")      // Light #6B7C93  Dark #7D8FA3
    // Utility
    static let nafasDivider        = Color("Divider")        // Light #E4EBF5  Dark #21262D
    static let nafasSuccess        = Color("Success")        // Light #34C759  Dark #30D158
    static let nafasWarning        = Color("Warning")        // Light #FF9F0A  Dark #FFB340
    static let nafasDanger         = Color("Danger")         // Light #FF3B30  Dark #FF453A
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Font helpers
extension Font {
    static func nafasTitle()    -> Font { .system(size: 28, weight: .bold,     design: .default) }
    static func nafasHeading()  -> Font { .system(size: 22, weight: .bold,     design: .default) }
    static func nafasBody()     -> Font { .system(size: 15, weight: .regular,  design: .default) }
    static func nafasCaption()  -> Font { .system(size: 13, weight: .regular,  design: .default) }
}

// MARK: - Shape helpers
struct BottomRounded: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(r.cgPath)
    }
}

struct TopRounded: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(r.cgPath)
    }
}

// MARK: - NafasLogo
struct NafasLogoMark: View {
    var size: CGFloat = 64
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: Color.nafasPrimary.opacity(0.18), radius: 12, y: 4)
            Image(systemName: "lungs.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.46)
                .foregroundStyle(Color.nafasPrimary)
        }
    }
}

// MARK: - NafasPrimaryButton
struct NafasPrimaryButton: View {
    let titleKey: LocalizedStringKey
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isEnabled ? Color.nafasPrimary : Color.nafasPrimary.opacity(0.45))
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(titleKey)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - NafasTextField
struct NafasTextField: View {
    let labelKey: LocalizedStringKey
    var placeholderKey: LocalizedStringKey
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(Color.nafasTextMuted)
                        .frame(width: 18)
                }
                TextField(placeholderKey, text: $text)
                    .font(.nafasBody())
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nafasBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.nafasDivider, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    enum Status { case connected, noDevice, pending }
    let status: Status

    private var label: LocalizedStringKey {
        switch status {
        case .connected: return "badge_connected"
        case .noDevice:  return "badge_no_device"
        case .pending:   return "badge_pending"
        }
    }
    private var color: Color {
        switch status {
        case .connected: return .nafasSuccess
        case .noDevice:  return .nafasWarning
        case .pending:   return .nafasTextMuted
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Divider with label
struct LabeledDivider: View {
    let key: LocalizedStringKey
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.nafasDivider).frame(height: 1)
            Text(key)
                .font(.nafasCaption())
                .foregroundStyle(Color.nafasTextMuted)
                .fixedSize()
            Rectangle().fill(Color.nafasDivider).frame(height: 1)
        }
    }
}
