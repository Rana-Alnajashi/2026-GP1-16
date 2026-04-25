import SwiftUI
import Combine




// MARK: - HomeView
struct HomeView: View {
    @Binding var showSignInView: Bool
    @StateObject private var vm = HomeViewModel()
    @ObservedObject private var store = NafasStore.shared
    @State private var menuOpen = false
    @State private var showAddChild = false
    @State private var showNotifications = false
    @State private var activeSheet: MenuSheet?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .trailing) {
                // Main content
                HomeContentView(
                    vm: vm,
                    store: store,
                    showAddChild: $showAddChild
                )

                // Dim scrim
                if menuOpen {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            toggleMenu()
                        }
                }

                // Side menu
                SideMenuView(
                    showSignInView: $showSignInView,
                    isOpen: $menuOpen,
                    activeSheet: $activeSheet
                )
                .frame(width: UIScreen.main.bounds.width * 0.82)
                .offset(x: menuOpen ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.38, dampingFraction: 0.88), value: menuOpen)
            }
            .navigationDestination(for: ChildModel.self) { child in
                ChildDetailView(child: child)
            }
            // Buttons moved here to match ChildDetailView location
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showNotifications = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.nafasTextPrimary)
                                if store.children.contains(where: { c in
                                    let v = store.latestVitals[c.id.uuidString]
                                    return v?.spO2Status == .low
                                }) {
                                    Circle().fill(Color.nafasDanger)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        Button(action: { toggleMenu() }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(Color.nafasTextPrimary)
                        }
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editProfile: EditProfileView()
            case .support: SupportView()
            case .faq: FAQView()
            }
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
    }
    
    private func toggleMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            menuOpen.toggle()
        }
    }
}

// MARK: - Home Content View
struct HomeContentView: View {
    @ObservedObject var vm: HomeViewModel
    @ObservedObject var store: NafasStore
    @ObservedObject var userManager = UserProfileManager.shared
    @Binding var showAddChild: Bool

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
                Text(LocalizedStringKey("home_subtitle"))
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
            }
            Spacer()
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
                        .font(.system(size: 22)).foregroundStyle(.white.opacity(0.9))
                    Text(vm.weather.condition)
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                }
                Text(vm.weather.advice)
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)).lineLimit(3)
            }
            .padding(18)
        }
    }

    // MARK: Children section
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(LocalizedStringKey("home_my_children"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Text(String.localizedStringWithFormat(NSLocalizedString("home_children_count %lld", comment: ""), store.children.count))
                    .font(.nafasCaption())
                    .foregroundStyle(Color.nafasTextMuted)
                    .font(.nafasCaption())
                    .foregroundStyle(Color.nafasTextMuted)
            }
            ForEach(store.children) { child in
                childCard(child)
            }
            addChildButton
        }
    }

    @ViewBuilder
    private func childCard(_ child: ChildModel) -> some View {
        let vitals = store.latestVitals[child.id.uuidString]
        let hasAlert = vitals?.spO2Status == .low || vitals?.peakZone == .red

        NavigationLink(value: child) {
            HStack(spacing: 14) {
                ZStack {
                    if let avatarData = child.avatarImageData,
                       let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(hex: child.avatarColor))
                            .frame(width: 46, height: 46)
                        Text(String(child.name.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if hasAlert {
                        Circle().fill(Color.nafasDanger)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(Color.nafasSurface, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Text(LocalizedStringKey("child_age_years_old %d"))
                        .font(.nafasCaption())
                        .foregroundStyle(Color.nafasTextMuted)
                    StatusBadge(status: child.isConnected ? .connected : .noDevice)
                }
                Spacer()

                if child.isConnected {
                    Text(LocalizedStringKey("home_enter_button"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.nafasPrimary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.nafasPrimary.opacity(0.4), lineWidth: 1.5)
                        )
                } else {
                    Text(LocalizedStringKey("home_connect_button"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(16)
            .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(hasAlert ? Color.nafasDanger : Color.clear, lineWidth: 3)
            )
            .shadow(color: hasAlert ? Color.nafasDanger.opacity(0.35) : .clear, radius: 8, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addChildButton: some View {
        Button { showAddChild = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle").font(.system(size: 16, weight: .semibold))
                Text(LocalizedStringKey("home_add_child")).font(.system(size: 15, weight: .semibold))
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

// MARK: - Side Menu View
struct SideMenuView: View {
    @Binding var showSignInView: Bool
    @Binding var isOpen: Bool
    @Binding var activeSheet: MenuSheet?
    @ObservedObject var userManager = UserProfileManager.shared
    @AppStorage("nafas_dark_mode") private var darkMode = false
    @AppStorage("nafas_language") private var language = "English"

    private var userName: String { userManager.displayName ?? "—" }
    private var initial: String { String(userName.prefix(1)).uppercased() }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isOpen = false }
    }
    
    private func toggleLanguage() {
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
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.nafasPrimary).frame(width: 56, height: 56)
                        Text(initial)
                            .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(userName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        Text(LocalizedStringKey("menu_guardian_badge"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.nafasPrimary)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color.nafasPrimaryLight, in: Capsule())
                    }
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 24)

                Divider().padding(.horizontal, 24)

                VStack(spacing: 6) {
                    row(icon: "person", labelKey: "menu_edit_profile") { close(); activeSheet = .editProfile }
                    toggleRow(icon: "moon", labelKey: "menu_dark_mode", binding: $darkMode)
                    valueRow(icon: "globe", labelKey: "menu_language", value: language, action: toggleLanguage)
                    row(icon: "message", labelKey: "menu_contact_support") { close(); activeSheet = .support }
                    row(icon: "questionmark.circle", labelKey: "menu_questions_help") { close(); activeSheet = .faq }
                }
                .padding(.horizontal, 16).padding(.top, 14)

                Spacer()
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
                        Text(LocalizedStringKey("menu_sign_out"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.nafasDanger)
                }
                .padding(.horizontal, 24).padding(.top, 18)

                Text("Nafas v1.0.0")
                    .font(.system(size: 12)).foregroundStyle(Color.nafasTextMuted)
                    .frame(maxWidth: .infinity).padding(.top, 10).padding(.bottom, 36)
            }
        }
    }

    @ViewBuilder
    private func row(icon: String, labelKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(labelKey).font(.system(size: 15, weight: .medium)).foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func toggleRow(icon: String, labelKey: LocalizedStringKey, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBox(icon)
            Text(labelKey).font(.system(size: 15, weight: .medium)).foregroundStyle(Color.nafasTextPrimary)
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(Color.nafasPrimary).scaleEffect(0.85)
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func valueRow(icon: String, labelKey: LocalizedStringKey, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(labelKey).font(.system(size: 15, weight: .medium)).foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Text(LocalizedStringKey(value))
                    .font(.system(size: 14)).foregroundStyle(Color.nafasTextMuted)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func iconBox(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.nafasPrimary.opacity(0.10)).frame(width: 38, height: 38)
            Image(systemName: systemName).font(.system(size: 16, weight: .medium)).foregroundStyle(Color.nafasPrimary)
        }
    }
}

// MARK: - Notifications View
struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let titleKey: String
    let bodyKey: String
    let timeKey: String
    let isAlert: Bool
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    private let notifications: [AppNotification] = [
        AppNotification(
            icon: "exclamationmark.triangle.fill",
            iconColor: Color.nafasDanger,
            titleKey: "notif_attack_title",
            bodyKey: "notif_attack_body",
            timeKey: "notif_time_now",
            isAlert: true
        ),
        AppNotification(
            icon: "wind",
            iconColor: Color.nafasPrimary,
            titleKey: "notif_weather_title",
            bodyKey: "notif_weather_body",
            timeKey: "notif_time_1h",
            isAlert: false
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(notifications) { notif in
                        notifRow(notif)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("notif_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.nafasTextMuted)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func notifRow(_ notif: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(notif.iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: notif.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(notif.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStringKey(notif.titleKey))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Spacer()
                    Text(LocalizedStringKey(notif.timeKey))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.nafasTextMuted)
                }
                Text(LocalizedStringKey(notif.bodyKey))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.nafasTextMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(notif.isAlert ? Color.nafasDanger : Color.clear, lineWidth: 2)
        )
        .shadow(color: notif.isAlert
            ? Color.nafasDanger.opacity(0.2)
            : Color.black.opacity(0.04),
            radius: 8, y: 2)
    }
}

// MARK: - Menu Panel Shape
struct MenuPanelShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
