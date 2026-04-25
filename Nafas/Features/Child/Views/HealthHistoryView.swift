import SwiftUI
import PDFKit

// MARK: - Tab enum
enum HistoryTab: String, CaseIterable {
    case today     = "history_tab_today"
    case thisWeek  = "history_tab_week"
    case thisMonth = "history_tab_month"
    case last3     = "history_tab_3m"

    var localizedKey: LocalizedStringKey {
        LocalizedStringKey(self.rawValue)
    }
}

// MARK: - HealthHistoryView
struct HealthHistoryView: View {
    let child: ChildModel
    @ObservedObject private var store = NafasStore.shared
    @State private var selectedTab: HistoryTab = .thisWeek
    @State private var showPDFPreview = false
    @State private var pdfURL: URL?
    @Environment(\.dismiss) var dismiss

    private var allEntries: [HistoryEntry] {
        store.history(for: child.id.uuidString).filter { $0.alertLevel == .danger }
    }

    private var filteredEntries: [HistoryEntry] {
        switch selectedTab {
        case .today:
            let fmt = DateFormatter()
            fmt.setLocalizedDateFormatFromTemplate("EEE, d MMM yyyy")
            let todayString = fmt.string(from: Date())
            return allEntries.filter { $0.date == todayString }
        case .thisWeek:  return allEntries
        case .thisMonth: return allEntries
        case .last3:     return allEntries
        }
    }

    private var totalReadings: Int { allEntries.count }
    private var alertCount: Int    { allEntries.count }
    private var avgSpO2: Double {
        let vals = allEntries.compactMap { $0.spO2 }
        guard !vals.isEmpty else { return 0 }
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HistoryTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.localizedKey)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(selectedTab == tab ? .white : Color.nafasTextMuted)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(
                                        selectedTab == tab ? Color.nafasPrimary : Color.nafasBackground,
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }

                // Summary cards
                HStack(spacing: 12) {
                    summaryCard(value: "\(totalReadings)", label: "history_attacks_label", color: Color.nafasDanger)
                    summaryCard(value: alertCount == 0 ? "0" : "\(alertCount) ⚠️", label: "history_total_alerts_label", color: alertCount > 0 ? Color.nafasDanger : Color.nafasSuccess)
                    summaryCard(value: avgSpO2 > 0 ? String(format: "%.1f%%", avgSpO2) : "—", label: "history_avg_spo2_label", color: Color.nafasPrimary)
                }
                .padding(.horizontal, 20).padding(.bottom, 10)

                Divider()

                if filteredEntries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 48)).foregroundStyle(Color.nafasSuccess)
                        Text(LocalizedStringKey("history_empty_title"))
                            .font(.nafasBody()).foregroundStyle(Color.nafasTextMuted)
                        Text(LocalizedStringKey("history_empty_subtitle"))
                            .font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(filteredEntries) { entry in
                                historyRow(entry)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 100)
                    }
                }
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("history_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            .overlay(alignment: .bottom) { downloadButton }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let url = pdfURL {
                PDFPreviewView(url: url)
            }
        }
    }

    // MARK: - Summary card
    @ViewBuilder
    private func summaryCard(value: String, label: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(color)
            Text(label).font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - History row
    @ViewBuilder
    private func historyRow(_ entry: HistoryEntry) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(Color.nafasDanger).frame(width: 4)
                .clipShape(RoundedCornerRect(corners: [.topLeft, .bottomLeft], radius: 12))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(Color.nafasDanger)
                    Text(entry.date)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                    Spacer()
                    Text(entry.time).font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
                }

                Divider()

                HStack(spacing: 0) {
                    vitalIcon("heart.fill",  color: .red,               labelKey: "history_row_bp",   value: entry.bp)
                    vitalIcon("drop.fill",   color: Color.nafasPrimary,  labelKey: "history_row_spo2", value: entry.spO2.map { "\($0)%" }, isAlert: true)
                    vitalIcon("wind",        color: .gray,               labelKey: "history_row_iaq",  value: entry.iaq.map { "\($0)" })
                    vitalIcon("lungs.fill",  color: .red.opacity(0.7),   labelKey: "history_row_peak", value: entry.peakFlow.map { "\($0)" })
                }
            }
            .padding(14)
        }
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDanger.opacity(0.3), lineWidth: 1))
    }

    @ViewBuilder
    private func vitalIcon(_ icon: String, color: Color, labelKey: LocalizedStringKey, value: String?, isAlert: Bool = false) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
            Text(labelKey).font(.system(size: 11)).foregroundStyle(Color.nafasTextMuted)
            if let value {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isAlert ? Color.nafasDanger : Color.nafasTextPrimary)
            } else {
                Text("—").font(.system(size: 13)).foregroundStyle(Color.nafasTextMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - PDF Download Button
    private var downloadButton: some View {
        Button {
            generatePDF()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.to.line")
                Text(LocalizedStringKey("history_download_pdf")).font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
    }

    // ... Keep all PDF Generation functions below exactly the same ...
    private func generatePDF() {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
        let documentDirectory = FileManager.default.temporaryDirectory
        let pdfURL = documentDirectory.appendingPathComponent("\(child.name)_Attack_History.pdf")
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor.systemBlue]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        let mutedAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray]
        let totalLine = String(format: NSLocalizedString("pdf_total_attacks", comment: ""), totalReadings)
        let avgLine = String(format: NSLocalizedString("pdf_avg_spo2", comment: ""), avgSpO2 > 0 ? String(format: "%.1f%%", avgSpO2) : "—")

        do {
            try pdfRenderer.writePDF(to: pdfURL) { context in
                context.beginPage()
                let titleString = "\(child.name) - \(NSLocalizedString("history_nav_title", comment: ""))"
                titleString.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttrs)
                let dateString = String(format: NSLocalizedString("pdf_generated_on", comment: ""), dateFmt.string(from: Date()))
                dateString.draw(at: CGPoint(x: 50, y: 85), withAttributes: mutedAttrs)
                var y: CGFloat = 120
                NSLocalizedString("pdf_title_summary", comment: "").draw(at: CGPoint(x: 50, y: y), withAttributes: subtitleAttrs)
                y += 25
                totalLine.draw(at: CGPoint(x: 50, y: y), withAttributes: bodyAttrs)
                y += 20
                avgLine.draw(at: CGPoint(x: 50, y: y), withAttributes: bodyAttrs)
                y += 40

                if !filteredEntries.isEmpty {
                    NSLocalizedString("pdf_title_history", comment: "").draw(at: CGPoint(x: 50, y: y), withAttributes: subtitleAttrs)
                    y += 25
                    for entry in filteredEntries {
                        let dateTimeLine = "📅 " + String(format: NSLocalizedString("%@ at %@", comment: ""), entry.date, entry.time)
                        let spO2Line  = "   • " + String(format: NSLocalizedString("pdf_entry_spo2", comment: ""), entry.spO2.map { "\($0)%" } ?? "—")
                        let bpLine    = "   • " + String(format: NSLocalizedString("pdf_entry_bp", comment: ""), entry.bp ?? "—")
                        let iaqLine   = "   • " + String(format: NSLocalizedString("pdf_entry_iaq", comment: ""), entry.iaq.map { "\($0)" } ?? "—")
                        let peakLine  = "   • " + String(format: NSLocalizedString("pdf_entry_peak_flow", comment: ""), entry.peakFlow.map { "\($0)" } ?? "—")
                        let block = [dateTimeLine, spO2Line, bpLine, iaqLine, peakLine].joined(separator: "\n")
                        block.draw(at: CGPoint(x: 50, y: y), withAttributes: bodyAttrs)
                        y += 80
                        if y > 750 {
                            context.beginPage()
                            y = 50
                        }
                    }
                } else {
                    NSLocalizedString("pdf_no_data", comment: "").draw(at: CGPoint(x: 50, y: y), withAttributes: bodyAttrs)
                }
            }
            self.pdfURL = pdfURL
            showPDFPreview = true
        } catch {
            print("Failed to generate PDF: \(error)")
        }
    }
}

// MARK: - PDF Preview View
struct PDFPreviewView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .navigationTitle(LocalizedStringKey("pdf_preview_nav_title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("pdf_preview_close", comment: "")) { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: url) {
                            Label(NSLocalizedString("pdf_preview_share", comment: ""), systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

// MARK: - PDFKit View
struct PDFKitView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

// Helper shape for one-sided rounded corners
struct RoundedCornerRect: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
