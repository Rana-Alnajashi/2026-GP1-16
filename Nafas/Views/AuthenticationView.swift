//
//  AuthenticationView.swift
//  Nafas
//
//  Created by Rana Alngashy on 31/03/2026.
//
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Combine


@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Phone Auth State
    @Published var phoneNumber: String = ""
    @Published var verificationID: String? = nil
    @Published var otpCode: String = ""
    @Published var isPhoneAuthLoading: Bool = false
    @Published var phoneAuthError: String? = nil
    
    // MARK: - Google Sign In (unchanged)
    
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
    }
    
    // MARK: - Phone Sign In
    
    /// Step 1 – send the OTP SMS
    func sendPhoneVerification() async {
        isPhoneAuthLoading = true
        phoneAuthError = nil
        do {
            verificationID = try await AuthenticationManager.shared.sendPhoneVerification(phoneNumber: phoneNumber)
        } catch {
            phoneAuthError = error.localizedDescription
        }
        isPhoneAuthLoading = false
    }
    
    /// Step 2 – verify the code the user typed
    func verifyOTPAndSignIn() async throws {
        guard let verificationID = verificationID else {
            throw URLError(.badServerResponse)
        }
        try await AuthenticationManager.shared.signInWithPhone(
            verificationID: verificationID,
            verificationCode: otpCode
        )
    }
}

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        showSignInView = false
                    } catch {
                        print(error)
                    }
                }
            }
            
            // MARK: - Phone Number Sign In
            
            Divider()
                .padding(.vertical, 8)
            
            if viewModel.verificationID == nil {
                // Step 1: Enter phone number
                VStack(spacing: 12) {
                    TextField("+966XXXXXXXXX", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    if let error = viewModel.phoneAuthError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button {
                        Task { await viewModel.sendPhoneVerification() }
                    } label: {
                        if viewModel.isPhoneAuthLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Send Verification Code")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(viewModel.phoneNumber.isEmpty || viewModel.isPhoneAuthLoading)
                }
            } else {
                // Step 2: Enter OTP
                VStack(spacing: 12) {
                    Text("Enter the 6-digit code sent to \(viewModel.phoneNumber)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    TextField("123456", text: $viewModel.otpCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    if let error = viewModel.phoneAuthError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.verifyOTPAndSignIn()
                                showSignInView = false
                            } catch {
                                viewModel.phoneAuthError = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Verify & Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(viewModel.otpCode.count < 6)
                    
                    // Allow going back to re-enter phone number
                    Button("Change phone number") {
                        viewModel.verificationID = nil
                        viewModel.otpCode = ""
                        viewModel.phoneAuthError = nil
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign in")
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(false))
    }
}
