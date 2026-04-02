//
//  EditProfileView.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.

import SwiftUI
import Combine

class EditProfileViewModel: ObservableObject {
    @Published var name: String = ""
    
    init() {
        self.name = UserProfileManager.shared.displayName ?? ""
    }
    
    func saveProfile() {
        UserProfileManager.shared.displayName = name.trimmingCharacters(in: .whitespaces)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = EditProfileViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(Color.nafasPrimaryLight).frame(width: 100, height: 100)
                    Text(String(vm.name.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.nafasPrimary)
                }
                .padding(.top, 32)
                
                NafasTextField(
                    labelKey: "edit_profile_name_label",
                    placeholderKey: "edit_profile_name_placeholder",
                    icon: "person",
                    text: $vm.name
                )
                
                Spacer()
                
                NafasPrimaryButton(titleKey: "edit_profile_save_button", isEnabled: !vm.name.isEmpty) {
                    vm.saveProfile()
                    dismiss()
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .background(Color.nafasSurface.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("menu_edit_profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
        }
    }
}
