import SwiftUI
import Combine

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // Using the NEW ViewModel that handles Firestore and Linking
    @StateObject private var vm = EditProfileViewModel()
    @State private var showPhoneLinkingSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Kept your background color setup
                Color.nafasSurface.ignoresSafeArea()
                
                if vm.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.nafasPrimary)
                } else {
                    VStack(spacing: 24) {
                        
                        // 1. Avatar (Kept your exact design)
                        ZStack {
                            Circle().fill(Color.nafasPrimary.opacity(0.1)).frame(width: 100, height: 100)
                            
                            // Safely get the first letter to avoid a crash if the name is loading
                            let initial = vm.displayName.isEmpty ? "?" : String(vm.displayName.prefix(1)).uppercased()
                            
                            Text(initial)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(Color.nafasPrimary)
                        }
                        .padding(.top, 32)
                        
                        // 2. Editable Name (Kept your custom NafasTextField)
                        NafasTextField(
                            labelKey: "edit_profile_name_label",
                            placeholderKey: "edit_profile_name_placeholder",
                            icon: "person",
                            text: $vm.displayName
                        )
                        
                        // 3. Locked / Linkable Auth Methods (The New Feature!)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("Sign-In Methods"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 0) {
                                // -- Phone Row --
                                if vm.hasPhoneLinked {
                                    lockedRow(icon: "phone.fill", text: vm.phoneNumber)
                                } else {
                                    linkableRow(icon: "phone.fill", text: "Link Phone Number", color: Color.nafasPrimary) {
                                        showPhoneLinkingSheet = true
                                    }
                                }
                                
                                Divider().padding(.leading, 48)
                                
                                // -- Email Row --
                                if vm.hasEmailLinked {
                                    lockedRow(icon: "envelope.fill", text: vm.emailAddress)
                                } else {
                                    linkableRow(icon: "g.circle.fill", text: "Link Google Account", color: .red) {
                                        Task { await vm.linkGoogleAccount() }
                                    }
                                }
                            }
                            .background(Color.nafasBackground) // Uses background to contrast against the surface
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.nafasDivider, lineWidth: 1))
                        }
                        
                        // Success / Error Messages
                        if let error = vm.errorMessage {
                            Text(error).font(.caption).foregroundStyle(Color.nafasDanger)
                        }
                        if let success = vm.successMessage {
                            Text(success).font(.caption).foregroundStyle(.green)
                        }
                        
                        Spacer()
                        
                        // 4. Save Button (Kept your custom NafasPrimaryButton)
                        NafasPrimaryButton(
                            titleKey: "edit_profile_save_button",
                            isLoading: vm.isSaving,
                            isEnabled: !vm.displayName.isEmpty
                        ) {
                            Task {
                                await vm.saveName()
                                // Wait just a moment so the user sees the green success message before closing
                                try? await Task.sleep(nanoseconds: 800_000_000)
                                dismiss()
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 24)
                }
            }
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
            .sheet(isPresented: $showPhoneLinkingSheet) {
                // Future OTP Linking View
                PhoneLinkingView(profileVM: vm)
            }
        }
    }
    
    // MARK: - UI Helpers for Rows
    
    private func lockedRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(Color.nafasTextMuted)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Color.nafasTextMuted)
            
            Spacer()
            
            Image(systemName: "lock.fill") // The padlock
                .font(.system(size: 14))
                .foregroundStyle(Color.nafasTextMuted)
        }
        .padding(16)
        .background(Color.nafasBackground)
    }
    
    private func linkableRow(icon: String, text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(LocalizedStringKey(text))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
                
                Spacer()
                
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            .padding(16)
            .background(Color.nafasBackground)
        }
    }
}
