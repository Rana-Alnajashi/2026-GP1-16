import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PhoneLinkingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authVM = AuthenticationViewModel()
    @ObservedObject var profileVM: EditProfileViewModel
    
    @State private var showOTP = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Link Phone Number").font(.title2.bold()).padding(.top, 32)
                
                HStack(spacing: 12) {
                    Text(authVM.countryCode).fontWeight(.semibold)
                    Divider().frame(height: 24)
                    TextField("50 123 4567", text: $authVM.localPhoneNumber).keyboardType(.phonePad)
                }
                .padding().background(Color.nafasSurface).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1))
                
                if let err = authVM.phoneAuthError {
                    Text(err).font(.caption).foregroundColor(Color.nafasDanger)
                }
                
                Button {
                    Task {
                        await authVM.sendPhoneVerification()
                        if authVM.verificationID != nil { showOTP = true }
                    }
                } label: {
                    Text(authVM.isPhoneAuthLoading ? "Sending..." : "Send Verification Code")
                        .fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                        .background(authVM.localPhoneNumber.count >= 9 ? Color.nafasPrimary : Color.gray).cornerRadius(12)
                }
                .disabled(authVM.localPhoneNumber.count < 9 || authVM.isPhoneAuthLoading)
                
                Spacer()
            }
            .padding(.horizontal, 24).background(Color.nafasBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.nafasTextPrimary)
                }
            }
            .navigationDestination(isPresented: $showOTP) {
                VStack(spacing: 24) {
                    Text("Enter Verification Code").font(.title2.bold()).padding(.top, 32)
                    
                    TextField("123456", text: $authVM.otpCode)
                        .keyboardType(.numberPad).padding().background(Color.nafasSurface).cornerRadius(12)
                    
                    // 🚀 The Error Block for OTP failures!
                    if let err = authVM.phoneAuthError {
                        Text(err).font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.nafasDanger).multilineTextAlignment(.center)
                    }
                    
                    Button("Verify & Link") {
                                            Task {
                                                do {
                                                    // 1. Link the credential in Firebase Auth
                                                    try await AuthenticationManager.shared.linkPhone(
                                                        verificationID: authVM.verificationID ?? "",
                                                        verificationCode: authVM.otpCode
                                                    )
                                                    
                                                    // 2. 🚀 NEW: Tell Firestore about the new phone number!
                                                    if let uid = Auth.auth().currentUser?.uid,
                                                       let linkedPhone = Auth.auth().currentUser?.phoneNumber {
                                                        
                                                        let db = Firestore.firestore(database: "nafas")
                                                        try await db.collection("parents").document(uid).setData([
                                                            "phone": linkedPhone
                                                        ], merge: true)
                                                    }
                                                    
                                                    // 3. Refresh the Edit Profile UI and close the sheet
                                                    await profileVM.loadUserProfile()
                                                    dismiss()
                                                } catch {
                                                    authVM.phoneAuthError = error.localizedDescription
                                                }
                                            }
                                        }
                    .fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity)
                    .padding().background(Color.nafasPrimary).cornerRadius(12)
                    Spacer()
                }
                .padding(.horizontal, 24).background(Color.nafasBackground.ignoresSafeArea())
            }
        }
    }
}
