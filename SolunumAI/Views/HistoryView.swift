import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject private var coreData: CoreDataService

    @State private var analyses: [SavedAnalysis] = []
    @State private var filter: HistoryFilter = .all
    @State private var searchDate: Date = Date()
    @State private var showDateSearch = false
    @State private var showDeleteAll = false
    @State private var expandedID: UUID?
    @State private var showExport = false
    @State private var exportText = ""

    enum HistoryFilter: String, CaseIterable {
        case all       = "Tümü"
        case highRisk  = "Yüksek Risk"
        case lowRisk   = "Düşük Risk"
    }

    private var filtered: [SavedAnalysis] {
        var items = analyses
        switch filter {
        case .highRisk: items = items.filter { $0.pFinal >= 0.50 }
        case .lowRisk:  items = items.filter { $0.pFinal  < 0.40 }
        case .all:      break
        }
        if showDateSearch {
            let day = Calendar.current.startOfDay(for: searchDate)
            items = items.filter { Calendar.current.startOfDay(for: $0.date) == day }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !analyses.isEmpty {
                    TrendChartView(analyses: analyses)
                        .frame(height: 160)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                }

                filterBar

                if filtered.isEmpty {
                    EmptyHistoryView(hasData: !analyses.isEmpty)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { item in
                            HistoryRowView(item: item, isExpanded: expandedID == item.id)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedID = expandedID == item.id ? nil : item.id
                                    }
                                }
                                .listRowBackground(Color(.systemBackground))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .background(Color("AppBackground"))
                }
            }
            .background(Color("AppBackground"))
            .navigationTitle("Geçmiş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showDateSearch.toggle() } label: {
                        Image(systemName: showDateSearch ? "calendar.badge.minus" : "calendar.badge.plus")
                    }
                    Menu {
                        Button("CSV Olarak Dışa Aktar", systemImage: "square.and.arrow.up") {
                            exportText = coreData.exportCSV()
                            showExport = true
                        }
                        Button("Tümünü Sil", systemImage: "trash", role: .destructive) {
                            showDeleteAll = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ActivityViewRepresentable(text: exportText)
            }
            .confirmationDialog("Tüm analizler silinecek. Bu işlem geri alınamaz.", isPresented: $showDeleteAll, titleVisibility: .visible) {
                Button("Tümünü Sil", role: .destructive) {
                    coreData.deleteAll()
                    loadAnalyses()
                }
            }
            .onAppear { loadAnalyses() }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HistoryFilter.allCases, id: \.self) { f in
                        Button {
                            withAnimation { filter = f }
                        } label: {
                            Text(f.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(filter == f ? Color("AppPrimary") : Color(.systemGray5))
                                .foregroundColor(filter == f ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }

            if showDateSearch {
                DatePicker("Tarih Seç", selection: $searchDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "tr_TR"))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color("AppBackground"))
    }

    // MARK: - Helpers

    private func loadAnalyses() {
        analyses = coreData.fetchAll()
    }

    private func deleteItems(at offsets: IndexSet) {
        for i in offsets {
            coreData.delete(id: filtered[i].id)
        }
        loadAnalyses()
    }
}

// MARK: - Trend Chart

private struct TrendChartView: View {
    let analyses: [SavedAnalysis]

    private var chartData: [SavedAnalysis] {
        Array(analyses.prefix(30).reversed())
    }

    private var trend: String {
        guard chartData.count >= 2 else { return "—" }
        let first = chartData.first!.pFinal
        let last  = chartData.last!.pFinal
        if last < first - 0.02 { return "↓ İyileşiyor" }
        if last > first + 0.02 { return "↑ Kötüleşiyor" }
        return "→ Stabil"
    }

    private var trendColor: Color {
        if trend.contains("İyileşiyor")  { return Color("AppSuccess") }
        if trend.contains("Kötüleşiyor") { return Color("AppDanger") }
        return Color("AppWarning")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Son 30 Analiz Trendi")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(trend)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(trendColor)
            }

            Chart(chartData) { item in
                LineMark(
                    x: .value("Tarih", item.date),
                    y: .value("Skor", item.pFinal * 100)
                )
                .foregroundStyle(Color("AppPrimary"))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Tarih", item.date),
                    y: .value("Skor", item.pFinal * 100)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.3), Color("AppPrimary").opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: [0, 40, 50, 100]) { val in
                    AxisGridLine()
                    AxisValueLabel {
                        Text("\(val.as(Int.self) ?? 0)%").font(.caption2)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6)
    }
}

// MARK: - History Row

private struct HistoryRowView: View {
    let item: SavedAnalysis
    let isExpanded: Bool

    private var riskColor: Color {
        switch item.riskLevel {
        case .low:      return Color("AppSuccess")
        case .moderate: return Color("AppWarning")
        case .high:     return Color("AppDanger")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary row
            HStack(spacing: 12) {
                // Color strip
                RoundedRectangle(cornerRadius: 3)
                    .fill(riskColor)
                    .frame(width: 5)
                    .frame(height: isExpanded ? nil : 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.formattedDate)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(item.formattedPFinal)
                            .font(.headline.weight(.bold))
                            .foregroundColor(riskColor)
                    }
                    HStack(spacing: 6) {
                        Text(item.riskLevel.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(riskColor)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(item.airsIsim)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            // Expanded detail
            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        DetailChip(label: "Yaş", value: "\(item.yas)")
                        DetailChip(label: "Cinsiyet", value: item.cinsiyet)
                        if item.sigara { DetailChip(label: "Sigara", value: "Evet") }
                    }

                    ScoreBarView(label: "Gribal (P1)", value: item.p1, color: Color("AppWarning"))
                    ScoreBarView(label: "Astım/KOAH (P2)", value: item.p2, color: Color("AppDanger"))

                    Text(item.oneri)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

private struct DetailChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    let hasData: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(.systemGray4))
            Text(hasData ? "Filtre ile eşleşen analiz bulunamadı." : "Henüz analiz yapılmadı.")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Analiz sekmesinden ilk taramanızı yapın.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Share Sheet

private struct ActivityViewRepresentable: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HistoryView()
        .environmentObject(CoreDataService.shared)
}
