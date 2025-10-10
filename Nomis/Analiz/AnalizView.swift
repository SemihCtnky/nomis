import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AnalizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query private var sarnelForms: [SarnelForm]
    @Query private var kilitForms: [KilitToplamaForm]
    @Query private var gunlukForms: [GunlukForm]
    @Query private var yeniGunlukForms: [YeniGunlukForm]
    
    @State private var selectedTab = 0
    @State private var selectedAyar = 0 // 0 = all
    @State private var selectedTimeFrame = 0 // 0 = haftalık, 1 = aylık, 2 = yıllık
    @State private var selectedModel = "Tümü"
    @State private var selectedFirma = "Tümü"
    @State private var selectedCards: Set<String> = Set(["Tezgah", "Cila", "Ocak", "Patlatma", "Tambur", "Makine Kesme", "Testere Kesme"])
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingExport = false
    @State private var showingCardSelection = false
    @State private var exportURL: URL?
    
    private let tabs = ["Kilit Toplama", "Şarnel", "Günlük İşlerim"]
    private let timeFrames = ["Haftalık", "Aylık", "Yıllık"]
    private let availableCards = ["Tezgah", "Cila", "Ocak", "Patlatma", "Tambur", "Makine Kesme", "Testere Kesme"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                tabSelector
                
                filtersSection
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            kilitAnalysisSection
                        case 1:
                            sarnelAnalysisSection
                        case 2:
                            gunlukAnalysisSection
                        default:
                            EmptyView()
                        }
                        
                        exportSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Analiz")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCardSelection) {
            CardSelectionSheet(selectedCards: $selectedCards, availableCards: availableCards)
        }
        .fileExporter(
            isPresented: $showingExport,
            document: exportURL.map { DocumentWrapper(url: $0) },
            contentType: .pdf,
            defaultFilename: "Nomis_Analiz_\(turkishDateFormatter.string(from: Date()))"
        ) { result in
            handleExportResult(result)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(NomisTheme.accent)
            
            Text("Veri Analizi")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(NomisTheme.primary)
        }
        .padding()
        .background(NomisTheme.cardBackground)
    }
    
    private var tabSelector: some View {
        Picker("Analiz Türü", selection: $selectedTab) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Text(tabs[index]).tag(index)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(NomisTheme.background)
    }
    
    private var filtersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Gelişmiş Filtreler")
                    .font(.headline)
                    .foregroundColor(NomisTheme.primary)
                Spacer()
                
                Button("Sıfırla") {
                    resetFilters()
                }
                .font(.caption)
                .foregroundColor(NomisTheme.primaryGreen)
            }
            
            // Zaman aralığı seçimi
            VStack(alignment: .leading, spacing: 8) {
                Text("Zaman Aralığı")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
                
                Picker("Zaman Aralığı", selection: $selectedTimeFrame) {
                    ForEach(0..<timeFrames.count, id: \.self) { index in
                        Text(timeFrames[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedTimeFrame) { _, _ in
                    updateDateRangeForTimeFrame()
                }
            }
            
            // Tarih seçimi
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Başlangıç")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bitiş")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity)
            }
            
            // Ayar seçimi
            VStack(alignment: .leading, spacing: 8) {
                Text("Ayar Seçimi")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
                
                Picker("Ayar", selection: $selectedAyar) {
                    Text("Tümü").tag(0)
                    Text("14k").tag(14)
                    Text("18k").tag(18)
                    Text("21k").tag(21)
                    Text("22k").tag(22)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Tab-specific filters
            if selectedTab == 0 {
                kilitSpecificFilters
            } else if selectedTab == 2 {
                gunlukSpecificFilters
            }
        }
        .padding()
        .background(NomisTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: NomisTheme.primaryGreen.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var kilitSpecificFilters: some View {
        VStack(spacing: 12) {
            // Model seçimi
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Seçimi")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
                
                Picker("Model", selection: $selectedModel) {
                    Text("Tümü").tag("Tümü")
                    ForEach(getUniqueModels(), id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Firma seçimi
            VStack(alignment: .leading, spacing: 8) {
                Text("Firma Seçimi")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
                
                Picker("Firma", selection: $selectedFirma) {
                    Text("Tümü").tag("Tümü")
                    ForEach(getUniqueFirmas(), id: \.self) { firma in
                        Text(firma).tag(firma)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    private var gunlukSpecificFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analiz Edilecek Kartlar")
                .font(.caption)
                .foregroundColor(NomisTheme.secondaryText)
            
            // Kart seçimi butonu
            Button(action: {
                showingCardSelection = true
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kart Seçimi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.primary)
                        
                        Text("\(selectedCards.count) kart seçili")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(NomisTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NomisTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Seçili kartlar preview
            if !selectedCards.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedCards.sorted(), id: \.self) { card in
                            Text(card)
                                .font(.caption)
                                .foregroundColor(NomisTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(NomisTheme.primaryGreen.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
    
    // Kart renkleri için computed properties
    private let cardColors: [String: Color] = [
        "Tezgah": NomisTheme.primaryGreen,
        "Cila": NomisTheme.primaryGreen,
        "Ocak": NomisTheme.primaryGreen,
        "Patlatma": NomisTheme.primaryGreen,
        "Tambur": NomisTheme.primaryGreen,
        "Makine Kesme": NomisTheme.primaryGreen,
        "Testere Kesme": NomisTheme.primaryGreen
    ]
    
    private var kilitAnalysisSection: some View {
        let filteredForms = getAdvancedFilteredKilitForms()
        
        return VStack(spacing: 16) {
            AnalysisCard(
                title: "Kilit Toplama Analizi",
                subtitle: "\(filteredForms.count) kayıt bulundu"
            ) {
                VStack(spacing: 12) {
                    AnalysisRow(
                        label: "Toplam İşlem",
                        value: "\(filteredForms.count)"
                    )
                    
                    AnalysisRow(
                        label: "Toplam Fire",
                        value: "\(NomisFormatters.safeFormat(getTotalKilitFire(filteredForms))) gr",
                        isHighlighted: true
                    )
                    
                    AnalysisRow(
                        label: "Ortalama Fire",
                        value: "\(NomisFormatters.safeFormat(getAverageKilitFire(filteredForms))) gr"
                    )
                    
                    AnalysisRow(
                        label: "Verimlilik",
                        value: "\(String(format: "%.1f", getKilitEfficiency(filteredForms)))%"
                    )
                }
            }
            
            // Ayar bazında analiz
            if selectedAyar == 0 {
                ayarBasedKilitAnalysis(filteredForms)
            }
            
            // Model/Firma analizi
            if selectedModel == "Tümü" || selectedFirma == "Tümü" {
                modelFirmaKilitAnalysis(filteredForms)
            }
        }
    }
    
    private var sarnelAnalysisSection: some View {
        let filteredForms = getAdvancedFilteredSarnelForms()
        
        return VStack(spacing: 16) {
            AnalysisCard(
                title: "Şarnel Analizi",
                subtitle: "\(filteredForms.count) kayıt bulundu"
            ) {
                VStack(spacing: 12) {
                    AnalysisRow(
                        label: "Toplam İşlem",
                        value: "\(filteredForms.count)"
                    )
                    
                    AnalysisRow(
                        label: "Toplam Fire",
                        value: "\(NomisFormatters.safeFormat(getTotalSarnelFire(filteredForms))) gr",
                        isHighlighted: true
                    )
                    
                    AnalysisRow(
                        label: "Ortalama Altın Oranı",
                        value: String(format: "%.4f", getAverageSarnelRatio(filteredForms))
                    )
                }
            }
            
            // Ayar bazında analiz
            if selectedAyar == 0 {
                ayarBasedSarnelAnalysis(filteredForms)
            }
        }
    }
    
    private var gunlukAnalysisSection: some View {
        let filteredForms = getAdvancedFilteredGunlukForms()
        
        return VStack(spacing: 16) {
            AnalysisCard(
                title: "Günlük İşlemler Analizi",
                subtitle: "\(filteredForms.count) haftalık form bulundu"
            ) {
                VStack(spacing: 12) {
                    AnalysisRow(
                        label: "Toplam Hafta",
                        value: "\(filteredForms.count)"
                    )
                    
                    AnalysisRow(
                        label: "Toplam Fire",
                        value: "\(NomisFormatters.safeFormat(getTotalGunlukFire(filteredForms))) gr",
                        isHighlighted: true
                    )
                    
                    AnalysisRow(
                        label: "Haftalık Ortalama Fire",
                        value: "\(NomisFormatters.safeFormat(getAverageWeeklyFire(filteredForms))) gr"
                    )
                }
            }
            
            // Kart bazında analiz
            cardBasedGunlukAnalysis(filteredForms)
            
            // Ayar bazında günlük analiz
            if selectedAyar == 0 {
                ayarBasedGunlukAnalysis(filteredForms)
            }
        }
    }
    
    private var exportSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rapor Dışa Aktarma")
                    .font(.headline)
                    .foregroundColor(NomisTheme.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: exportToPDF) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("PDF Rapor")
                    }
                }
                .buttonStyle(NomisButtonStyle(style: .primary))
                .frame(maxWidth: .infinity)
                
                Button(action: exportToCSV) {
                    HStack {
                        Image(systemName: "tablecells")
                        Text("CSV Veri")
                    }
                }
                .buttonStyle(NomisButtonStyle(style: .secondary))
                .frame(maxWidth: .infinity)
            }
        }
        .nomisCard()
    }
    
    // MARK: - Filter Methods
    
    private func getFilteredKilitForms() -> [KilitToplamaForm] {
        return kilitForms.filter { form in
            let isInDateRange = (form.startedAt ?? form.createdAt) >= startDate && (form.startedAt ?? form.createdAt) <= endDate
            let isCorrectAyar = selectedAyar == 0 || form.ayar == selectedAyar
            return isInDateRange && isCorrectAyar
        }
    }
    
    private func getFilteredSarnelForms() -> [SarnelForm] {
        return sarnelForms.filter { form in
            let isInDateRange = form.createdAt >= startDate && form.createdAt <= endDate
            let isCorrectAyar = selectedAyar == 0 || form.karatAyar == selectedAyar
            return isInDateRange && isCorrectAyar
        }
    }
    
    private func getFilteredGunlukForms() -> [GunlukForm] {
        return gunlukForms.filter { form in
            let isInDateRange = form.createdAt >= startDate && form.createdAt <= endDate
            return isInDateRange
        }
    }
    
    // MARK: - Calculation Methods
    
    private func getAverageKilitDuration(_ forms: [KilitToplamaForm]) -> TimeInterval {
        let completedForms = forms.filter { $0.endedAt != nil && $0.startedAt != nil }
        guard !completedForms.isEmpty else { return 0 }
        
        let totalDuration = completedForms.reduce(0.0) { total, form in
            guard let startedAt = form.startedAt, let endedAt = form.endedAt else {
                return total
            }
            return total + endedAt.timeIntervalSince(startedAt)
        }
        
        return totalDuration / Double(completedForms.count)
    }
    
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
    
    private func exportToPDF() {
        Task {
            do {
                let pdfData = await generatePDFReport()
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("analiz_\(turkishDateFormatter.string(from: Date())).pdf")
                
                try pdfData.write(to: tempURL)
                
                await MainActor.run {
                    self.exportURL = tempURL
                    self.showingExport = true
                }
            } catch {
                // Silent fail
            }
        }
    }
    
    private func exportToCSV() {
        Task {
            do {
                let csvContent = generateCSV()
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("analiz_\(dateFormatter.string(from: Date())).csv")
                
                try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    self.exportURL = tempURL
                    self.showingExport = true
                }
            } catch {
                // Silent fail
            }
        }
    }
    
    @MainActor
    private func generatePDFReport() async -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Nomis App",
            kCGPDFContextAuthor: "Nomis Analytics",
            kCGPDFContextTitle: "Analiz Raporu"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // PDF content generation
            let title = "Nomis Analiz Raporu"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleRect = CGRect(x: 50, y: 50, width: 500, height: 40)
            title.draw(in: titleRect, withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ])
            
            // Add more content based on selected tab and data
            var yPosition: CGFloat = 120
            
            switch selectedTab {
            case 0:
                let forms = getAdvancedFilteredKilitForms()
                yPosition = drawKilitSection(in: context, forms: forms, startY: yPosition)
            case 1:
                let forms = getAdvancedFilteredSarnelForms()
                yPosition = drawSarnelSection(in: context, forms: forms, startY: yPosition)
            case 2:
                let forms = getAdvancedFilteredGunlukForms()
                yPosition = drawGunlukSection(in: context, forms: forms, startY: yPosition)
            default:
                break
            }
        }
    }
    
    private func drawKilitSection(in context: UIGraphicsPDFRendererContext, forms: [KilitToplamaForm], startY: CGFloat) -> CGFloat {
        var y = startY
        let font = UIFont.systemFont(ofSize: 14)
        
        "Kilit Toplama Analizi".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ])
        y += 30
        
        "Toplam İşlem: \(forms.count)".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.black
        ])
        y += 25
        
        "Toplam Fire: \(NomisFormatters.safeFormat(getTotalKilitFire(forms))) gr".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.red
        ])
        y += 25
        
        return y
    }
    
    private func drawSarnelSection(in context: UIGraphicsPDFRendererContext, forms: [SarnelForm], startY: CGFloat) -> CGFloat {
        var y = startY
        let font = UIFont.systemFont(ofSize: 14)
        
        "Şarnel Analizi".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ])
        y += 30
        
        "Toplam İşlem: \(forms.count)".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.black
        ])
        y += 25
        
        "Toplam Fire: \(NomisFormatters.safeFormat(getTotalSarnelFire(forms))) gr".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.red
        ])
        y += 25
        
        return y
    }
    
    private func drawGunlukSection(in context: UIGraphicsPDFRendererContext, forms: [YeniGunlukForm], startY: CGFloat) -> CGFloat {
        var y = startY
        let font = UIFont.systemFont(ofSize: 14)
        
        "Günlük İşlemler Analizi".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ])
        y += 30
        
        "Toplam Hafta: \(forms.count)".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.black
        ])
        y += 25
        
        "Toplam Fire: \(NomisFormatters.safeFormat(getTotalGunlukFire(forms))) gr".draw(in: CGRect(x: 50, y: y, width: 500, height: 20), withAttributes: [
            .font: font,
            .foregroundColor: UIColor.red
        ])
        y += 25
        
        return y
    }
    
    private func generateCSV() -> String {
        var csv = ""
        
        switch selectedTab {
        case 0: // Kilit
            csv = generateKilitCSV()
        case 1: // Sarnel
            csv = generateSarnelCSV()
        case 2: // Gunluk
            csv = generateGunlukCSV()
        default:
            break
        }
        
        return csv
    }
    
    private func generateKilitCSV() -> String {
        let forms = getFilteredKilitForms()
        var csv = "Model,Firma,Ayar,Başlama,Bitiş,Toplam Giriş Gram,Toplam Çıkış Gram,Fire Gram,Durum\n"
        
        for form in forms {
            let row = [
                form.model ?? "",
                form.firma ?? "",
                "\(form.ayar ?? 0)",
                dateFormatter.string(from: form.startedAt ?? form.createdAt),
                form.endedAt != nil ? dateFormatter.string(from: form.endedAt!) : "",
                "\(form.toplamGirisGram)",
                "\(form.toplamCikisGram)",
                "\(form.fireGram)",
                form.endedAt != nil ? "Tamamlandı" : "Devam Ediyor"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func generateSarnelCSV() -> String {
        let forms = getFilteredSarnelForms()
        var csv = "Oluşturma,Ayar,Giriş Altın,Çıkış Altın,Altın Oranı,Toplam Asit,Fire,Durum\n"
        
        for form in forms {
            let asitTotal = form.asitCikislari.reduce(0) { $0 + $1.valueGr }
            let fire = (form.girisAltin ?? 0) - asitTotal
            
            let row = [
                dateFormatter.string(from: form.createdAt),
                "\(form.karatAyar)",
                "\(form.girisAltin ?? 0)",
                "\(form.cikisAltin ?? 0)",
                "\(form.altinOrani ?? 0)",
                "\(asitTotal)",
                "\(fire)",
                form.state.displayName
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func generateGunlukCSV() -> String {
        let forms = getFilteredGunlukForms()
        var csv = "Oluşturma,Durum\n"
        
        for form in forms {
            let row = [
                dateFormatter.string(from: form.createdAt),
                form.state.displayName
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        // Clean up temporary file
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let turkishDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Helper Methods
    
    private func resetFilters() {
        selectedAyar = 0
        selectedTimeFrame = 0
        selectedModel = "Tümü"
        selectedFirma = "Tümü"
        selectedCards = Set(availableCards)
        updateDateRangeForTimeFrame()
    }
    
    private func updateDateRangeForTimeFrame() {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFrame {
        case 0: // Haftalık
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            endDate = now
        case 1: // Aylık
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            endDate = now
        case 2: // Yıllık
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            endDate = now
        default:
            break
        }
    }
    
    private func getUniqueModels() -> [String] {
        let models = Set(kilitForms.compactMap { $0.model })
        return Array(models).filter { !$0.isEmpty }
    }
    
    private func getUniqueFirmas() -> [String] {
        let firmas = Set(kilitForms.compactMap { $0.firma })
        return Array(firmas).filter { !$0.isEmpty }
    }
    
    // MARK: - Advanced Filter Methods
    
    private func getAdvancedFilteredKilitForms() -> [KilitToplamaForm] {
        return kilitForms.filter { form in
            let isInDateRange = (form.startedAt ?? form.createdAt) >= startDate && (form.startedAt ?? form.createdAt) <= endDate
            let isCorrectAyar = selectedAyar == 0 || form.ayar == selectedAyar
            let isCorrectModel = selectedModel == "Tümü" || form.model == selectedModel
            let isCorrectFirma = selectedFirma == "Tümü" || form.firma == selectedFirma
            return isInDateRange && isCorrectAyar && isCorrectModel && isCorrectFirma
        }
    }
    
    private func getAdvancedFilteredSarnelForms() -> [SarnelForm] {
        return sarnelForms.filter { form in
            let isInDateRange = form.createdAt >= startDate && form.createdAt <= endDate
            let isCorrectAyar = selectedAyar == 0 || form.karatAyar == selectedAyar
            return isInDateRange && isCorrectAyar
        }
    }
    
    private func getAdvancedFilteredGunlukForms() -> [YeniGunlukForm] {
        return yeniGunlukForms.filter { form in
            let isInDateRange = form.baslamaTarihi >= startDate && form.baslamaTarihi <= endDate
            return isInDateRange
        }
    }
    
    private func ayarBasedKilitAnalysis(_ forms: [KilitToplamaForm]) -> some View {
        VStack(spacing: 12) {
            ForEach([14, 18, 21, 22], id: \.self) { ayar in
                let ayarForms = forms.filter { $0.ayar == ayar }
                if !ayarForms.isEmpty {
                    AnalysisCard(
                        title: "\(ayar)k Ayar Analizi",
                        subtitle: "\(ayarForms.count) kayıt"
                    ) {
                        VStack(spacing: 8) {
                            AnalysisRow(
                                label: "Fire",
                                value: "\(NomisFormatters.safeFormat(getTotalKilitFire(ayarForms))) gr",
                                isHighlighted: true
                            )
                            
                            AnalysisRow(
                                label: "Ortalama Giriş",
                                value: "\(NomisFormatters.safeFormat(getAverageKilitInput(ayarForms))) gr"
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func modelFirmaKilitAnalysis(_ forms: [KilitToplamaForm]) -> some View {
        VStack(spacing: 12) {
            // Model bazında
            if selectedModel == "Tümü" {
                let modelStats = getModelStatistics(forms)
                ForEach(modelStats.keys.sorted(), id: \.self) { model in
                    if let stats = modelStats[model] {
                        AnalysisCard(
                            title: "Model: \(model)",
                            subtitle: "\(stats.count) kayıt"
                        ) {
                            AnalysisRow(
                                label: "Fire",
                                value: "\(NomisFormatters.safeFormat(stats.totalFire)) gr",
                                isHighlighted: true
                            )
                        }
                    }
                }
            }
            
            // Firma bazında
            if selectedFirma == "Tümü" {
                let firmaStats = getFirmaStatistics(forms)
                ForEach(firmaStats.keys.sorted(), id: \.self) { firma in
                    if let stats = firmaStats[firma] {
                        AnalysisCard(
                            title: "Firma: \(firma)",
                            subtitle: "\(stats.count) kayıt"
                        ) {
                            AnalysisRow(
                                label: "Fire",
                                value: "\(NomisFormatters.safeFormat(stats.totalFire)) gr",
                                isHighlighted: true
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func getModelStatistics(_ forms: [KilitToplamaForm]) -> [String: (count: Int, totalFire: Double)] {
        var stats: [String: (count: Int, totalFire: Double)] = [:]
        
        for form in forms {
            let model = form.model ?? "Bilinmeyen"
            let currentStats = stats[model] ?? (count: 0, totalFire: 0.0)
            stats[model] = (count: currentStats.count + 1, totalFire: currentStats.totalFire + form.fireGram)
        }
        
        return stats
    }
    
    private func getFirmaStatistics(_ forms: [KilitToplamaForm]) -> [String: (count: Int, totalFire: Double)] {
        var stats: [String: (count: Int, totalFire: Double)] = [:]
        
        for form in forms {
            let firma = form.firma ?? "Bilinmeyen"
            let currentStats = stats[firma] ?? (count: 0, totalFire: 0.0)
            stats[firma] = (count: currentStats.count + 1, totalFire: currentStats.totalFire + form.fireGram)
        }
        
        return stats
    }
    
    private func getAverageKilitInput(_ forms: [KilitToplamaForm]) -> Double {
        guard !forms.isEmpty else { return 0 }
        return forms.reduce(0) { $0 + $1.toplamGirisGram } / Double(forms.count)
    }
    
    // MARK: - Sarnel Analysis Methods
    
    private func getTotalSarnelFire(_ forms: [SarnelForm]) -> Double {
        return forms.reduce(0) { total, form in
            return total + (form.fire ?? 0.0)
        }
    }
    
    private func getAverageSarnelRatio(_ forms: [SarnelForm]) -> Double {
        guard !forms.isEmpty else { return 0 }
        return forms.compactMap { $0.altinOrani }.reduce(0, +) / Double(forms.count)
    }
    
    private func ayarBasedSarnelAnalysis(_ forms: [SarnelForm]) -> some View {
        VStack(spacing: 12) {
            ForEach([14, 18, 21, 22], id: \.self) { ayar in
                let ayarForms = forms.filter { $0.karatAyar == ayar }
                if !ayarForms.isEmpty {
                    AnalysisCard(
                        title: "\(ayar)k Ayar Şarnel",
                        subtitle: "\(ayarForms.count) kayıt"
                    ) {
                        VStack(spacing: 8) {
                            AnalysisRow(
                                label: "Fire",
                                value: "\(NomisFormatters.safeFormat(getTotalSarnelFire(ayarForms))) gr",
                                isHighlighted: true
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Kilit Analysis Methods
    
    private func getTotalKilitFire(_ forms: [KilitToplamaForm]) -> Double {
        return forms.reduce(0) { $0 + $1.fireGram }
    }
    
    private func getAverageKilitFire(_ forms: [KilitToplamaForm]) -> Double {
        guard !forms.isEmpty else { return 0 }
        return getTotalKilitFire(forms) / Double(forms.count)
    }
    
    private func getKilitEfficiency(_ forms: [KilitToplamaForm]) -> Double {
        guard !forms.isEmpty else { return 0 }
        let totalInput = forms.reduce(0) { $0 + $1.toplamGirisGram }
        let totalOutput = forms.reduce(0) { $0 + $1.toplamCikisGram }
        guard totalInput > 0 else { return 0 }
        return (totalOutput / totalInput) * 100
    }
    
    // MARK: - Gunluk Analysis Methods
    
    private func getTotalGunlukFire(_ forms: [YeniGunlukForm]) -> Double {
        var totalFire: Double = 0
        
        for form in forms {
            for gunVerisi in form.gunlukVeriler {
                // Tezgah kartları
                if selectedCards.contains("Tezgah"), let tezgah1 = gunVerisi.tezgahKarti1 {
                    totalFire += calculateTezgahFire(tezgah1)
                }
                if selectedCards.contains("Tezgah"), let tezgah2 = gunVerisi.tezgahKarti2 {
                    totalFire += calculateTezgahFire(tezgah2)
                }
                
                // Diğer kartlar
                if selectedCards.contains("Cila"), let cila = gunVerisi.cilaKarti {
                    totalFire += calculateIslemFire(cila.satirlar)
                }
                if selectedCards.contains("Ocak"), let ocak = gunVerisi.ocakKarti {
                    totalFire += calculateIslemFire(ocak.satirlar)
                }
                if selectedCards.contains("Patlatma"), let patlatma = gunVerisi.patlatmaKarti {
                    totalFire += calculateIslemFire(patlatma.satirlar)
                }
                if selectedCards.contains("Tambur"), let tambur = gunVerisi.tamburKarti {
                    totalFire += calculateIslemFire(tambur.satirlar)
                }
                if selectedCards.contains("Makine Kesme"), let makine = gunVerisi.makineKesmeKarti1 {
                    totalFire += calculateIslemFire(makine.satirlar)
                }
                if selectedCards.contains("Testere Kesme"), let testere = gunVerisi.testereKesmeKarti1 {
                    totalFire += calculateIslemFire(testere.satirlar)
                }
            }
        }
        
        return totalFire
    }
    
    private func getAverageWeeklyFire(_ forms: [YeniGunlukForm]) -> Double {
        guard !forms.isEmpty else { return 0 }
        return getTotalGunlukFire(forms) / Double(forms.count)
    }
    
    private func getGunlukFireForAyar(_ forms: [YeniGunlukForm], ayar: Int) -> Double {
        var totalFire: Double = 0
        
        for form in forms {
            for gunVerisi in form.gunlukVeriler {
                // Tezgah kartları - ayar kontrolü ile
                if let tezgah1 = gunVerisi.tezgahKarti1, tezgah1.ayar == ayar {
                    totalFire += calculateTezgahFire(tezgah1)
                }
                if let tezgah2 = gunVerisi.tezgahKarti2, tezgah2.ayar == ayar {
                    totalFire += calculateTezgahFire(tezgah2)
                }
                
                // Diğer kartlar - ayar kontrolü ile
                if let cila = gunVerisi.cilaKarti {
                    totalFire += calculateIslemFireForAyar(cila.satirlar, ayar: ayar)
                }
                if let ocak = gunVerisi.ocakKarti {
                    totalFire += calculateIslemFireForAyar(ocak.satirlar, ayar: ayar)
                }
                if let patlatma = gunVerisi.patlatmaKarti {
                    totalFire += calculateIslemFireForAyar(patlatma.satirlar, ayar: ayar)
                }
                if let tambur = gunVerisi.tamburKarti {
                    totalFire += calculateIslemFireForAyar(tambur.satirlar, ayar: ayar)
                }
                if let makine = gunVerisi.makineKesmeKarti1 {
                    totalFire += calculateIslemFireForAyar(makine.satirlar, ayar: ayar)
                }
                if let testere = gunVerisi.testereKesmeKarti1 {
                    totalFire += calculateIslemFireForAyar(testere.satirlar, ayar: ayar)
                }
            }
        }
        
        return totalFire
    }
    
    private func getGunlukFireForCard(_ forms: [YeniGunlukForm], cardName: String) -> Double {
        var totalFire: Double = 0
        
        for form in forms {
            for gunVerisi in form.gunlukVeriler {
                switch cardName {
                case "Tezgah":
                    if let tezgah1 = gunVerisi.tezgahKarti1 {
                        totalFire += calculateTezgahFire(tezgah1)
                    }
                    if let tezgah2 = gunVerisi.tezgahKarti2 {
                        totalFire += calculateTezgahFire(tezgah2)
                    }
                case "Cila":
                    if let cila = gunVerisi.cilaKarti {
                        totalFire += calculateIslemFire(cila.satirlar)
                    }
                case "Ocak":
                    if let ocak = gunVerisi.ocakKarti {
                        totalFire += calculateIslemFire(ocak.satirlar)
                    }
                case "Patlatma":
                    if let patlatma = gunVerisi.patlatmaKarti {
                        totalFire += calculateIslemFire(patlatma.satirlar)
                    }
                case "Tambur":
                    if let tambur = gunVerisi.tamburKarti {
                        totalFire += calculateIslemFire(tambur.satirlar)
                    }
                case "Makine Kesme":
                    if let makine = gunVerisi.makineKesmeKarti1 {
                        totalFire += calculateIslemFire(makine.satirlar)
                    }
                case "Testere Kesme":
                    if let testere = gunVerisi.testereKesmeKarti1 {
                        totalFire += calculateIslemFire(testere.satirlar)
                    }
                default:
                    break
                }
            }
        }
        
        return totalFire
    }
    
    private func calculateTezgahFire(_ karti: TezgahKarti) -> Double {
        return karti.satirlar.reduce(0.0) { total, satir in
            let giris = satir.girisValue ?? 0.0
            let cikis = satir.cikisValue ?? 0.0
            return total + max(0, giris - cikis)
        }
    }
    
    private func calculateIslemFire(_ satirlar: [IslemSatiri]) -> Double {
        return satirlar.reduce(0.0) { $0 + $1.fire }
    }
    
    private func calculateIslemFireForAyar(_ satirlar: [IslemSatiri], ayar: Int) -> Double {
        return satirlar.filter { $0.ayar == ayar }.reduce(0.0) { $0 + $1.fire }
    }
    
    // MARK: - Analysis Helper Views
    
    private func cardBasedGunlukAnalysis(_ forms: [YeniGunlukForm]) -> some View {
        VStack(spacing: 12) {
            ForEach(selectedCards.sorted(), id: \.self) { cardName in
                let fireData = getGunlukFireForCard(forms, cardName: cardName)
                if fireData > 0 {
                    AnalysisCard(
                        title: "\(cardName) Kartı",
                        subtitle: "Fire analizi"
                    ) {
                        AnalysisRow(
                            label: "Toplam Fire",
                            value: "\(NomisFormatters.safeFormat(fireData)) gr",
                            isHighlighted: true
                        )
                    }
                }
            }
        }
    }
    
    private func ayarBasedGunlukAnalysis(_ forms: [YeniGunlukForm]) -> some View {
        VStack(spacing: 12) {
            ForEach([14, 18, 21, 22], id: \.self) { ayar in
                let fireData = getGunlukFireForAyar(forms, ayar: ayar)
                if fireData > 0 {
                    AnalysisCard(
                        title: "\(ayar)k Ayar Fire",
                        subtitle: "Günlük işlemler"
                    ) {
                        AnalysisRow(
                            label: "Toplam Fire",
                            value: "\(NomisFormatters.safeFormat(fireData)) gr",
                            isHighlighted: true
                        )
                    }
                }
            }
        }
    }
}

struct AnalysisCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(NomisTheme.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondary)
                }
                
                Spacer()
            }
            
            content
        }
        .nomisCard()
    }
}

struct AnalysisRow: View {
    let label: String
    let value: String
    let isHighlighted: Bool
    
    init(label: String, value: String, isHighlighted: Bool = false) {
        self.label = label
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(NomisTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(isHighlighted ? .red : NomisTheme.primary)
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadCorruptFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

struct DocumentWrapper: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadCorruptFile)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

struct CardSelectionSheet: View {
    @Binding var selectedCards: Set<String>
    let availableCards: [String]
    @Environment(\.dismiss) private var dismiss
    
    private let cardColors: [String: Color] = [
        "Tezgah": NomisTheme.primaryGreen,
        "Cila": NomisTheme.primaryGreen,
        "Ocak": NomisTheme.primaryGreen,
        "Patlatma": NomisTheme.primaryGreen,
        "Tambur": NomisTheme.primaryGreen,
        "Makine Kesme": NomisTheme.primaryGreen,
        "Testere Kesme": NomisTheme.primaryGreen
    ]
    
    var body: some View {
        ZStack {
            // ✅ TAM EKRAN BACKGROUND - Beyazlığı tamamen kaldırır
            NomisTheme.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button("İptal") {
                            dismiss()
                        }
                        .font(.body)
                        .foregroundColor(NomisTheme.secondaryText)
                        
                        Spacer()
                        
                        Text("Kart Seçimi")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(NomisTheme.primary)
                        
                        Spacer()
                        
                        Button("Tamam") {
                            dismiss()
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedCards.isEmpty ? NomisTheme.secondaryText : NomisTheme.primaryGreen)
                        .disabled(selectedCards.isEmpty)
                    }
                    
                    // Selection Info
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fire Analizi İçin Kartları Seçin")
                                .font(.subheadline)
                                .foregroundColor(NomisTheme.primary)
                            
                            Text("\(selectedCards.count) kart seçili")
                                .font(.caption)
                                .foregroundColor(NomisTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        if !selectedCards.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCards.removeAll()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Temizle")
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.clear)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(NomisTheme.border.opacity(0.3)),
                    alignment: .bottom
                )
                
                // Cards List - Ana içerik
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(availableCards, id: \.self) { card in
                            CardSelectionItem(
                                cardName: card,
                                color: cardColors[card] ?? NomisTheme.primaryGreen,
                                isSelected: selectedCards.contains(card)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    toggleCard(card)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 160)
                }
            }
        }
        .overlay(
            // Floating Action Area
            VStack(spacing: 0) {
                Spacer()
                
                // Seçili kartlar için ayrı bölüm
                if !selectedCards.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Seçili Kartlar")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(NomisTheme.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedCards.sorted(), id: \.self) { card in
                                    Text(card)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(NomisTheme.primaryGreen)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(NomisTheme.border.opacity(0.3)),
                        alignment: .top
                    )
                }
                
                // Confirm Button
                VStack(spacing: 0) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(selectedCards.isEmpty ? "En Az Bir Kart Seçin" : "Seçimi Onayla (\(selectedCards.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedCards.isEmpty ? NomisTheme.secondaryText : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCards.isEmpty ? NomisTheme.border.opacity(0.3) : NomisTheme.primaryGreen)
                        )
                    }
                    .disabled(selectedCards.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.clear)
            }
        )
    }
    
    private func toggleCard(_ card: String) {
        if selectedCards.contains(card) {
            selectedCards.remove(card)
        } else {
            selectedCards.insert(card)
        }
    }
}

struct CardSelectionItem: View {
    let cardName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? color : NomisTheme.border.opacity(0.4))
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Card Name
                Text(cardName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? color : NomisTheme.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : NomisTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : NomisTheme.border.opacity(0.6), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    AnalizView()
        .environmentObject(AuthenticationManager())
}
