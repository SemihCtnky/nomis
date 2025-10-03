import SwiftUI
import SwiftData

struct SarnelEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State var form: SarnelForm?
    
    @State private var karatAyar: Int?
    @State private var girisAltin: Double?
    @State private var cikisAltin: Double?
    @State private var demirli_1: Double?
    @State private var demirli_2: Double?
    @State private var demirli_3: Double?
    @State private var demirliHurda: Double?
    @State private var demirliToz: Double?
    @State private var asitItems: [AsitItem] = []
    @State private var newAsitValue: Double?
    @State private var newAsitNote: String = ""
    
    @State private var extraFireItems: [FireItem] = []
    @State private var newFireValue: Double?
    @State private var newFireNote: String = ""
    
    @State private var hasChanges = false
    @State private var showingSummary = false
    @State private var autoSaveTimer: Timer?
    @State private var showingFinalSummary = false
    
    private var isNewForm: Bool { form == nil }
    private var canStartForm: Bool {
        karatAyar != nil
    }
    
    private var altinOrani: Double? {
        guard let giris = girisAltin,
              let cikis = cikisAltin,
              let d1 = demirli_1,
              let d2 = demirli_2,
              let d3 = demirli_3 else { return nil }
        
        let denominator = d1 + d2 + d3
        guard denominator > 0 else { return nil }
        
        return ((giris - cikis) / denominator) * 100
    }
    
    private var totalAsitCikisi: Double {
        let existingAsit = asitItems.reduce(0) { $0 + $1.valueGr }
        let newAsit = newAsitValue ?? 0
        return existingAsit + newAsit
    }
    
    private var fire: Double? {
        guard let giris = girisAltin, let cikis = cikisAltin else { return nil }
        // Bitirme tablosundaki giriş değeri (giris - cikis)
        let girisTablosu = giris - cikis
        // Bitirme tablosundaki çıkış değeri (asit çıkışı + toz × altın oranı / 100)
        let existingAsitCikisi = asitItems.reduce(0) { $0 + $1.valueGr }
        let newAsitCikisi = newAsitValue ?? 0
        let totalAsitCikisi = existingAsitCikisi + newAsitCikisi
        let tozCikisi = (demirli_3 ?? 0) * (altinOrani ?? 0) / 100
        let cikisTablosu = totalAsitCikisi + tozCikisi
        // Fire = Bitirme tablosundaki giriş - çıkış
        return girisTablosu - cikisTablosu
    }
    
    private var totalExtraFire: Double {
        let existingFire = extraFireItems.reduce(0) { $0 + $1.value }
        let newFire = newFireValue ?? 0
        return existingFire + newFire
    }
    
    private var finalFire: Double? {
        guard let initialFire = fire else { return nil }
        return initialFire - totalExtraFire
    }
    
    init(form: SarnelForm? = nil, isReadOnly: Bool = false) {
        self._form = State(initialValue: form)
        self.isReadOnly = isReadOnly
    }
    
    private let isReadOnly: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: NomisTheme.largeSpacing) {
                        // Header with start and end times
                        if let form = form {
                            VStack(spacing: NomisTheme.smallSpacing) {
                                Rectangle()
                                    .fill(NomisTheme.border)
                                    .frame(height: 2)
                                
                                HStack {
                                    if let startTime = form.startedAt {
                                        VStack(alignment: .leading) {
                                            Text("Başlangıç:")
                                                .font(.caption)
                                                .foregroundColor(NomisTheme.secondaryText)
                                            Text(Formatters.formatDateTime(startTime))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(NomisTheme.text)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let endTime = form.endedAt {
                                        VStack(alignment: .trailing) {
                                            Text("Bitiş:")
                                                .font(.caption)
                                                .foregroundColor(NomisTheme.secondaryText)
                                            Text(Formatters.formatDateTime(endTime))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(NomisTheme.text)
                                        }
                                    }
                                }
                                .padding(.horizontal, NomisTheme.contentSpacing)
                            }
                        }
                        
                        // Ayar Section  
                        ayarSection
                        
                        // Main Table (Giriş/Çıkış)
                        mainTableSection
                        
                        // Demirli Section
                        demirliSection
                        
                        // Altın Oranı (computed) - Demirli tablosu tamamlandıktan sonra görünür
                        if demirli_1 != nil && demirli_2 != nil && demirli_3 != nil {
                            if let oran = altinOrani {
                                altinOraniSection(oran)
                            } else {
                                // Demirli tablo dolu ama altın değerleri henüz girilmemiş
                                altinOraniPlaceholderSection()
                            }
                        }
                        
                        // Asit Çıkışı Table
                        asitCikisiSection
                        
                        // Summary Section
                        if showingSummary {
                            summarySection
                        }
                        
                        // Final Summary Section (after Bitir button)
                        if showingFinalSummary {
                            finalSummarySection
                        }
                        
                        // Action Buttons
                        if !isReadOnly {
                            actionButtonsSection
                        }
                    }
                    .padding(NomisTheme.contentSpacing)
                }
            }
            .navigationTitle(isNewForm ? "Yeni Şarnel" : "Şarnel Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        // FORCE CANCEL: Eğer yeni form ise kesinlikle sil, kaydetme
                        if isNewForm, let currentForm = form {
                            modelContext.delete(currentForm)
                            try? modelContext.save()
                        }
                        // Mevcut form ise sadece değişiklikleri kaydetme
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.canEdit && !isReadOnly {
                        Button("Kaydet") {
                            saveForm()
                        }
                        .disabled(!canStartForm)
                    }
                }
            }
            .onAppear {
                loadFormData()
                setupAutoSave()
            }
            .onDisappear {
                stopAutoSave()
            }
            .onChange(of: asitItems) { _, newItems in
                // Asit çıkışı değeri girildiğinde otomatik sonuç tablosu güncellemesi
                if !newItems.isEmpty && newItems.contains(where: { $0.valueGr > 0 }) {
                    showingFinalSummary = true
                    hasChanges = true
                }
            }
            .onChange(of: extraFireItems) { _, newItems in
                // Fire değeri girildiğinde otomatik güncelleme
                if !newItems.isEmpty {
                    hasChanges = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - UI Sections
    
    private var ayarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    Text("Ayar")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    if isReadOnly {
                        // Read-only mode: Show as text
                        Text(karatAyar == nil ? "Seçilmemiş" : "\(karatAyar!)")
                            .font(.system(size: NomisTheme.headlineSize, weight: .black))
                            .foregroundColor(karatAyar == nil ? NomisTheme.secondaryText : NomisTheme.blackNight)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(NomisTheme.cardBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(NomisTheme.border, lineWidth: NomisTheme.tableBorderWidth)
                            )
                    } else {
                        // Editable mode: Show as picker
                        Picker("Ayar", selection: Binding(
                            get: { karatAyar ?? 0 },
                            set: { karatAyar = $0 == 0 ? nil : $0 }
                        )) {
                            Text("Seçiniz").tag(0)
                            Text("14").tag(14)
                            Text("18").tag(18)
                            Text("21").tag(21)
                            Text("22").tag(22)
                        }
                        .font(.system(size: NomisTheme.headlineSize, weight: .bold))
                        .foregroundColor(NomisTheme.prominentText)
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(NomisTheme.lightCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: NomisTheme.tableBorderWidth)
                        )
                    }
                }
                .frame(height: NomisTheme.tableHeaderHeight)
                .onChange(of: karatAyar) { _, _ in hasChanges = true }
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private var mainTableSection: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                VStack {
                    Text("Altın")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Giriş")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Çıkış")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Data Row
            HStack(spacing: 0) {
                VStack { Spacer() }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell() // Excel formatı border
                
                VStack {
                    NumberTableCell(
                        value: $girisAltin,
                        placeholder: "0",
                        isEnabled: authManager.canEdit && !isReadOnly,
                        unit: "gr"
                    )
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell() // Excel formatı border
                .onChange(of: girisAltin) { _, _ in hasChanges = true }
                
                VStack {
                    NumberTableCell(
                        value: $cikisAltin,
                        placeholder: "0",
                        isEnabled: authManager.canEdit && !isReadOnly,
                        unit: "gr"
                    )
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell() // Excel formatı border
                .onChange(of: cikisAltin) { _, _ in hasChanges = true }
            }
            .frame(height: NomisTheme.tableCellHeight)
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private var demirliSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Sol taraftaki "Demirli" hücresi
                VStack {
                    Text("Demirli")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 180, height: NomisTheme.tableCellHeight * 3)
                .luxuryTableHeader()
                
                // Sağ taraftaki üç satırlık alan
                VStack(spacing: 0) {
                    // İlk hücre
                    HStack {
                        NumberTableCell(
                            value: $demirli_1,
                            placeholder: "0",
                            isEnabled: authManager.canEdit && !isReadOnly,
                            unit: "gr"
                        )
                    }
                    .frame(height: NomisTheme.tableCellHeight)
                    .luxuryTableCell() // Excel tarzı border
                    .onChange(of: demirli_1) { _, _ in hasChanges = true }
                    
                    // İkinci hücre
                    HStack {
                        NumberTableCell(
                            value: $demirli_2,
                            placeholder: "0",
                            isEnabled: authManager.canEdit && !isReadOnly,
                            unit: "gr (hurda)"
                        )
                    }
                    .frame(height: NomisTheme.tableCellHeight)
                    .luxuryTableCell() // Excel tarzı border
                    .onChange(of: demirli_2) { _, _ in hasChanges = true }
                    
                    // Üçüncü hücre
                    HStack {
                        NumberTableCell(
                            value: $demirli_3,
                            placeholder: "0",
                            isEnabled: authManager.canEdit && !isReadOnly,
                            unit: "gr (toz)"
                        )
                    }
                    .frame(height: NomisTheme.tableCellHeight)
                    .luxuryTableCell() // Excel tarzı border
                    .onChange(of: demirli_3) { _, _ in hasChanges = true }
                }
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private func altinOraniSection(_ oran: Double) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    Text("Altın Oranı")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    HStack {
                        if altinOrani != nil {
                            Text("%\(String(format: "%.2f", oran))")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(NomisTheme.goldAccent)
                        } else {
                            Text("Hesaplanıyor...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(NomisTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [NomisTheme.lightCream, NomisTheme.champagneGold.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.goldAccent.opacity(0.4), lineWidth: NomisTheme.tableBorderWidth)
                    )
                }
                .frame(height: NomisTheme.tableHeaderHeight)
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private func altinOraniPlaceholderSection() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    Text("Altın Oranı")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    HStack {
                        Text("Altın değerleri girince hesaplanacak...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(NomisTheme.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [NomisTheme.lightCream, NomisTheme.champagneGold.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.goldAccent.opacity(0.4), lineWidth: NomisTheme.tableBorderWidth)
                    )
                }
                .frame(height: NomisTheme.tableHeaderHeight)
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private var asitCikisiSection: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                VStack {
                    Text("Asit Çıkışı")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Değer")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Açıklama")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
            }
            .frame(height: NomisTheme.tableHeaderHeight)
            
            // Data Rows
            ForEach(asitItems.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    VStack {
                        if authManager.canEdit && !isReadOnly {
                            Button("Sil") {
                                removeAsitItem(at: index)
                            }
                            .font(.system(size: NomisTheme.captionSize, weight: NomisTheme.captionWeight))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NomisTheme.destructive)
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell() // Excel formatı border
                    
                    VStack {
                        NumberTableCell(
                            value: Binding(
                                get: { asitItems[index].valueGr },
                                set: { newValue in 
                                    asitItems[index].valueGr = newValue ?? 0
                                    hasChanges = true 
                                }
                            ),
                            placeholder: "0",
                            isEnabled: authManager.canEdit && !isReadOnly,
                            unit: "gr"
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell() // Excel formatı border
                    
                    VStack {
                        EditableTableCell(
                            value: Binding(
                                get: { asitItems[index].note ?? "" },
                                set: { newValue in 
                                    asitItems[index].note = newValue.isEmpty ? nil : newValue
                                    hasChanges = true 
                                }
                            ),
                            placeholder: "Açıklama",
                            isEnabled: authManager.canEdit && !isReadOnly
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell()
                }
                .frame(height: NomisTheme.tableCellHeight)
            }
            
            // Add new row
            if authManager.canEdit && !isReadOnly {
                HStack(spacing: 0) {
                    VStack { Spacer() }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell()
                    
                    VStack {
                        NumberTableCell(
                            value: $newAsitValue,
                            placeholder: "0",
                            unit: "gr"
                        )
                        .onChange(of: newAsitValue) { _, _ in
                            hasChanges = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell()
                    
                    VStack {
                        EditableTableCell(
                            value: $newAsitNote,
                            placeholder: "Açıklama"
                        )
                        .onChange(of: newAsitNote) { _, _ in
                            hasChanges = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .luxuryTableCell()
                }
                .frame(height: NomisTheme.tableCellHeight)
                
                // Add Button - Manuel satır ekleme
                HStack {
                    Spacer()
                    Button(action: addAsitItem) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Satır Ekle")
                                .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [NomisTheme.primaryGreen, NomisTheme.primaryGreen.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(NomisTheme.buttonCornerRadius)
                        .shadow(
                            color: NomisTheme.shadowColor,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                    .disabled(newAsitValue == nil || newAsitValue! <= 0)
                    .opacity((newAsitValue == nil || newAsitValue! <= 0) ? 0.6 : 1.0)
                    .padding(.top, NomisTheme.smallSpacing)
                    Spacer()
                }
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private var summarySection: some View {
        VStack(spacing: NomisTheme.contentSpacing) {
            Text("Özet")
                .sectionHeaderStyle()
            
            VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
                if let giris = girisAltin {
                    HStack {
                        Text("Altın:")
                        Spacer()
                        Text(Formatters.formatGrams(giris))
                            .font(.body.weight(NomisTheme.headlineWeight))
                    }
                }
                
                HStack {
                    Text("Asit Çıkışı:")
                    Spacer()
                    Text(Formatters.formatGrams(totalAsitCikisi))
                        .font(.body.weight(NomisTheme.headlineWeight))
                }
                
                if let fireValue = fire {
                    HStack {
                        Text("Fire:")
                        Spacer()
                        Text(Formatters.formatGrams(fireValue))
                            .font(.body.weight(NomisTheme.headlineWeight))
                            .foregroundColor(fireValue > 0 ? NomisTheme.destructive : NomisTheme.primary)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var finalSummarySection: some View {
        VStack(spacing: 0) {
            // Header with separate Giriş and Çıkış
            HStack(spacing: 0) {
                VStack {
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Giriş")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Text("Çıkış")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
            }
            .frame(height: NomisTheme.tableHeaderHeight)
            
            // Data Row with Altın in the first column
            HStack(spacing: 0) {
                VStack {
                    Text("Altın")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.darkText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell() // Excel tarzı çizgiler eklendi
                
                VStack {
                    if let giris = girisAltin, let cikis = cikisAltin {
                        let fark = giris - cikis
                        Text(String(format: "%.2f gr", fark))
                            .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.darkText)
                    } else {
                        Text("--")
                            .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .luxuryTableCell() // Excel tarzı çizgiler eklendi
                
                VStack {
                    let existingAsitCikisi = asitItems.reduce(0) { $0 + $1.valueGr }
                    let newAsitCikisi = newAsitValue ?? 0
                    let totalAsitCikisi = existingAsitCikisi + newAsitCikisi
                    let tozCikisi = (demirli_3 ?? 0) * (altinOrani ?? 0) / 100
                    let toplamCikis = totalAsitCikisi + tozCikisi
                    Text(String(format: "%.2f gr", toplamCikis))
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .luxuryTableCell() // Excel tarzı çizgiler eklendi
                
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Fire row with calculation
            fireCalculationSection
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private var fireCalculationSection: some View {
        VStack(spacing: 0) {
            // Fire header - centered across table
            HStack(spacing: 0) {
                VStack {
                    Text("Fire")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(NomisTheme.cardBackground)
                }
                .frame(maxWidth: .infinity)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.border, lineWidth: 3)
                )
                
                VStack {
                    if let initialFire = fire {
                        Text(String(format: "%.2f gr", initialFire))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(initialFire > 0 ? NomisTheme.destructive : NomisTheme.primary)
                    } else {
                        Text("--")
                            .font(.headline)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(NomisTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.border, lineWidth: 3)
                )
                
                VStack { Spacer() }
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
            }
            .frame(height: NomisTheme.tableHeaderHeight)
            
            // Extra Fire entries
            ForEach(extraFireItems.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    VStack { 
                        Text("Yeni Fire \(index + 1)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.text)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                    
                    VStack {
                        Text(String(format: "%.2f gr", extraFireItems[index].value))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.text)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                    
                    VStack {
                        EditableTableCell(
                            value: Binding(
                                get: { extraFireItems[index].note ?? "" },
                                set: { newValue in 
                                    extraFireItems[index].note = newValue.isEmpty ? nil : newValue
                                    hasChanges = true 
                                }
                            ),
                            placeholder: "Açıklama",
                            isEnabled: authManager.canEdit && !isReadOnly
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(0) // Padding kaldır
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                }
                .frame(height: NomisTheme.tableCellHeight)
                
                // Sil butonu satırı
                HStack(spacing: 0) {
                    VStack { Spacer() }
                        .frame(maxWidth: .infinity)
                        .background(NomisTheme.cardBackground)
                        .overlay(Rectangle().stroke(NomisTheme.border, lineWidth: 3))
                    
                    VStack { Spacer() }
                        .frame(maxWidth: .infinity)
                        .background(NomisTheme.cardBackground)
                        .overlay(Rectangle().stroke(NomisTheme.border, lineWidth: 3))
                    
                    VStack {
                        if authManager.canEdit && !isReadOnly {
                            Button("Sil") {
                                extraFireItems.remove(at: index)
                                hasChanges = true
                            }
                            .font(.system(size: NomisTheme.captionSize, weight: NomisTheme.captionWeight))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NomisTheme.destructive)
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(Rectangle().stroke(NomisTheme.border, lineWidth: 3))
                }
                .frame(height: NomisTheme.tableCellHeight)
            }
            
            // Add new fire input
            if authManager.canEdit && !isReadOnly {
                HStack(spacing: 0) {
                    VStack { 
                        Text("Yeni Fire")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.text)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                    
                    VStack {
                        NumberTableCell(
                            value: $newFireValue,
                            placeholder: "0",
                            isEnabled: true,
                            unit: "gr"
                        )
                        .onChange(of: newFireValue) { _, _ in
                            hasChanges = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                    
                    VStack {
                        EditableTableCell(
                            value: $newFireNote,
                            placeholder: "Açıklama"
                        )
                        .onChange(of: newFireNote) { _, _ in
                            hasChanges = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.border, lineWidth: 3)
                    )
                }
                .frame(height: NomisTheme.tableCellHeight)
                
                // Add Fire Button - Manuel satır ekleme
                HStack {
                    Spacer()
                    Button(action: addFireValue) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Satır Ekle")
                                .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [NomisTheme.primary, NomisTheme.primary.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(NomisTheme.buttonCornerRadius)
                        .shadow(
                            color: NomisTheme.shadowColor,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                    .disabled(newFireValue == nil || newFireValue! <= 0)
                    .opacity((newFireValue == nil || newFireValue! <= 0) ? 0.6 : 1.0)
                    .padding(.top, NomisTheme.smallSpacing)
                    Spacer()
                }
            }
            
            // Final Fire Result
            if !extraFireItems.isEmpty || fire != nil {
                HStack {
                    VStack {
                        HStack {
                            Text("Toplam Fire Miktarı: ")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(NomisTheme.text)
                            
                            if let finalFireValue = finalFire {
                                Text(String(format: "%.2f gr", finalFireValue))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(finalFireValue > 0 ? NomisTheme.destructive : NomisTheme.primary)
                            } else {
                                Text("--")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(NomisTheme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, NomisTheme.contentSpacing)
                        .padding(.vertical, NomisTheme.largeSpacing)
                        .background(NomisTheme.goldAccent.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(NomisTheme.border, lineWidth: 4)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: NomisTheme.contentSpacing) {
            // Bitir butonu
            if !showingFinalSummary && canStartForm && authManager.canEdit && !isReadOnly {
                Button("Bitir") {
                    finishForm()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            if authManager.canEdit && !isReadOnly {
                Button("Kaydet ve Çık") {
                    saveForm()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadFormData() {
        guard let form = form else { return }
        
        karatAyar = form.karatAyar
        girisAltin = form.girisAltin
        cikisAltin = form.cikisAltin
        demirli_1 = form.demirli_1
        demirli_2 = form.demirli_2
        demirli_3 = form.demirli_3
        demirliHurda = form.demirliHurda
        demirliToz = form.demirliToz
        asitItems = form.asitCikislari
        extraFireItems = form.extraFireItems
        
        // If the form has an end date, show the final summary
        if form.endedAt != nil {
            showingFinalSummary = true
        }
    }
    
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            autoSave()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func autoSave() {
        guard hasChanges, authManager.canEdit else { return }
        saveForm(silent: true)
    }
    
    private func addAsitItem() {
        // Yeni boş satır ekle
        let item = AsitItem(valueGr: newAsitValue ?? 0, note: newAsitNote.isEmpty ? nil : newAsitNote)
        asitItems.append(item)
        newAsitValue = nil
        newAsitNote = ""
        hasChanges = true
    }
    
    private func removeAsitItem(at index: Int) {
        asitItems.remove(at: index)
        hasChanges = true
    }
    
    private func addFireValue() {
        // Yeni fire değeri ekle (değer kontrolü yapmadan)
        let value = newFireValue ?? 0
        let fireItem = FireItem(value: value, note: newFireNote.isEmpty ? nil : newFireNote)
        extraFireItems.append(fireItem)
        newFireValue = nil
        newFireNote = ""
        hasChanges = true
    }
    
    private func autoSavePendingValues() {
        // Asit değeri varsa otomatik kaydet
        if let asitValue = newAsitValue, asitValue > 0 {
            let asitItem = AsitItem(valueGr: asitValue, note: newAsitNote.isEmpty ? nil : newAsitNote)
            asitItems.append(asitItem)
            newAsitValue = nil
            newAsitNote = ""
        }
        
        // Fire değeri varsa otomatik kaydet
        if let fireValue = newFireValue, fireValue > 0 {
            let fireItem = FireItem(value: fireValue, note: newFireNote.isEmpty ? nil : newFireNote)
            extraFireItems.append(fireItem)
            newFireValue = nil
            newFireNote = ""
        }
    }
    
    
    private func saveFormWithEndTime(endTime: Date? = nil, silent: Bool = false) {
        guard let ayar = karatAyar else { return }
        
        // Otomatik kaydetme: newAsitValue ve newFireValue'yi otomatik ekle
        autoSavePendingValues()
        
        if let existingForm = form {
            // Update existing form
            existingForm.karatAyar = ayar
            existingForm.girisAltin = girisAltin
            existingForm.cikisAltin = cikisAltin
            existingForm.demirli_1 = demirli_1
            existingForm.demirli_2 = demirli_2
            existingForm.demirli_3 = demirli_3
            existingForm.demirliHurda = demirliHurda
            existingForm.demirliToz = demirliToz
            existingForm.asitCikislari = asitItems
            existingForm.extraFireItems = extraFireItems
            existingForm.lastEditedAt = Date()
            
            if existingForm.startedAt == nil {
                existingForm.startedAt = Date()
            }
            
            // Set specific end time if provided
            if let endTime = endTime {
                existingForm.endedAt = endTime
            }
            // Otherwise set end time if final summary is showing and no end time exists
            else if showingFinalSummary && existingForm.endedAt == nil {
                existingForm.endedAt = Date()
            }
        } else {
            // Create new form
            let newForm = SarnelForm(karatAyar: ayar)
            newForm.girisAltin = girisAltin
            newForm.cikisAltin = cikisAltin
            newForm.demirli_1 = demirli_1
            newForm.demirli_2 = demirli_2
            newForm.demirli_3 = demirli_3
            newForm.demirliHurda = demirliHurda
            newForm.demirliToz = demirliToz
            newForm.asitCikislari = asitItems
            newForm.extraFireItems = extraFireItems
            newForm.startedAt = Date()
            
            // Set specific end time if provided
            if let endTime = endTime {
                newForm.endedAt = endTime
            }
            
            modelContext.insert(newForm)
            
            // Update the form reference to prevent creating duplicates
            form = newForm
        }
        
        // Save changes
        try? modelContext.save()
        
        // Stop auto-save to prevent duplicates
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
        // Mark as saved
        hasChanges = false
        
        if !silent {
            dismiss()
        }
    }

    private func saveForm(silent: Bool = false) {
        saveFormWithEndTime(endTime: nil, silent: silent)
    }

    
    private func finishForm() {
        // Set end time first
        let endTime = Date()
        
        // Set end time and show final summary
        if let existingForm = form {
            existingForm.endedAt = endTime
        }
        
        showingFinalSummary = true
        hasChanges = true
        
        // Save the form with end time set
        saveFormWithEndTime(endTime: endTime, silent: true)
    }
    
    private func autoFinishForm() {
        // Otomatik fire hesabı - sadece summary'yi göster, end time set etme
        showingFinalSummary = true
        hasChanges = true
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SarnelForm.self, configurations: config)
        
        return SarnelEditorView()
            .environmentObject(AuthenticationManager())
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
