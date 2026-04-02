//
//  FAQView.swift
//  Nafas
//
//  Created by Rana Alngashy on 02/04/2026.


import SwiftUI
import Combine 

struct FAQItem: Identifiable {
    let id = UUID()
    let questionKey: LocalizedStringKey
    let answerKey: LocalizedStringKey
}

class FAQViewModel: ObservableObject {
    @Published var faqs: [FAQItem] = [
        FAQItem(questionKey: "faq_q1", answerKey: "faq_a1"),
        FAQItem(questionKey: "faq_q2", answerKey: "faq_a2"),
        FAQItem(questionKey: "faq_q3", answerKey: "faq_a3")
    ]
}

struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = FAQViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(vm.faqs) { item in
                        FAQRow(item: item)
                    }
                }
                .padding(20)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("menu_questions_help"))
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

struct FAQRow: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.questionKey)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.nafasTextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(Color.nafasPrimary)
                }
                .padding(16)
            }
            
            if isExpanded {
                Text(item.answerKey)
                    .font(.nafasBody())
                    .foregroundStyle(Color.nafasTextMuted)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}
