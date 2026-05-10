
import SwiftUI

struct RootView: View {
    @State private var showSignInView: Bool = true
    
    // Global settings for your new menu features
    @AppStorage("nafas_dark_mode") private var darkMode = false
    @AppStorage("nafas_language") private var language = "English"

    var body: some View {
        ZStack {
            if showSignInView {
                AuthenticationView(showSignInView: $showSignInView)
            } else {
                NavigationStack {
                    HomeView(showSignInView: $showSignInView)
                }
            }
        }
        .onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = authUser == nil
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .environment(\.locale, Locale(identifier: language == "English" ? "en" : "ar"))
        .environment(\.layoutDirection, language == "English" ? .leftToRight : .rightToLeft)
    }
}
