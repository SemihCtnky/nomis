import SwiftUI
import SwiftData

// MARK: - Kilit Number Field (NumberTableCell logic with Kilit styling)
struct KilitNumberField: View {
    @Binding var value: Double?
    let placeholder: String
    let isEnabled: Bool
    let onChange: () -> Void
    
    @State private var textValue: String = ""
    
    init(
        value: Binding<Double?>,
        placeholder: String = "0",
        isEnabled: Bool = true,
        onChange: @escaping () -> Void = {}
    ) {
        self._value = value
        self.placeholder = placeholder
        self.isEnabled = isEnabled
        self.onChange = onChange
    }
    
    var body: some View {
        TextField(placeholder, text: $textValue)
            .keyboardType(.decimalPad)
            .disabled(!isEnabled)
            .multilineTextAlignment(.center)
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
            .foregroundColor(NomisTheme.darkText)
            .onChange(of: textValue) { _, newValue in
                value = NomisFormatters.parseDouble(from: newValue)
                onChange()
            }
            .onAppear {
                updateTextValue()
            }
            .onChange(of: value) { _, _ in
                updateTextValue()
            }
    }
    
    private func updateTextValue() {
        if let val = value {
            textValue = NomisFormatters.safeFormat(val)
        } else {
            textValue = ""
        }
    }
}

struct KilitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query private var models: [ModelItem]
    @Query private var companies: [CompanyItem]
    
    @State private var form: KilitToplamaForm?
    @State private var model: String = ""
    @State private var firma: String = ""
    @State private var ayar: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    // Item arrays
    @State private var kasaItems: [KilitItem] = [KilitItem()]
    @State private var dilItems: [KilitItem] = [KilitItem()]
    @State private var yayItems: [KilitItem] = [KilitItem()]
    @State private var kilitItems: [KilitItem] = [KilitItem()]
    
    @State private var showingFinalSummary = false
    @State private var hasChanges = false
    @State private var hasStarted = false
    
    // Zoom functionality
    @State private var currentZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    let isReadOnly: Bool
    
    var isNewForm: Bool {
        form == nil
    }
    
    var canStartForm: Bool {
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !firma.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ayar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(form: KilitToplamaForm? = nil, isReadOnly: Bool = false) {
        self._form = State(initialValue: form)
        self.isReadOnly = isReadOnly
        
        if let form = form {
            self._model = State(initialValue: form.model ?? "")
            self._firma = State(initialValue: form.firma ?? "")
            self._ayar = State(initialValue: String(form.ayar ?? 0))
            self._startDate = State(initialValue: form.startedAt ?? Date())
            self._endDate = State(initialValue: form.endedAt ?? Date())
            self._kasaItems = State(initialValue: form.kasaItems.isEmpty ? [KilitItem()] : form.kasaItems)
            self._dilItems = State(initialValue: form.dilItems.isEmpty ? [KilitItem()] : form.dilItems)
            self._yayItems = State(initialValue: form.yayItems.isEmpty ? [KilitItem()] : form.yayItems)
            self._kilitItems = State(initialValue: form.kilitItems.isEmpty ? [KilitItem()] : form.kilitItems)
            self._showingFinalSummary = State(initialValue: form.endedAt != nil)
            self._hasStarted = State(initialValue: form.startedAt != nil)
        }
    }
    
    // Computed zoom scale (gesture + base)
    private var finalZoomScale: CGFloat {
        currentZoomScale * gestureZoomScale
    }
    
    // Magnification gesture for pinch-to-zoom
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                currentZoomScale *= value
                // Limit zoom: 0.5x to 3.0x
                currentZoomScale = min(max(currentZoomScale, 0.5), 3.0)
            }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: NomisTheme.sectionSpacing) {
                    // Header Section (Model & Firma)
                    headerSection
                    
                    // Date Section
                    if hasStarted {
                        dateSection
                    }
                    
                    // Ayar Section
                    ayarSection
                    
                    // Main Table
                    mainTableSection
                    
                    // Summary Section
                    summarySection
                    
                    // Final Summary Section (after completion)
                    if showingFinalSummary {
                        finalSummarySection
                    }
                    
                    // Action Buttons
                    if !isReadOnly {
                        actionButtonsSection
                    }
                }
                .padding(NomisTheme.contentSpacing)
                .scaleEffect(finalZoomScale) // Apply zoom
                .gesture(magnificationGesture) // Pinch-to-zoom gesture
            }
            .navigationTitle(isNewForm ? "Yeni Kilit Toplama" : "Kilit Toplama Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
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
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if isNewForm && !hasStarted {
                startFormIfNeeded()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    Text("Model")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Picker("Model", selection: $model) {
                        Text("Seçiniz").tag("")
                        ForEach(models, id: \.id) { modelItem in
                            Text(modelItem.name).tag(modelItem.name)
                        }
                    }
                    .disabled(isReadOnly)
                    .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.prominentText)
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background((authManager.canEdit && !isReadOnly) ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                    .overlay(
                        Rectangle()
                            .stroke(
                                (authManager.canEdit && !isReadOnly) ? NomisTheme.primaryGreen.opacity(0.3) : NomisTheme.borderGray,
                                lineWidth: NomisTheme.tableBorderWidth
                            )
                    )
                        .onChange(of: model) { _, _ in hasChanges = true }
                }
                .frame(maxWidth: .infinity)
                .frame(height: NomisTheme.tableHeaderHeight)
                
                VStack {
                    Text("Firma")
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
                
                VStack {
                    Picker("Firma", selection: $firma) {
                        Text("Seçiniz").tag("")
                        ForEach(companies, id: \.id) { company in
                            Text(company.name).tag(company.name)
                        }
                    }
                    .disabled(isReadOnly)
                    .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.prominentText)
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background((authManager.canEdit && !isReadOnly) ? NomisTheme.lightCream : NomisTheme.cardBackground.opacity(0.5))
                    .overlay(
                        Rectangle()
                            .stroke(
                                (authManager.canEdit && !isReadOnly) ? NomisTheme.primaryGreen.opacity(0.3) : NomisTheme.borderGray,
                                lineWidth: NomisTheme.tableBorderWidth
                            )
                    )
                    .onChange(of: firma) { _, _ in hasChanges = true }
                }
                .frame(maxWidth: .infinity)
                .frame(height: NomisTheme.tableHeaderHeight)
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            HStack {
                if hasStarted {
                    VStack(alignment: .leading) {
                        Text("Başlama:")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                        Text(Formatters.formatDateTime(startDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.text)
                    }
                }
                
                Spacer()
                
                if showingFinalSummary {
                    VStack(alignment: .trailing) {
                        Text("Bitiş:")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                        Text(Formatters.formatDateTime(endDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.text)
                    }
                }
            }
            .padding(.horizontal, NomisTheme.contentSpacing)
        }
    }
    
    // MARK: - Ayar Section
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
                        Text(ayar.isEmpty ? "Seçilmemiş" : ayar)
                            .font(.system(size: NomisTheme.headlineSize, weight: .black))
                            .foregroundColor(ayar.isEmpty ? NomisTheme.secondaryText : NomisTheme.blackNight)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(NomisTheme.cardBackground.opacity(0.5))
                            .overlay(
                                Rectangle()
                                    .stroke(NomisTheme.borderGray, lineWidth: NomisTheme.tableBorderWidth)
                            )
                    } else {
                        // Editable mode: Show as picker
                        Picker("Ayar", selection: $ayar) {
                            Text("Seçiniz").tag("")
                            Text("14").tag("14")
                            Text("18").tag("18")
                            Text("21").tag("21")
                            Text("22").tag("22")
                        }
                        .font(.system(size: NomisTheme.headlineSize, weight: .bold))
                        .foregroundColor(NomisTheme.prominentText)
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(NomisTheme.lightCream)
                        .overlay(
                            Rectangle()
                                .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: NomisTheme.tableBorderWidth)
                        )
                    }
                }
                .frame(width: 150, height: NomisTheme.tableHeaderHeight)
                .onChange(of: ayar) { _, _ in hasChanges = true }
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    // MARK: - Main Table Section
    private var mainTableSection: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                VStack { Spacer() }
                    .frame(width: 100)
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
                
                VStack { Spacer() }
                    .frame(width: 70)
                    .luxuryTableHeader()
            }
            .frame(height: NomisTheme.tableCellHeight)
                
            // Kasa Rows
            ForEach(kasaItems.indices, id: \.self) { index in
                luxuryItemRow(
                    title: "Kasa",
                    item: $kasaItems[index],
                    showAddButton: index == 0,
                    onAdd: { kasaItems.append(KilitItem()) },
                    onDelete: kasaItems.count > 1 ? { kasaItems.remove(at: index) } : nil,
                    showAdetForEntry: true,
                    showAdetForExit: true
                )
            }
            
            // Dil Rows
            ForEach(dilItems.indices, id: \.self) { index in
                luxuryItemRow(
                    title: "Dil",
                    item: $dilItems[index],
                    showAddButton: index == 0,
                    onAdd: { dilItems.append(KilitItem()) },
                    onDelete: dilItems.count > 1 ? { dilItems.remove(at: index) } : nil,
                    showAdetForEntry: true,
                    showAdetForExit: true
                )
            }
            
            // Yay Rows (no adet, only gram combined)
            ForEach(yayItems.indices, id: \.self) { index in
                luxuryYayItemRow(
                    item: $yayItems[index],
                    showAddButton: index == 0,
                    onAdd: { yayItems.append(KilitItem()) },
                    onDelete: yayItems.count > 1 ? { yayItems.remove(at: index) } : nil
                )
            }
            
            // Kilit Rows
            ForEach(kilitItems.indices, id: \.self) { index in
                luxuryKilitItemRow(
                    item: $kilitItems[index],
                    showAddButton: index == 0,
                    onAdd: { kilitItems.append(KilitItem()) },
                    onDelete: kilitItems.count > 1 ? { kilitItems.remove(at: index) } : nil
                )
            }
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private func luxuryItemRow(
        title: String,
        item: Binding<KilitItem>,
        showAddButton: Bool,
        onAdd: @escaping () -> Void,
        onDelete: (() -> Void)?,
        showAdetForEntry: Bool,
        showAdetForExit: Bool
    ) -> some View {
        HStack(spacing: 0) {
            // Title with add button (Kasa/Dil için)
            VStack {
                HStack {
                    Text(title)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                    
                    if showAddButton && !isReadOnly {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(NomisTheme.primaryGreen)
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(width: 100)
            .luxuryTableCell()
            
            // Giriş Section
            HStack(spacing: 0) {
                VStack {
                    VStack(spacing: 4) {
                        Text("Adet")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NomisTheme.blackNight)
                        
                        Rectangle()
                            .fill(NomisTheme.borderGray)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                        
                        KilitNumberField(
                            value: item.girisAdet,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    VStack(spacing: 4) {
                        Text("Gram")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NomisTheme.blackNight)
                        
                        Rectangle()
                            .fill(NomisTheme.borderGray)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                        KilitNumberField(
                            value: item.girisGram,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(maxWidth: .infinity)
            
                // Çıkış Section  
                HStack(spacing: 0) {
                    VStack {
                        VStack(spacing: 4) {
                            Text("Gram")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(NomisTheme.blackNight)
                            
                            Rectangle()
                                .fill(NomisTheme.borderGray)
                                .frame(height: 1)
                                .padding(.horizontal, 4)
                        KilitNumberField(
                            value: item.cikisGram,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    VStack(spacing: 4) {
                        Text("Adet")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NomisTheme.blackNight)
                        
                        Rectangle()
                            .fill(NomisTheme.borderGray)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                        KilitNumberField(
                            value: item.cikisAdet,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                            .foregroundColor(NomisTheme.darkText)
                            .disabled(isReadOnly)
                            .onChange(of: item.cikisAdet.wrappedValue) { _, _ in hasChanges = true }
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(maxWidth: .infinity)
            
            // Right title (Kasa/Dil tekrar yazılacak)
            VStack {
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                    Spacer()
                }
                
                if let onDelete = onDelete, !isReadOnly {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } else {
                    Spacer().frame(height: 20)
                }
            }
            .frame(width: 70)
            .luxuryTableCell()
        }
        .frame(height: NomisTheme.tableCellHeight)
    }
    
    // Special row for Yay (only gram, no adet)
    private func luxuryYayItemRow(
        item: Binding<KilitItem>,
        showAddButton: Bool,
        onAdd: @escaping () -> Void,
        onDelete: (() -> Void)?
    ) -> some View {
        HStack(spacing: 0) {
            // Title with add button
            VStack {
                HStack {
                    Text("Yay")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                    
                    if showAddButton && !isReadOnly {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(NomisTheme.primaryGreen)
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(width: 100)
            .luxuryTableCell()
            
            // Giriş Section - Combined gram field  
            VStack {
                VStack(spacing: 4) {
                    Text("Gram")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(NomisTheme.blackNight)
                    
                    Rectangle()
                        .fill(NomisTheme.borderGray)
                        .frame(height: 1)
                        .padding(.horizontal, 4)
                    KilitNumberField(
                        value: item.girisGram,
                        isEnabled: !isReadOnly,
                        onChange: { hasChanges = true }
                    )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                        .disabled(isReadOnly)
                        .onChange(of: item.girisGram.wrappedValue) { _, _ in hasChanges = true }
                }
            }
            .frame(maxWidth: .infinity)
            .luxuryTableCell()
            
            // Çıkış Section - Combined gram field
            VStack {
                VStack(spacing: 4) {
                    Text("Gram")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(NomisTheme.blackNight)
                    
                    Rectangle()
                        .fill(NomisTheme.borderGray)
                        .frame(height: 1)
                        .padding(.horizontal, 4)
                    KilitNumberField(
                        value: item.cikisGram,
                        isEnabled: !isReadOnly,
                        onChange: { hasChanges = true }
                    )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                        .disabled(isReadOnly)
                        .onChange(of: item.cikisGram.wrappedValue) { _, _ in hasChanges = true }
                }
            }
            .frame(maxWidth: .infinity)
            .luxuryTableCell()
            
            // Right title (Yay tekrar yazılacak)
            VStack {
                HStack {
                    Spacer()
                    Text("Yay")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                    Spacer()
                }
                
                if let onDelete = onDelete, !isReadOnly {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } else {
                    Spacer().frame(height: 20)
                }
            }
            .frame(width: 70)
            .luxuryTableCell()
        }
        .frame(height: NomisTheme.tableCellHeight)
    }
    
    // Special row for Kilit (no left title, only exit side)
    private func luxuryKilitItemRow(
        item: Binding<KilitItem>,
        showAddButton: Bool,
        onAdd: @escaping () -> Void,
        onDelete: (() -> Void)?
    ) -> some View {
        HStack(spacing: 0) {
            // Empty left side
            VStack { Spacer() }
                .frame(width: 100)
                .luxuryTableCell()
            
            // Giriş Section - Empty
            VStack { Spacer() }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            
            // Çıkış Section - Gram and Adet
            HStack(spacing: 0) {
                VStack {
                    VStack(spacing: 4) {
                        Text("Gram")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NomisTheme.blackNight)
                        
                        Rectangle()
                            .fill(NomisTheme.borderGray)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                        KilitNumberField(
                            value: item.cikisGram,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    VStack(spacing: 4) {
                        Text("Adet")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(NomisTheme.blackNight)
                        
                        Rectangle()
                            .fill(NomisTheme.borderGray)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                        KilitNumberField(
                            value: item.cikisAdet,
                            isEnabled: !isReadOnly,
                            onChange: { hasChanges = true }
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                            .foregroundColor(NomisTheme.darkText)
                            .disabled(isReadOnly)
                            .onChange(of: item.cikisAdet.wrappedValue) { _, _ in hasChanges = true }
                    }
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(maxWidth: .infinity)
            
            // Right side with Kilit title
            VStack {
                HStack {
                    Spacer()
                    Text("Kilit")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                    
                    if showAddButton && !isReadOnly {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(NomisTheme.primaryGreen)
                                .font(.caption)
                        }
                    } else if let onDelete = onDelete, !isReadOnly {
                        Button(action: onDelete) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    Spacer()
                }
            }
            .frame(width: 70)
            .luxuryTableCell()
        }
        .frame(height: NomisTheme.tableCellHeight)
    }
    
    // MARK: - Summary Section  
    private var summarySection: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                VStack { Spacer() }
                    .frame(width: 100)
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
                
                VStack {
                    Text("Fire")
                        .font(.system(size: NomisTheme.headlineSize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableHeader()
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Toplam Gr Row
            HStack(spacing: 0) {
                VStack {
                    Text("Toplam Gr")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(width: 100)
                .luxuryTableCell()
                
                VStack {
                    Text(String(format: "%.2f", calculateTotalGirisGram()))
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text(String(format: "%.2f", calculateTotalCikisGram()))
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text(String(format: "%.2f", calculateFireGram()))
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Dil Adet Row
            HStack(spacing: 0) {
                VStack {
                    Text("Dil Adet")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(width: 100)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateDilGirisAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateDilCikisAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateDilFireAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Kasa Adet Row
            HStack(spacing: 0) {
                VStack {
                    Text("Kasa Adet")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(width: 100)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateKasaGirisAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateKasaCikisAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.darkText)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
                
                VStack {
                    Text("\(calculateKasaFireAdet())")
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .luxuryTableCell()
            }
            .frame(height: NomisTheme.tableCellHeight)
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private func summaryRow(title: String, adet: Int, gram: Double) -> some View {
        HStack(spacing: 1) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            Text("\(gram, specifier: "%.2f")")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
            
            Text("\(adet)")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
            
            Text("\(adet)")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
            
            Spacer()
                .frame(width: 44)
        }
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.5))
    }
    
    // MARK: - Final Summary Section
    private var finalSummarySection: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                VStack {
                    Text("Detaylı Özet")
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
            }
            .frame(height: NomisTheme.tableCellHeight)
            
            // Data Rows
            luxuryDetailRow(title: "Toplam Kilit Adedi:", value: "\(calculateInputKilitAdet())")
            luxuryDetailRow(title: "Toplam Kilit Gramı:", value: String(format: "%.4f g", calculateTotalKilitGram()))
            luxuryDetailRow(title: "Ortalama Kilit Gramı:", value: String(format: "%.4f g", calculateAverageKilitGram()))
            luxuryDetailRow(title: "Ortalama Yay Gramı:", value: String(format: "%.4f g", calculateAverageYayGram()))
            luxuryDetailRow(title: "Ortalama Altın Gramı:", value: String(format: "%.4f g", calculateAverageAltinGram()))
            luxuryDetailRow(title: "Kilit Milyemi:", value: String(format: "%.4f (\(ayar)k)", calculateKilitMilyemi()))
        }
        .luxuryTableContainer()
        .padding(.horizontal, NomisTheme.contentSpacing)
    }
    
    private func luxuryDetailRow(title: String, value: String) -> some View {
        HStack(spacing: 0) {
            VStack {
                Text(title)
                    .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                    .foregroundColor(NomisTheme.darkText)
            }
            .frame(maxWidth: .infinity)
            .luxuryTableCell()
            
            VStack {
                Text(value)
                    .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(NomisTheme.primaryGreen)
            }
            .frame(maxWidth: .infinity)
            .luxuryTableCell()
        }
        .frame(height: NomisTheme.tableCellHeight)
    }
    
    private func detailSummaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(NomisTheme.text)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(NomisTheme.primary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !showingFinalSummary {
                Button("Tamamla") {
                    completeForm()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(NomisTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(NomisTheme.cornerRadius)
                .disabled(!canStartForm)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startFormIfNeeded() {
        if !hasStarted && canStartForm {
            startDate = Date()
            hasStarted = true
            hasChanges = true
        }
    }
    
    private func completeForm() {
        endDate = Date()
        showingFinalSummary = true
        hasChanges = true
    }
    
    private func saveForm() {
        let ayarValue = Int(ayar) ?? 0
        
        if let existingForm = form {
            existingForm.model = model
            existingForm.firma = firma
            existingForm.ayar = ayarValue
            existingForm.startedAt = hasStarted ? startDate : nil
            existingForm.endedAt = showingFinalSummary ? endDate : nil
            
            // Update items
            existingForm.kasaItems = kasaItems
            existingForm.dilItems = dilItems
            existingForm.yayItems = yayItems
            existingForm.kilitItems = kilitItems
        } else {
            let newForm = KilitToplamaForm(
                model: model,
                firma: firma,
                ayar: ayarValue
            )
            
            newForm.startedAt = hasStarted ? startDate : nil
            newForm.endedAt = showingFinalSummary ? endDate : nil
            newForm.kasaItems = kasaItems
            newForm.dilItems = dilItems
            newForm.yayItems = yayItems
            newForm.kilitItems = kilitItems
            
            modelContext.insert(newForm)
        }
        
        do {
            try modelContext.save()
            hasChanges = false
            dismiss()
        } catch {
            // Silent fail
        }
    }
    
    // MARK: - Calculation Functions
    private func calculateInputKilitAdet() -> Int {
        // İlk tabloda girilen toplam kilit adedi (giriş + çıkış)
        return Int(kilitItems.reduce(0) { $0 + ($1.girisAdet ?? 0) + ($1.cikisAdet ?? 0) })
    }
    
    private func calculateTotalKilitAdet() -> Int {
        // 1 kasa + 1 dil = 1 kilit mantığı
        let kasaAdet = kasaItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) }
        let dilAdet = dilItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) }
        
        // En az olanı kilit adedini belirler (kasa ve dil eşleşmesi gerekiyor)
        return min(Int(kasaAdet), Int(dilAdet))
    }
    
    private func calculateTotalKilitGram() -> Double {
        return kilitItems.reduce(0) { $0 + ($1.girisGram ?? 0) + ($1.cikisGram ?? 0) }
    }
    
    private func calculateAverageKilitGram() -> Double {
        let totalAdet = calculateInputKilitAdet()
        let totalGram = calculateTotalKilitGram()
        return totalAdet > 0 ? totalGram / Double(totalAdet) : 0
    }
    
    private func calculateAverageYayGram() -> Double {
        let girisYayGram = yayItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let cikisYayGram = yayItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let fireYayGram = girisYayGram - cikisYayGram
        let kilitAdedi = calculateInputKilitAdet()
        return kilitAdedi > 0 ? fireYayGram / Double(kilitAdedi) : 0
    }
    
    private func calculateAverageAltinGram() -> Double {
        // Kasa ve dil giriş toplamı
        let kasaGirisGram = kasaItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let dilGirisGram = dilItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let toplamGirisGram = kasaGirisGram + dilGirisGram
        
        // Kasa ve dil çıkış toplamı  
        let kasaCikisGram = kasaItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let dilCikisGram = dilItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let toplamCikisGram = kasaCikisGram + dilCikisGram
        
        // Fire hesabı
        let fireAltinGram = toplamGirisGram - toplamCikisGram
        let kilitAdedi = calculateInputKilitAdet()
        return kilitAdedi > 0 ? fireAltinGram / Double(kilitAdedi) : 0
    }
    
    private func calculateKilitMilyemi() -> Double {
        // Giriş yapılan yay gramından çıkış yapılan yay gramını çıkar
        let girisYayGram = yayItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let cikisYayGram = yayItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let yayFire = girisYayGram - cikisYayGram
        
        // Toplam kilit gramı
        let toplamKilitGram = calculateTotalKilitGram()
        
        // Yay fire / toplam kilit gramı
        let milyemOrani = toplamKilitGram > 0 ? yayFire / toplamKilitGram : 0
        
        // 1 çıkar
        let milyemEksi1 = milyemOrani - 1
        
        // Ayar değerine göre çarp
        let ayarValue = Int(ayar) ?? 14
        let ayarCarpani: Double
        switch ayarValue {
        case 14: ayarCarpani = 585
        case 18: ayarCarpani = 750
        case 21: ayarCarpani = 875
        case 22: ayarCarpani = 916
        default: ayarCarpani = 585 // Default 14 ayar
        }
        
        let sonuc = milyemEksi1 * ayarCarpani
        
        // Negatif ise pozitife çevir (mutlak değer)
        return abs(sonuc)
    }
    
    private func calculateTotalGirisGram() -> Double {
        let kasaGram = kasaItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let dilGram = dilItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let yayGram = yayItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let kilitGram = kilitItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        return kasaGram + dilGram + yayGram + kilitGram
    }
    
    private func calculateTotalFireGram() -> Double {
        let kasaFire = calculateKasaFireGram()
        let dilFire = calculateDilFireGram()
        return kasaFire + dilFire
    }
    
    private func calculateKasaFireGram() -> Double {
        return kasaItems.reduce(0) { total, item in
            total + ((item.girisGram ?? 0) - (item.cikisGram ?? 0))
        }
    }
    
    private func calculateKasaFireAdet() -> Int {
        let kasaFire = Int(kasaItems.reduce(0) { total, item in
            total + ((item.girisAdet ?? 0) - (item.cikisAdet ?? 0))
        })
        let inputKilitAdet = calculateInputKilitAdet()
        return kasaFire - inputKilitAdet
    }
    
    private func calculateDilFireGram() -> Double {
        return dilItems.reduce(0) { total, item in
            total + ((item.girisGram ?? 0) - (item.cikisGram ?? 0))
        }
    }
    
    private func calculateDilFireAdet() -> Int {
        let dilFire = Int(dilItems.reduce(0) { total, item in
            total + ((item.girisAdet ?? 0) - (item.cikisAdet ?? 0))
        })
        let inputKilitAdet = calculateInputKilitAdet()
        return dilFire - inputKilitAdet
    }
    
    // New calculation functions for summary table
    private func calculateTotalCikisGram() -> Double {
        let kasaGram = kasaItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let dilGram = dilItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let yayGram = yayItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let kilitGram = kilitItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        return kasaGram + dilGram + yayGram + kilitGram
    }
    
    private func calculateFireGram() -> Double {
        return calculateTotalGirisGram() - calculateTotalCikisGram()
    }
    
    private func calculateDilGirisAdet() -> Int {
        return Int(dilItems.reduce(0) { $0 + ($1.girisAdet ?? 0) })
    }
    
    private func calculateDilCikisAdet() -> Int {
        return Int(dilItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) })
    }
    
    private func calculateKasaGirisAdet() -> Int {
        return Int(kasaItems.reduce(0) { $0 + ($1.girisAdet ?? 0) })
    }
    
    private func calculateKasaCikisAdet() -> Int {
        return Int(kasaItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) })
    }
}

#Preview {
    KilitEditorView()
        .environmentObject(AuthenticationManager())
}