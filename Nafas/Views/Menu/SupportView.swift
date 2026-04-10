//
//  SupportView.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.


import SwiftUI

struct SupportView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.nafasPrimary)
                    .padding(.top, 40)
                
                Text("support_title")
                    .font(.nafasHeading())
                    .foregroundStyle(Color.nafasTextPrimary)
                
                Text("support_subtitle")
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 16) {
                    supportCard(icon: "envelope.fill", title: "support_email", value: "asthmadetector@gmail.com") {
                        if let url = URL(string: "mailto:asthmadetector@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    supportCard(icon: "phone.fill", title: "support_phone", value: "+966 50 123 4567") {
                        if let url = URL(string: "tel://+966501234567") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .padding(.top, 16)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color.nafasSurface.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("menu_contact_support"))
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
    
    @ViewBuilder
    private func supportCard(icon: String, title: LocalizedStringKey, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.nafasPrimaryLight).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.nafasPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.nafasTextMuted)
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)
                        // These two lines prevent the text from wrapping to a second line
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .padding(16)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
