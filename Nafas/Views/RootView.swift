//
//  RootView.swift
//  Nafas
//
//  Created by Rana Alngashy on 31/03/2026.
//

import SwiftUI
struct RootView: View {
    @State private var showSignInView: Bool = false
    
    var body: some View {
        ZStack {
            if !showSignInView {
                // The view the user sees when LOGGED IN
                NavigationStack {
                    SettingsView(showSignInView: $showSignInView)
                }
            }
        }
        .onAppear {
            // Check if user is already authenticated
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = authUser == nil
        }
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        }
    }
}
