import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Replace this placeholder text with your actual Terms of Service
                    Text("Welcome to Nafas. By using our app, you agree to the following terms and conditions...")
                        .font(.nafasBody())
                        .foregroundStyle(Color.nafasTextPrimary)
                        .lineSpacing(6)
                    
                    Spacer()
                }
                .padding(24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("auth_terms_tos"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.nafasDivider)
                                .frame(width: 30, height: 30)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.nafasTextMuted)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TermsOfServiceView()
}
