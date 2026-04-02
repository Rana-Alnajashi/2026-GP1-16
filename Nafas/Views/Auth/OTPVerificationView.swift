//
//  OTPVerificationView.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.


import SwiftUI
import Combine

struct OTPVerificationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Binding var showSignInView: Bool

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var resendSeconds = 60
    @State private var isVerifying = false
    @State private var shakeOffset: CGFloat = 0
    @State private var errorMessage: String? = nil

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Fill viewModel.otpCode from digits array
    private var otp: String { digits.joined() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                envelopeHeader
                    .padding(.top, 32)

                VStack(spacing: 28) {
                    digitBoxes
                    confirmButton
                    resendRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer(minLength: 20)
                customNumpad
                    .padding(.bottom, 24)
            }
        }
        .background(Color.nafasSurface.ignoresSafeArea())
        .navigationTitle(LocalizedStringKey("otp_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onReceive(timer) { _ in
            if resendSeconds > 0 { resendSeconds -= 1 }
        }
        .onDisappear { timer.upstream.connect().cancel() }
    }

    // MARK: - Envelope header
    private var envelopeHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.nafasPrimaryLight)
                    .frame(width: 80, height: 80)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.nafasPrimary)
            }
            Text("otp_heading")
                .font(.nafasHeading())
                .foregroundStyle(Color.nafasTextPrimary)
            VStack(spacing: 2) {
                Text("otp_subheading")
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
                Text(viewModel.fullPhoneNumber)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.nafasTextPrimary)
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Digit boxes
    private var digitBoxes: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nafasBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    digits[i].isEmpty
                                        ? Color.nafasDivider
                                        : Color.nafasPrimary,
                                    lineWidth: digits[i].isEmpty ? 1 : 2
                                )
                        )
                        .frame(height: 56)
                    Text(digits[i])
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)
                }
                .offset(x: shakeOffset)
            }
        }
        .animation(.default, value: digits)
    }

    // MARK: - Confirm button
    private var confirmButton: some View {
        VStack(spacing: 10) {
            NafasPrimaryButton(
                titleKey: "otp_confirm_button",
                isLoading: isVerifying,
                isEnabled: otp.count == 6
            ) {
                verify()
            }
            if let err = errorMessage ?? viewModel.phoneAuthError {
                Text(err)
                    .font(.nafasCaption())
                    .foregroundStyle(Color.nafasDanger)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Resend row
    private var resendRow: some View {
        HStack(spacing: 4) {
            Text("otp_resend_prefix")
                .foregroundStyle(Color.nafasTextMuted)
            if resendSeconds > 0 {
                Text(String(format: NSLocalizedString("otp_resend_timer", comment: ""), resendSeconds))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.nafasTextPrimary)
            } else {
                Button {
                    resendOTP()
                } label: {
                    Text("otp_resend_action")
                        .foregroundStyle(Color.nafasPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Custom numpad
    private var customNumpad: some View {
        VStack(spacing: 12) {
            ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { digit in
                        numpadKey(label: "\(digit)") { appendDigit("\(digit)") }
                    }
                }
            }
            HStack(spacing: 12) {
                // empty placeholder
                Color.clear.frame(width: numpadKeyWidth, height: numpadKeyHeight)
                numpadKey(label: "0") { appendDigit("0") }
                // Backspace
                Button { deleteDigit() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nafasBackground)
                            .frame(width: numpadKeyWidth, height: numpadKeyHeight)
                        Image(systemName: "delete.left")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
        }
    }

    private let numpadKeyWidth: CGFloat  = (UIScreen.main.bounds.width - 80) / 3
    private let numpadKeyHeight: CGFloat = 60

    @ViewBuilder
    private func numpadKey(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.nafasBackground)
                    .frame(width: numpadKeyWidth, height: numpadKeyHeight)
                Text(label)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.nafasTextPrimary)
            }
        }
    }

    // MARK: - Actions
    private func appendDigit(_ d: String) {
        guard let idx = digits.firstIndex(of: "") else { return }
        digits[idx] = d
        if otp.count == 6 { verify() }
    }

    private func deleteDigit() {
        for i in stride(from: 5, through: 0, by: -1) {
            if !digits[i].isEmpty {
                digits[i] = ""
                return
            }
        }
    }

    private func verify() {
        viewModel.otpCode = otp
        isVerifying = true
        errorMessage = nil
        Task {
            do {
                try await viewModel.verifyOTPAndSignIn()
                showSignInView = false
            } catch {
                errorMessage = error.localizedDescription
                shakeBoxes()
            }
            isVerifying = false
        }
    }

    private func shakeBoxes() {
        withAnimation(.interpolatingSpring(stiffness: 400, damping: 6)) {
            shakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 6)) {
                shakeOffset = 0
            }
        }
    }

    private func resendOTP() {
        digits = Array(repeating: "", count: 6)
        errorMessage = nil
        resendSeconds = 60
        Task { await viewModel.sendPhoneVerification() }
    }
}

#Preview {
    let vm = AuthenticationViewModel()
    vm.fullPhoneNumber  // trigger build
    return NavigationStack {
        OTPVerificationView(viewModel: vm, showSignInView: .constant(true))
    }
}
