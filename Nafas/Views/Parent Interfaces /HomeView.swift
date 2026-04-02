//
//  HomeView.swift
//  Nafas


import SwiftUI
import Combine

// MARK: - Models

struct ChildModel: Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var isConnected: Bool
}

struct WeatherInfo {
    var condition: String
    var advice: String
    var windKmh: Int
    var aqi: Int
    var aqiLabel: String
    var humidityPercent: Int
    var sfSymbol: String
}

enum MenuSheet: Identifiable {
    case editProfile, support, faq
    var id: Int { hashValue }
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var children: [ChildModel] = [
        ChildModel(id: UUID(), name: "Adam Al-Harbi", age: 8, isConnected: true),
        ChildModel(id: UUID(), name: "Nora Al-Harbi", age: 5, isConnected: false)
    ]
    @Published var weather = WeatherInfo(
        condition: "Windy Today",
        advice: "Make sure your child wears a mask outdoors.",
        windKmh: 28, aqi: 42, aqiLabel: "Good",
        humidityPercent: 65, sfSymbol: "wind"
    )
    var greetingKey: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case  5..<12: return "home_good_morning"
        case 12..<18: return "home_good_afternoon"
        default:      return "home_good_evening"
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var showSignInView: Bool
    @StateObject private var vm = HomeViewModel()
    @State private var menuOpen = false
    @State private var showAddChild = false
    @State private var activeSheet: MenuSheet?

    var body: some View {
        ZStack(alignment: .trailing) {

            // Main scrollable content
            HomeContentView(vm: vm, showAddChild: $showAddChild) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    menuOpen = true
                }
            }

            // Dim scrim behind the menu
            if menuOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            menuOpen = false
                        }
                    }
            }

            // Slide-in menu panel
            SideMenuView(showSignInView: $showSignInView, isOpen: $menuOpen, activeSheet: $activeSheet)
                .frame(width: UIScreen.main.bounds.width * 0.82)
                .offset(x: menuOpen ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.38, dampingFraction: 0.88), value: menuOpen)
        }
        .navigationBarHidden(true)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editProfile:
                EditProfileView()
            case .support:
                SupportView()
            case .faq:
                FAQView()
            }
        }
    }
}

// MARK: - Home content

private struct HomeContentView: View {
    @ObservedObject var vm: HomeViewModel
    @ObservedObject var userManager = UserProfileManager.shared // Observes changes instantly
    @Binding var showAddChild: Bool
    let onMenuTap: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 8)
                header
                weatherCard
                childrenSection
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.nafasBackground.ignoresSafeArea())
    }

    // MARK: Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey(vm.greetingKey))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Text(userManager.displayName ?? "")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Text("👋").font(.system(size: 22))
                }
                Text("home_subtitle")
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
            }
            Spacer()
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Circle().fill(Color.nafasDanger)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(Color.nafasTextPrimary)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: Weather card
    private var weatherCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color.nafasPrimary, Color.nafasPrimary.opacity(0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: vm.weather.sfSymbol)
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(vm.weather.condition)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(vm.weather.advice)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    chip("🌫️", "\(vm.weather.windKmh) km/h")
                    chip("🌿", "AQI \(vm.weather.aqi) · \(vm.weather.aqiLabel)")
                    chip("💧", "\(vm.weather.humidityPercent)%")
                }
            }
            .padding(18)
        }
    }

    private func chip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 13))
            Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.18), in: Capsule())
    }

    // MARK: Children section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("home_my_children")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.nafasTextPrimary)
            ForEach(vm.children) { childCard($0) }
            addChildButton
        }
    }

    @ViewBuilder
    private func childCard(_ child: ChildModel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.nafasPrimary).frame(width: 46, height: 46)
                Text(String(child.name.prefix(1)))
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.nafasTextPrimary)
                Text(String(format: NSLocalizedString("home_years_old", comment: ""), child.age))
                    .font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
                StatusBadge(status: child.isConnected ? .connected : .noDevice)
            }
            Spacer()
            if child.isConnected {
                Button {} label: {
                    Text("home_enter_button")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.nafasPrimary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.nafasPrimary.opacity(0.4), lineWidth: 1.5))
                }
            } else {
                Button {} label: {
                    Text("home_connect_button")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var addChildButton: some View {
        Button { showAddChild = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").font(.system(size: 16, weight: .semibold))
                Text("home_add_child").font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.nafasPrimary)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(Color.nafasPrimary.opacity(0.5))
            )
        }
    }
}

// MARK: - Side menu panel

private struct SideMenuView: View {
    @Binding var showSignInView: Bool
    @Binding var isOpen: Bool
    @Binding var activeSheet: MenuSheet?
    
    @ObservedObject var userManager = UserProfileManager.shared
    
    @AppStorage("nafas_dark_mode") private var darkMode  = false
    @AppStorage("nafas_language")  private var language  = "English"

    private var userName: String   { userManager.displayName ?? "—" }
    private var initial:  String   { String(userName.prefix(1)).uppercased() }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isOpen = false }
    }
    
    private func toggleLanguage() {
        // Toggle language logic
        language = (language == "English") ? "Arabic" : "English"
        close()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.nafasSurface
                .clipShape(MenuPanelShape(radius: 28))
                .shadow(color: .black.opacity(0.14), radius: 24, x: -4, y: 0)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── User header ─────────────────────────────────────────
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.nafasPrimary).frame(width: 56, height: 56)
                        Text(initial)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(userName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        Text("menu_guardian_badge")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.nafasPrimary)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color.nafasPrimaryLight, in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)

                Divider()
                    .padding(.horizontal, 24)

                // ── Rows ─────────────────────────────────────────────────
                VStack(spacing: 6) {
                    row(icon: "person", labelKey: "menu_edit_profile") {
                        close()
                        activeSheet = .editProfile
                    }
                    // Health History removed per your request
                    
                    toggleRow(icon: "moon", labelKey: "menu_dark_mode", binding: $darkMode)
                    
                    // Language toggle action
                    valueRow(icon: "globe", labelKey: "menu_language", value: language, action: toggleLanguage)
                    
                    row(icon: "message", labelKey: "menu_contact_support") {
                        close()
                        activeSheet = .support
                    }
                    
                    row(icon: "questionmark.circle", labelKey: "menu_questions_help") {
                        close()
                        activeSheet = .faq
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                // ── Sign out + version ────────────────────────────────────
                Divider().padding(.horizontal, 24)

                Button {
                    try? AuthenticationManager.shared.signOut()
                    UserProfileManager.shared.clearProfile()
                    isOpen = false
                    showSignInView = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                        Text("menu_sign_out")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.nafasDanger)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Text("Nafas v1.0.0")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.nafasTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 36)
            }
        }
    }

    // MARK: Row builders
    @ViewBuilder
    private func row(icon: String, labelKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(labelKey)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func toggleRow(icon: String, labelKey: LocalizedStringKey, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBox(icon)
            Text(labelKey)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.nafasTextPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Color.nafasPrimary)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func valueRow(icon: String, labelKey: LocalizedStringKey, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(labelKey)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Text(NSLocalizedString(value, comment: "Language string"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nafasTextMuted)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func iconBox(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.nafasPrimary.opacity(0.10))
                .frame(width: 38, height: 38)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.nafasPrimary)
        }
    }
}

private struct MenuPanelShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
