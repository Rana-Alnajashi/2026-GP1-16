//
//  SettingsView.swift
//  Nafas
//
//  Created by Rana Alngashy on 31/03/2026.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try AuthenticationManager.shared.signOut()
                        showSignInView = true // This triggers the navigation back
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSignInView: .constant(false))
    }
}
