import SwiftUI

// MARK: - Table Row Component
struct TableRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .tableRowStyle()
    }
}

// MARK: - Table Cell Component
struct TableCell: View {
    let text: String
    let alignment: Alignment
    let weight: Font.Weight
    let color: Color
    
    init(
        _ text: String,
        alignment: Alignment = .leading,
        weight: Font.Weight = NomisTheme.bodyWeight,
        color: Color = NomisTheme.text
    ) {
        self.text = text
        self.alignment = alignment
        self.weight = weight
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.body.weight(weight))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

// MARK: - Editable Table Cell (Luxury Style)
struct EditableTableCell: View {
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isEnabled: Bool
    
    init(
        value: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        isEnabled: Bool = true
    ) {
        self._value = value
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        TextField(placeholder, text: $value)
            .keyboardType(keyboardType)
            .disabled(!isEnabled)
            .multilineTextAlignment(.center)
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
            .foregroundColor(NomisTheme.darkText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(isEnabled ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                    .overlay(
                        Rectangle()
                            .stroke(
                                isEnabled ? NomisTheme.primaryGreen.opacity(0.3) : NomisTheme.border,
                                lineWidth: 1.5
                            )
                    )
            )
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Number Table Cell (Luxury Style)
struct NumberTableCell: View {
    @Binding var value: Double?
    let placeholder: String
    let isEnabled: Bool
    let unit: String
    
    @State private var textValue: String = ""
    
    init(
        value: Binding<Double?>,
        placeholder: String = "0",
        isEnabled: Bool = true,
        unit: String = ""
    ) {
        self._value = value
        self.placeholder = placeholder
        self.isEnabled = isEnabled
        self.unit = unit
    }
    
    var body: some View {
        HStack(spacing: 6) {
            TextField(placeholder, text: $textValue)
                .keyboardType(.decimalPad)
                .disabled(!isEnabled)
                .multilineTextAlignment(.center)
                .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                .foregroundColor(NomisTheme.darkText)
                .onChange(of: textValue) { _, newValue in
                    value = NomisFormatters.parseDouble(from: newValue)
                }
                .onAppear {
                    updateTextValue()
                }
                .onChange(of: value) { _, _ in
                    updateTextValue()
                }
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: NomisTheme.captionSize, weight: NomisTheme.captionWeight))
                    .foregroundColor(NomisTheme.goldAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(isEnabled ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                .overlay(
                    Rectangle()
                        .stroke(
                            isEnabled ? NomisTheme.primaryGreen.opacity(0.3) : NomisTheme.border,
                            lineWidth: 1.5
                        )
                )
        )
        .frame(maxWidth: .infinity)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    private func updateTextValue() {
        if let val = value {
            textValue = NomisFormatters.safeFormat(val)
        } else {
            textValue = ""
        }
    }
}

// MARK: - Table Header
struct TableHeader: View {
    let columns: [String]
    
    var body: some View {
        HStack {
            ForEach(columns, id: \.self) { column in
                Text(column)
                    .font(.subheadline.weight(NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.text)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, NomisTheme.contentSpacing)
        .padding(.vertical, NomisTheme.smallSpacing)
        .background(NomisTheme.primary.opacity(0.2))
        .overlay(
            Rectangle()
                .stroke(NomisTheme.border, lineWidth: 2)
        )
    }
}

// MARK: - Totals Row
struct TotalsRow: View {
    let label: String
    let values: [String]
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.subheadline.weight(NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, NomisTheme.contentSpacing)
        .padding(.vertical, NomisTheme.smallSpacing)
        .background(NomisTheme.goldAccent.opacity(0.1))
    }
}

// MARK: - Add Row Button
struct AddRowButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(title)
            }
            .font(.subheadline.weight(NomisTheme.headlineWeight))
            .foregroundColor(NomisTheme.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Divider
struct SectionDivider: View {
    let title: String?
    
    init(_ title: String? = nil) {
        self.title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let title = title {
                Text(title)
                    .sectionHeaderStyle()
            }
            
            Rectangle()
                .fill(NomisTheme.border)
                .frame(height: 1)
        }
    }
}

// MARK: - Info Button with Timestamp
struct InfoButton: View {
    let timestamp: Date?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "info.circle")
                .foregroundColor(NomisTheme.secondaryText)
                .font(.caption)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Timestamp Popup
struct TimestampPopup: View {
    let timestamp: Date?
    
    var body: some View {
        VStack(spacing: NomisTheme.smallSpacing) {
            Text("Girish Zamanı")
                .font(.caption.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
            
            Text(NomisFormatters.formatTimestamp(timestamp))
                .font(.caption)
                .foregroundColor(NomisTheme.secondaryText)
        }
        .padding(NomisTheme.contentSpacing)
        .background(NomisTheme.cardBackground)
        .cornerRadius(NomisTheme.fieldCornerRadius)
        .shadow(color: NomisTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - STABLE TABLE COMPONENTS (NO ROW REORDERING)

// MARK: - Stable Table View Component (No Row Reordering)
struct StableTableView<RowData: Identifiable>: View where RowData.ID == UUID {
    let rows: [RowData]
    let rowBuilder: (RowData, Int) -> AnyView
    
    @State private var stableSnapshot: [(UUID, RowData)] = []
    
    init(
        rows: [RowData],
        @ViewBuilder rowBuilder: @escaping (RowData, Int) -> AnyView
    ) {
        self.rows = rows
        self.rowBuilder = rowBuilder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stableSnapshot.enumerated()), id: \.element.0) { enumerated in
                let index = enumerated.offset
                let (uuid, row) = enumerated.element
                rowBuilder(row, index)
                    .id("super_stable_\(uuid)")
            }
        }
        .animation(.none, value: stableSnapshot.count) // Disable all animations
        .onAppear {
            updateStableSnapshot()
        }
        // CONTROLLED UPDATE: Enable listeners for row addition detection
        .onChange(of: rows.count) { oldCount, newCount in
            // Only update when rows are added, not for reordering
            if newCount > oldCount {
                updateStableSnapshot()
            }
        }
        .onChange(of: rows.map(\.id)) { oldIds, newIds in
            // Only update when new IDs are detected (new rows)
            let oldIdSet = Set(oldIds)
            let newIdSet = Set(newIds)
            if !newIdSet.subtracting(oldIdSet).isEmpty {
                updateStableSnapshot()
            }
        }
    }
    
    private func updateStableSnapshot() {
        // Use creation time for stable ordering (if available)
        let sortedRows: [RowData]
        
        // Try to sort by orderIndex first, then createdAt if the type has these properties
        if let firstRow = rows.first {
            let mirror = Mirror(reflecting: firstRow)
            if mirror.children.contains(where: { $0.label == "orderIndex" }) {
                // Sort by orderIndex using reflection (preferred method)
                sortedRows = rows.sorted { row1, row2 in
                    let mirror1 = Mirror(reflecting: row1)
                    let mirror2 = Mirror(reflecting: row2)
                    
                    guard let index1 = mirror1.children.first(where: { $0.label == "orderIndex" })?.value as? Int,
                          let index2 = mirror2.children.first(where: { $0.label == "orderIndex" })?.value as? Int else {
                        return false
                    }
                    
                    return index1 < index2
                }
            } else if mirror.children.contains(where: { $0.label == "createdAt" }) {
                // Fallback to createdAt using reflection
                sortedRows = rows.sorted { row1, row2 in
                    let mirror1 = Mirror(reflecting: row1)
                    let mirror2 = Mirror(reflecting: row2)
                    
                    guard let date1 = mirror1.children.first(where: { $0.label == "createdAt" })?.value as? Date,
                          let date2 = mirror2.children.first(where: { $0.label == "createdAt" })?.value as? Date else {
                        return false
                    }
                    
                    return date1 < date2
                }
            } else {
                // Fallback to original order
                sortedRows = rows
            }
        } else {
            sortedRows = rows
        }
        
        let newSnapshot = sortedRows.map { ($0.id, $0) }
        
        // If this is the first time, create initial snapshot
        if stableSnapshot.isEmpty {
            stableSnapshot = newSnapshot
            return
        }
        
        // CRITICAL: NEVER reorder - only update existing data in place
        let currentIDs = Set(stableSnapshot.map(\.0))
        let newIDs = Set(newSnapshot.map(\.0))
        
        // Only update data for existing rows, never change position
        var updatedSnapshot: [(UUID, RowData)] = []
        for (uuid, _) in stableSnapshot {
            if let newRowData = newSnapshot.first(where: { $0.0 == uuid })?.1 {
                updatedSnapshot.append((uuid, newRowData))
            }
        }
        
        // Add new rows ONLY at the very end, in creation order
        let addedIDs = newIDs.subtracting(currentIDs)
        for (uuid, row) in newSnapshot {
            if addedIDs.contains(uuid) {
                updatedSnapshot.append((uuid, row))
            }
        }
        
        // ABSOLUTE FREEZE: Once set, this order is PERMANENT
        stableSnapshot = updatedSnapshot
    }
}

// MARK: - Tezgah Table Row (Stable Version)
struct StableTezgahTableRow: View {
    let satir: TezgahSatiri
    let index: Int
    let isReadOnly: Bool
    @State private var localChanges = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Açıklama Giriş
            StableEditableCell(
                text: Binding(
                    get: { satir.aciklamaGiris },
                    set: { satir.aciklamaGiris = $0; markChanged() }
                ),
                placeholder: "Açıklama",
                isEnabled: !isReadOnly,
                createdAt: satir.aciklamaGirisTarihi
            )
            
            // Giriş Value
            StableNumberCell(
                value: Binding(
                    get: { satir.girisValue },
                    set: { satir.girisValue = $0; markChanged() }
                ),
                placeholder: "0",
                    unit: "",
                isEnabled: !isReadOnly
            )
            
            // Çıkış Value
            StableNumberCell(
                value: Binding(
                    get: { satir.cikisValue },
                    set: { satir.cikisValue = $0; markChanged() }
                ),
                placeholder: "0",
                    unit: "",
                isEnabled: !isReadOnly
            )
            
            // Açıklama Çıkış
            StableEditableCell(
                text: Binding(
                    get: { satir.aciklamaCikis },
                    set: { satir.aciklamaCikis = $0; markChanged() }
                ),
                placeholder: "Açıklama",
                isEnabled: !isReadOnly,
                createdAt: satir.aciklamaCikisTarihi
            )
            
        }
        .frame(height: 55) // Fixed height prevents jumping
        .background(
            Rectangle()
                .fill(
                    index % 2 == 0 
                    ? NomisTheme.lightCream 
                    : NomisTheme.creamBackground
                )
        )
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 1.5)
        )
    }
    
    private func markChanged() {
        localChanges = true
        // Trigger parent save via notification if needed
    }
}

// MARK: - İşlem Table Row (Stable Version)
struct StableIslemTableRow: View {
    let satir: IslemSatiri
    let index: Int
    let ayar: Int?
    let isReadOnly: Bool
    let allowExpandableCikis: Bool // Çıkış hücresi genişletmeye izin ver
    let showAyarColumn: Bool // Ayar sütununu göster/gizle
    let onAddRowAfter: ((Int) -> Void)? // Yeni satır ekleme callback'i
    @State private var localChanges = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Açıklama Giriş
            StableEditableCell(
                text: Binding(
                    get: { satir.aciklamaGiris },
                    set: { satir.aciklamaGiris = $0; markChanged() }
                ),
                placeholder: "Açıklama",
                isEnabled: !isReadOnly,
                createdAt: satir.aciklamaGirisTarihi
            )
            
            // Giriş Value (editable via computed property)
            StableNumberCell(
                value: Binding(
                    get: { satir.giris },
                    set: { satir.giris = $0 ?? 0; markChanged() }
                ),
                placeholder: "0",
                unit: "",
                isEnabled: !isReadOnly
            )
            
            // Çıkış Values - Expandable veya Normal
            Group {
                if allowExpandableCikis {
                    // Expandable çıkış sistemi - her çıkış değeri alt alta
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(satir.cikisValues.enumerated()), id: \.element.id) { cikisIndex, cikisValue in
                            HStack(spacing: 6) {
                                // Çıkış hücresini giriş hücresiyle aynı genişlikte yap
                                StableNumberCell(
                                    value: Binding(
                                        get: { cikisValue.value },
                                        set: { newValue in 
                                            cikisValue.value = newValue
                                            markChanged()
                                        }
                                    ),
                                    placeholder: "0",
                                    unit: "",
                                    isEnabled: !isReadOnly
                                )
                                
                                // + butonu (yeni çıkış ekler) - silme butonu kaldırıldı
                                if !isReadOnly {
                                    Button(action: {
                                        addCikisValueAfter(index: cikisIndex)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(NomisTheme.primaryGreen)
                                            .font(.system(size: 16))
                                    }
                                    .frame(width: 24, height: 24)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    // Normal tek çıkış sistemi
                    StableNumberCell(
                        value: Binding(
                            get: { satir.cikis },
                            set: { satir.cikis = $0 ?? 0; markChanged() }
                        ),
                        placeholder: "0",
                        unit: "",
                        isEnabled: !isReadOnly
                    )
                }
            }
            .frame(maxWidth: .infinity) // Consistent with other cells
            .onAppear {
                // Eğer çıkış değerleri yoksa, başlangıçta bir tane ekle
                if satir.cikisValues.isEmpty {
                    satir.cikisValues.append(GenisletilebilirDeger(value: 0.0))
                }
            }
            
            // Fire (computed from toplamGiris - toplamCikis)
            StableEditableCell(
                text: Binding(
                    get: { String(format: "%.2f", satir.fire) },
                    set: { _ in /* Read-only computed value */ }
                ),
                placeholder: "0",
                isEnabled: false,
                textColor: NomisTheme.destructive
            )
            
            // Açıklama Fire (Fire ve Ayar arası yeni sütun)
            StableEditableCell(
                text: Binding(
                    get: { satir.aciklamaFire },
                    set: { 
                        satir.aciklamaFire = $0
                        if !$0.isEmpty && satir.aciklamaFireTarihi == nil {
                            satir.aciklamaFireTarihi = Date()
                        }
                        markChanged()
                    }
                ),
                placeholder: "Açıklama",
                isEnabled: !isReadOnly,
                createdAt: satir.aciklamaFireTarihi
            )
            
            // Ayar (sadece Makine & Testere Kesme kartlarında göster)
            if showAyarColumn {
                Picker("Ayar", selection: Binding(
                    get: { satir.ayar ?? 0 },
                    set: { satir.ayar = $0 == 0 ? nil : $0; markChanged() }
                )) {
                    Text("Seçiniz").tag(0)
                    Text("14").tag(14)
                    Text("18").tag(18)
                    Text("21").tag(21)
                    Text("22").tag(22)
                }
                .disabled(isReadOnly)
                .pickerStyle(MenuPickerStyle())
                .font(.system(size: NomisTheme.bodySize, weight: .semibold))
                .foregroundColor(NomisTheme.prominentText)
                .frame(maxWidth: .infinity, minHeight: 55) // Consistent with other cells
                .background(
                    Rectangle()
                        .fill(
                            index % 2 == 0 
                            ? NomisTheme.lightCream 
                            : NomisTheme.creamBackground
                        )
                )
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 1)
                )
            }
        }
        .frame(minHeight: allowExpandableCikis ? CGFloat(55 + max(0, satir.cikisValues.count - 1) * 70) : 55)
        .background(
            Rectangle()
                .fill(
                    index % 2 == 0 
                    ? NomisTheme.lightCream 
                    : NomisTheme.creamBackground
                )
        )
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 1.5)
        )
    }
    
    private func markChanged() {
        localChanges = true
        // Trigger parent save via notification if needed
    }
    
    private func addCikisValue() {
        let newCikisValue = GenisletilebilirDeger(value: 0.0)
        satir.cikisValues.append(newCikisValue)
        markChanged()
    }
    
    private func addCikisValueAfter(index: Int) {
        let newCikisValue = GenisletilebilirDeger(value: 0.0)
        let insertIndex = min(index + 1, satir.cikisValues.count)
        satir.cikisValues.insert(newCikisValue, at: insertIndex)
        markChanged()
    }
    
}


// MARK: - Stable Editable Cell
struct StableEditableCell: View {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    let createdAt: Date?
    let textColor: Color?
    
    @State private var showTooltip = false
    
    init(text: Binding<String>, placeholder: String, isEnabled: Bool, createdAt: Date? = nil, textColor: Color? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.textColor = textColor
    }
    
    var body: some View {
        HStack(spacing: NomisTheme.tinySpacing) {
            TextField(placeholder, text: $text)
                .disabled(!isEnabled)
                .multilineTextAlignment(.center)
                .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                .foregroundColor(
                    textColor ?? (isEnabled ? NomisTheme.darkText : NomisTheme.secondaryText)
                )
            
            if !text.isEmpty && textColor != NomisTheme.destructive {
                Button(action: { showTooltip.toggle() }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(NomisTheme.primaryGreen.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showTooltip) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Oluşturma Bilgisi")
                            .font(.headline)
                            .foregroundColor(NomisTheme.primaryGreen)
                        let displayDate = createdAt ?? Date()
                        Text("Tarih: \(displayDate, formatter: dateFormatter)")
                        Text("Saat: \(displayDate, formatter: timeFormatter)")
                    }
                    .padding()
                    .frame(minWidth: 180)
                }
            }
        }
        .padding(.horizontal, NomisTheme.smallSpacing)
        .padding(.vertical, NomisTheme.smallSpacing)
        .background(
            Rectangle()
                .fill(isEnabled ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                .overlay(
                    Rectangle()
                        .stroke(
                            isEnabled ? NomisTheme.primaryGreen : NomisTheme.border.opacity(0.3), 
                            lineWidth: isEnabled ? 2.0 : 0.5
                        )
                )
        )
        .frame(maxWidth: .infinity)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Stable Number Cell
struct StableNumberCell: View {
    @Binding var value: Double?
    let placeholder: String
    let unit: String
    let isEnabled: Bool
    
    @State private var textValue: String = ""
    
    var body: some View {
        HStack(spacing: NomisTheme.tinySpacing) {
            TextField(placeholder, text: $textValue)
                .keyboardType(.decimalPad)
                .disabled(!isEnabled)
                .multilineTextAlignment(.center)
                .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                .foregroundColor(isEnabled ? NomisTheme.darkText : NomisTheme.secondaryText)
                .onChange(of: textValue) { _, newValue in
                    value = NomisFormatters.parseDouble(from: newValue)
                }
                .onAppear {
                    updateTextValue()
                }
                .onChange(of: value) { _, _ in
                    updateTextValue()
                }
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: NomisTheme.captionSize, weight: NomisTheme.captionWeight))
                    .foregroundColor(NomisTheme.goldAccent)
            }
        }
        .padding(.horizontal, NomisTheme.smallSpacing)
        .padding(.vertical, NomisTheme.smallSpacing)
        .background(
            Rectangle()
                .fill(isEnabled ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                .overlay(
                    Rectangle()
                        .stroke(
                            isEnabled ? NomisTheme.primaryGreen : NomisTheme.border.opacity(0.3), 
                            lineWidth: isEnabled ? 2.0 : 0.5
                        )
                )
        )
        .frame(maxWidth: .infinity)
    }
    
    private func updateTextValue() {
        if let val = value {
            textValue = NomisFormatters.safeFormat(val)
        } else {
            textValue = ""
        }
    }
}

// MARK: - Fire Summary Table
struct FireSummaryTable: View {
    let fireData: [SimpleAyarFireData]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Proje temasıyla uyumlu
            HStack(spacing: 0) {
                Text("Ayar")
                    .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.prominentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NomisTheme.lightCream)
                
                // Dikey ayırıcı çizgi
                Rectangle()
                    .fill(NomisTheme.primaryGreen.opacity(0.8))
                    .frame(width: 1)
                
                Text("Fire Miktarı")
                    .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.prominentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NomisTheme.lightCream)
            }
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 1.5)
            )
            
            // Fire rows
            ForEach(Array(fireData.enumerated()), id: \.element.ayar) { index, data in
                HStack(spacing: 0) {
                    // Ayar hücresi
                    Text("\(data.ayar)k")
                        .font(.system(size: NomisTheme.bodySize, weight: .semibold))
                        .foregroundColor(NomisTheme.darkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            index % 2 == 0 
                            ? NomisTheme.lightCream 
                            : NomisTheme.creamBackground
                        )
                    
                    // Dikey ayırıcı çizgi
                    Rectangle()
                        .fill(NomisTheme.primaryGreen.opacity(0.8))
                        .frame(width: 1)
                    
                    // Fire miktarı hücresi
                    Text("\(NomisFormatters.safeFormat(data.fire)) gr")
                        .font(.system(size: NomisTheme.bodySize, weight: .bold))
                        .foregroundColor(.red) // Sadece fire değerleri kırmızı
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            index % 2 == 0 
                            ? NomisTheme.lightCream 
                            : NomisTheme.creamBackground
                        )
                }
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(height: 1)
                    }
                )
            }
        }
        .background(NomisTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
        )
        .cornerRadius(8)
    }
}

// MARK: - Weekly Fire Summary Table
struct WeeklyFireSummaryTable: View {
    let fireData: [AyarFireData]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Haftalık özet teması
            HStack(spacing: 0) {
                Text("Haftalık Fire Özeti")
                    .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [NomisTheme.primaryGreen, NomisTheme.primaryGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.primaryGreen, lineWidth: 2)
            )
            
            // Scrollable table content
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Column headers
                    HStack(spacing: 0) {
                        // Ayar kolonu - sabit genişlik
                        Text("Ayar")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 70)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Tezgah 1
                        Text("Tezgah 1")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Tezgah 2
                        Text("Tezgah 2")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Cila
                        Text("Cila")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Ocak
                        Text("Ocak")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Patlatma
                        Text("Patlatma")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Tambur
                        Text("Tambur")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Makine
                        Text("Makine")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                        
                        Rectangle()
                            .fill(NomisTheme.primaryGreen.opacity(0.8))
                            .frame(width: 2)
                        
                        // Testere
                        Text("Testere")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: NomisTheme.headlineWeight))
                            .foregroundColor(NomisTheme.prominentText)
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(NomisTheme.goldAccent.opacity(0.1))
                    }
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 1.5)
                    )
                    
                    // Fire rows - Haftalık değerler
                    ForEach(Array(fireData.enumerated()), id: \.element.ayar) { index, data in
                        HStack(spacing: 0) {
                            // Ayar hücresi
                            Text("\(data.ayar)k")
                                .font(.system(size: NomisTheme.bodySize + 1, weight: .bold))
                                .foregroundColor(NomisTheme.darkText)
                                .frame(width: 70)
                                .padding(.vertical, 12)
                                .background(
                                    index % 2 == 0 
                                    ? NomisTheme.lightCream 
                                    : NomisTheme.creamBackground
                                )
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Tezgah 1
                            FireCell(fire: data.tezgah1Fire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Tezgah 2
                            FireCell(fire: data.tezgah2Fire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Cila
                            FireCell(fire: data.cilaFire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Ocak
                            FireCell(fire: data.ocakFire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Patlatma
                            FireCell(fire: data.patlatmaFire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Tambur
                            FireCell(fire: data.tamburFire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Makine
                            FireCell(fire: data.makineFire, isEvenRow: index % 2 == 0)
                            
                            Rectangle()
                                .fill(NomisTheme.primaryGreen.opacity(0.8))
                                .frame(width: 2)
                            
                            // Testere
                            FireCell(fire: data.testereFire, isEvenRow: index % 2 == 0)
                        }
                        .overlay(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(NomisTheme.primaryGreen.opacity(0.8))
                                    .frame(height: 1)
                            }
                        )
                    }
                    
                    // Total row - Genel toplam
                    HStack(spacing: 0) {
                        Text("TOPLAM")
                            .font(.system(size: NomisTheme.headlineSize - 1, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 70)
                            .padding(.vertical, 12)
                            .background(NomisTheme.primaryGreen)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Tezgah 1 toplam
                        let tezgah1Total = fireData.reduce(0.0) { $0 + $1.tezgah1Fire }
                        TotalFireCell(fire: tezgah1Total)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Tezgah 2 toplam
                        let tezgah2Total = fireData.reduce(0.0) { $0 + $1.tezgah2Fire }
                        TotalFireCell(fire: tezgah2Total)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Cila toplam
                        let cilaTotal = fireData.reduce(0.0) { $0 + $1.cilaFire }
                        TotalFireCell(fire: cilaTotal)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Ocak toplam
                        let ocakTotal = fireData.reduce(0.0) { $0 + $1.ocakFire }
                        TotalFireCell(fire: ocakTotal)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Patlatma toplam
                        let patlatmaTotal = fireData.reduce(0.0) { $0 + $1.patlatmaFire }
                        TotalFireCell(fire: patlatmaTotal)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Tambur toplam
                        let tamburTotal = fireData.reduce(0.0) { $0 + $1.tamburFire }
                        TotalFireCell(fire: tamburTotal)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Makine toplam
                        let makineTotal = fireData.reduce(0.0) { $0 + $1.makineFire }
                        TotalFireCell(fire: makineTotal)
                        
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                        
                        // Testere toplam
                        let testereTotal = fireData.reduce(0.0) { $0 + $1.testereFire }
                        TotalFireCell(fire: testereTotal)
                    }
                }
            }
        }
        .background(NomisTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen, lineWidth: 3)
        )
        .cornerRadius(12)
        .shadow(color: NomisTheme.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// Helper view for fire cells
private struct FireCell: View {
    let fire: Double
    let isEvenRow: Bool
    
    var body: some View {
        Text(fire > 0 ? "\(NomisFormatters.safeFormat(fire))" : "-")
            .font(.system(size: NomisTheme.bodySize, weight: fire > 0 ? .semibold : .regular))
            .foregroundColor(fire > 0 ? .red : NomisTheme.secondaryText)
            .frame(width: 90)
            .padding(.vertical, 12)
            .background(
                isEvenRow 
                ? (fire > 0 ? Color.red.opacity(0.05) : NomisTheme.lightCream)
                : (fire > 0 ? Color.red.opacity(0.1) : NomisTheme.creamBackground)
            )
    }
}

// Helper view for total fire cells
private struct TotalFireCell: View {
    let fire: Double
    
    var body: some View {
        Text(fire > 0 ? "\(NomisFormatters.safeFormat(fire))" : "-")
            .font(.system(size: NomisTheme.headlineSize - 1, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 90)
            .padding(.vertical, 12)
            .background(NomisTheme.primaryGreen)
    }
}

// MARK: - Ayar Fire Data Models
// Haftalık fire özeti için detaylı model
struct AyarFireData {
    let ayar: Int
    let tezgah1Fire: Double
    let tezgah2Fire: Double
    let cilaFire: Double
    let ocakFire: Double
    let patlatmaFire: Double
    let tamburFire: Double
    let makineFire: Double
    let testereFire: Double
    
    var totalFire: Double {
        tezgah1Fire + tezgah2Fire + cilaFire + ocakFire + patlatmaFire + tamburFire + makineFire + testereFire
    }
}

// Tek kart için basit fire modeli
struct SimpleAyarFireData {
    let ayar: Int
    let fire: Double
}

// MARK: - Stable Table Header
struct StableTableHeader: View {
    let columns: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.self) { column in
                Text(column)
                    .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.blackNight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, NomisTheme.smallSpacing)
                    .padding(.vertical, NomisTheme.contentSpacing)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [NomisTheme.champagneGold.opacity(0.3), NomisTheme.goldAccent.opacity(0.2)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.primaryGreen, lineWidth: NomisTheme.tableBorderWidth)
                    )
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(NomisTheme.primaryGreen)
                                .frame(height: 2)
                        }
                    )
            }
        }
        .background(NomisTheme.cardBackground)
    }
}

// MARK: - Stable Add Row Button
struct StableAddRowButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: NomisTheme.tinySpacing) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: NomisTheme.bodySize))
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
            }
            .padding(.vertical, NomisTheme.smallSpacing)
            .frame(maxWidth: .infinity)
            .background(NomisTheme.primaryGreen)
            .overlay(
                Rectangle()
                    .stroke(NomisTheme.primaryGreen, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, NomisTheme.tinySpacing)
    }
}

#Preview {
    VStack(spacing: 20) {
        TableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Açıklama"])
        
        TableRow {
            EditableTableCell(value: .constant("Test açıklama"))
            NumberTableCell(value: .constant(15.5), unit: "gr")
            NumberTableCell(value: .constant(12.3), unit: "gr")
            EditableTableCell(value: .constant("Sonuç"))
        }
        
        TotalsRow(label: "Toplam", values: ["27.8 gr", "24.6 gr"])
        
        AddRowButton(title: "Yeni Satır Ekle") {
            // Empty action
        }
        
        SectionDivider("Demirli Değerler")
    }
    .padding()
}
