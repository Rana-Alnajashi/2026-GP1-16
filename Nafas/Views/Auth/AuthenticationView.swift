//
//  AuthenticationView.swift
//  Nafas
//
//  Redesigned UI – logic in AuthenticationManager.swift is unchanged.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Combine

// MARK: - ViewModel (logic unchanged, UI additions only)

@MainActor
final class AuthenticationViewModel: ObservableObject {

    // MARK: Phone auth
    @Published var fullName: String = ""          // NEW – captured on sign-up
    @Published var countryCode: String = "+966"   // default: Saudi Arabia
    @Published var localPhoneNumber: String = ""  // digits after the country code
    @Published var verificationID: String? = nil
    @Published var otpCode: String = ""
    @Published var isPhoneAuthLoading: Bool = false
    @Published var phoneAuthError: String? = nil

    var fullPhoneNumber: String { "\(countryCode)\(localPhoneNumber)" }

    // MARK: Google sign-in (logic unchanged)
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let result = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)

        // Persist the display name that comes from the Google profile
        if let name = tokens.name, !name.isEmpty {
            UserProfileManager.shared.displayName = name
        }
        _ = result
    }

    // MARK: Phone – Step 1
    func sendPhoneVerification() async {
        isPhoneAuthLoading = true
        phoneAuthError = nil
        do {
            verificationID = try await AuthenticationManager.shared
                .sendPhoneVerification(phoneNumber: fullPhoneNumber)
        } catch {
            phoneAuthError = error.localizedDescription
            print("Phone auth error:", error)
        }
        isPhoneAuthLoading = false
    }

    // MARK: Phone – Step 2
    func verifyOTPAndSignIn() async throws {
        guard let id = verificationID else { throw URLError(.badServerResponse) }
        try await AuthenticationManager.shared.signInWithPhone(
            verificationID: id,
            verificationCode: otpCode
        )
        // Persist name entered during sign-up (phone path)
        if !fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            UserProfileManager.shared.displayName =
                fullName.trimmingCharacters(in: .whitespaces)
        }
    }

    var isPhoneInputValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        localPhoneNumber.count >= 9
    }
}

// MARK: - Authentication View (Login Screen)

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    // Navigation state
    @State private var showOTP        = false
    @State private var showNameSetup  = false
    @State private var showTOS = false
    @State private var showPrivacy = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // ── Background ──────────────────────────────────────────
                Color.nafasBackground.ignoresSafeArea()
                
                // ── Hero gradient header ─────────────────────────────────
                LinearGradient(
                    colors: [Color.nafasPrimary.opacity(0.18), Color.nafasBackground],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 280)
                .ignoresSafeArea(edges: .top)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        formCard
                    }
                }
            }
            .navigationBarHidden(true)
            // ── Navigation destinations ──────────────────────────────────
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView(
                    viewModel: viewModel,
                    showSignInView: $showSignInView
                )
            }
        }
    }
    
    // MARK: Hero
    private var heroSection: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 56)
            NafasLogoMark(size: 72)
            Text("app_name")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color.nafasTextPrimary)
            Text("app_tagline")
                .font(.nafasCaption())
                .foregroundStyle(Color.nafasTextMuted)
            Spacer().frame(height: 28)
        }
    }
    
    // MARK: Card
    private var formCard: some View {
        VStack(spacing: 24) {
            // Heading
            VStack(alignment: .leading, spacing: 4) {
                Text("auth_welcome_title")
                    .font(.nafasHeading())
                    .foregroundStyle(Color.nafasTextPrimary)
                Text("auth_welcome_subtitle")
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Full Name
            NafasTextField(
                labelKey: "auth_name_label",
                placeholderKey: "auth_name_placeholder",
                icon: "person",
                contentType: .name,
                text: $viewModel.fullName
            )
            
            // Phone Number
            phoneNumberField
            
            // Error
            if let err = viewModel.phoneAuthError {
                Text(err)
                    .font(.nafasCaption())
                    .foregroundStyle(Color.nafasDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Primary CTA
            NafasPrimaryButton(
                titleKey: "auth_verify_button",
                isLoading: viewModel.isPhoneAuthLoading,
                isEnabled: viewModel.isPhoneInputValid
            ) {
                Task {
                    await viewModel.sendPhoneVerification()
                    if viewModel.verificationID != nil {
                        showOTP = true
                    }
                }
            }
            
            // Google sign-in (secondary)
            LabeledDivider(key: "auth_or_continue")
            googleSignInButton
            
            // Terms
            termsText
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.nafasSurface)
        .clipShape(TopRounded(radius: 28))
        .shadow(color: .black.opacity(0.06), radius: 20, y: -4)
    }
    
    // MARK: Phone field
    private var phoneNumberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("auth_phone_label")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)
            HStack(spacing: 10) {
                // Country code button
                Button {
                    // TODO: country picker sheet
                } label: {
                    HStack(spacing: 6) {
                        Text("🇸🇦")
                        Text(viewModel.countryCode)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.nafasTextPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.nafasTextMuted)
                    }
                    .padding(.horizontal, 12)
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
                
                // Local number
                TextField(
                    LocalizedStringKey("auth_phone_placeholder"),
                    text: $viewModel.localPhoneNumber
                )
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(.nafasBody())
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
    
    // MARK: Google button
    private var googleSignInButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.signInGoogle()
                    showSignInView = false
                } catch {
                    viewModel.phoneAuthError = error.localizedDescription
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                Text("auth_google_button")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Color.nafasTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.nafasDivider, lineWidth: 1.5)
            )
        }
    }
    
    // MARK: Terms
    private var termsText: some View {
        ViewThatFits {
            // Layout for wider screens (fits on one line)
            HStack(spacing: 4) {
                Text("auth_terms_prefix").foregroundStyle(Color.nafasTextMuted)
                Button(action: { showTOS = true }) {
                    Text("auth_terms_tos").foregroundStyle(Color.nafasPrimary)
                }
                Text("auth_terms_and").foregroundStyle(Color.nafasTextMuted)
                Button(action: { showPrivacy = true }) {
                    Text("auth_terms_privacy").foregroundStyle(Color.nafasPrimary)
                }
            }
            
            // Layout for narrower screens (wraps to two lines)
            VStack(spacing: 4) {
                Text("auth_terms_prefix").foregroundStyle(Color.nafasTextMuted)
                HStack(spacing: 4) {
                    Button(action: { showTOS = true }) {
                        Text("auth_terms_tos").foregroundStyle(Color.nafasPrimary)
                    }
                    Text("auth_terms_and").foregroundStyle(Color.nafasTextMuted)
                    Button(action: { showPrivacy = true }) {
                        Text("auth_terms_privacy").foregroundStyle(Color.nafasPrimary)
                    }
                }
            }
        }
        .font(.system(size: 12, weight: .medium))
        .multilineTextAlignment(.center)
        .sheet(isPresented: $showTOS) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
    
}
#Preview {
    AuthenticationView(showSignInView: .constant(true))
}
