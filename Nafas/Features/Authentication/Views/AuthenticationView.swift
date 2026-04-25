import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    @State private var showOTP = false
    @State private var step: AuthStep = .initialChoice
    
    enum AuthStep {
        case initialChoice
        case nameInput
        case methodSelection
        case phoneInput
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.nafasBackground.ignoresSafeArea()
                LinearGradient(colors: [Color.nafasPrimary.opacity(0.18), Color.nafasBackground], startPoint: .top, endPoint: .bottom)
                    .frame(height: 280).ignoresSafeArea(edges: .top)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        formCard
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView(viewModel: viewModel, showSignInView: $showSignInView)
            }
        }
    }
    
    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 56)
            NafasLogoMark(size: 72)
            Text("app_name").font(.system(size: 34, weight: .black)).foregroundStyle(Color.nafasTextPrimary)
            Text("app_tagline").font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
            Spacer().frame(height: 28)
        }
    }
    
    // MARK: - Main Card
    private var formCard: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(step == .initialChoice ? "Welcome" : (viewModel.isRegistration ? "Create Account" : "Log In"))
                    .font(.nafasHeading()).foregroundStyle(Color.nafasTextPrimary)
                Text(step == .nameInput ? "Let's start with your name" : "Manage your child's health")
                    .font(.nafasBody()).foregroundStyle(Color.nafasTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Group {
                switch step {
                case .initialChoice:   initialChoiceStep
                case .nameInput:       nameInputStep
                case .methodSelection: methodSelectionStep
                case .phoneInput:      phoneInputStep
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24).padding(.vertical, 32)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.nafasSurface)
        .clipShape(TopRounded(radius: 28)).shadow(color: .black.opacity(0.06), radius: 20, y: -4)
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // MARK: - Steps
    private var initialChoiceStep: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.isRegistration = true
                step = .nameInput
            } label: {
                Text("I am a New User").fontWeight(.bold).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52).background(Color.nafasPrimary).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            Button {
                viewModel.isRegistration = false
                step = .methodSelection
            } label: {
                Text("I already have an account").fontWeight(.bold).foregroundStyle(Color.nafasPrimary).frame(maxWidth: .infinity).frame(height: 52).background(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.nafasPrimary, lineWidth: 1.5))
            }
        }
    }
    
    private var nameInputStep: some View {
        VStack(spacing: 24) {
            backButton { step = .initialChoice }
            
            NafasTextField(labelKey: "Full Name", placeholderKey: "e.g. Ahmad Al-Harbi", icon: "person", text: $viewModel.fullName)
            
            NafasPrimaryButton(titleKey: "Continue", isLoading: false, isEnabled: !viewModel.fullName.trimmingCharacters(in: .whitespaces).isEmpty) {
                step = .methodSelection
            }
        }
    }
    
    private var methodSelectionStep: some View {
        VStack(spacing: 16) {
            backButton { step = viewModel.isRegistration ? .nameInput : .initialChoice }
            
            Button { step = .phoneInput } label: {
                HStack(spacing: 10) { Image(systemName: "phone.fill"); Text("Continue with Phone").fontWeight(.bold) }
                .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52).background(Color.nafasPrimary).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            LabeledDivider(key: "auth_or_continue")
            
            Button {
                Task {
                    do {
                        let success = try await viewModel.signInGoogle()
                        if success { showSignInView = false }
                    } catch {
                        viewModel.phoneAuthError = error.localizedDescription
                    }
                }
            } label: {
                HStack(spacing: 10) { Image(systemName: "globe"); Text("Continue with Google").fontWeight(.bold) }
                .foregroundStyle(Color.nafasTextPrimary).frame(maxWidth: .infinity).frame(height: 52).background(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.nafasDivider, lineWidth: 1.5))
            }
            
            if let err = viewModel.phoneAuthError {
                Text(err).font(.nafasCaption()).foregroundStyle(Color.nafasDanger).multilineTextAlignment(.center)
            }
        }
    }
    
    private var phoneInputStep: some View {
        VStack(spacing: 24) {
            backButton { step = .methodSelection }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("auth_phone_label").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Text("🇸🇦").padding(.leading, 12)
                        Text(viewModel.countryCode).fontWeight(.medium).foregroundStyle(Color.nafasTextPrimary)
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.nafasTextMuted).padding(.trailing, 12)
                    }
                    .frame(height: 50).background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
                    
                    TextField("50 123 4567", text: $viewModel.localPhoneNumber)
                        .keyboardType(.phonePad).frame(height: 50).padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
                }
            }
            
            if let err = viewModel.phoneAuthError {
                Text(err).font(.nafasCaption()).foregroundStyle(Color.nafasDanger).frame(maxWidth: .infinity, alignment: .leading)
            }
            
            NafasPrimaryButton(titleKey: "auth_verify_button", isLoading: viewModel.isPhoneAuthLoading, isEnabled: viewModel.isPhoneInputValid) {
                Task {
                    await viewModel.sendPhoneVerification()
                    if viewModel.verificationID != nil { showOTP = true }
                }
            }
        }
    }
    
    private func backButton(action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) { HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Back") }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.nafasTextMuted) }
            Spacer()
        }.padding(.bottom, -8)
    }
}
