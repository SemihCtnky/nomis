import SwiftUI
import SwiftData

// Protocol for cards that have IslemSatiri arrays
protocol IslemKartiProtocol {
    var satirlar: [IslemSatiri] { get }
}

struct DailyOperationsEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    // SwiftData Query ile satırları direkt çek ve sırala
    @Query private var allTezgahSatirlar: [TezgahSatiri]
    @Query private var allIslemSatirlar: [IslemSatiri]
    
    @State private var form: YeniGunlukForm
    @State private var isNewForm: Bool
    @State private var isReadOnly: Bool
    @State private var hasChanges = false
    @State private var showingDateAlert = false
    @State private var alertMessage = ""
    @State private var autoSaveTimer: Timer?
    @State private var showingPasswordAlert = false
    @State private var showingWeeklyFinishMenu = false
    @State private var showingWeeklyFinishAlert = false
    @State private var showingCancelAuth = false
    
    // Focus management for Tezgah cards
    @FocusState private var focusedTezgahField: TezgahFocusedField?
    
    enum TezgahFocusedField: Hashable {
        case giris(cardIndex: Int, satirIndex: Int)
        case solAciklama(cardIndex: Int, satirIndex: Int)
        case cikis(cardIndex: Int, satirIndex: Int)
        case sagAciklama(cardIndex: Int, satirIndex: Int)
    }
    
    // Tezgah onay mekanizması için state
    @State private var showingTezgahConfirmation = false
    @State private var confirmationType: TezgahConfirmationType?
    @State private var pendingTezgahSatir: TezgahSatiri?
    @State private var pendingTezgahIndex: Int?
    
    enum TezgahConfirmationType {
        case giris
        case cikis
    }
    
    // Local arrays for stable sorting - SwiftData array sıralaması sorununu tamamen bypass et
    @State private var localTezgahSatirlar1: [TezgahSatiri] = []
    @State private var localTezgahSatirlar2: [TezgahSatiri] = []
    @State private var localCilaSatirlar: [IslemSatiri] = []
    @State private var localOcakSatirlar: [IslemSatiri] = []
    @State private var localPatlatmaSatirlar: [IslemSatiri] = []
    @State private var localTamburSatirlar: [IslemSatiri] = []
    @State private var localMakineKesmeSatirlar: [IslemSatiri] = []
    @State private var localTestereKesmeSatirlar: [IslemSatiri] = []
    
    // Current card tracking - hangi kartın aktif olduğunu takip et
    @State private var currentGunVerisi: GunlukGunVerisi?
    
    // SwiftData bug'unu bypass etmek için tamamen local yönetim
    @State private var useLocalOnly: Bool = true
    
    init(form: YeniGunlukForm? = nil, isReadOnly: Bool = false) {
        if let existingForm = form {
            self._form = State(initialValue: existingForm)
            self._isNewForm = State(initialValue: false)
            self._isReadOnly = State(initialValue: isReadOnly)
        } else {
            // Temporary form oluştur - DB'ye kaydetme!
            let tempForm = YeniGunlukForm()
            self._form = State(initialValue: tempForm)
            self._isNewForm = State(initialValue: true)
            self._isReadOnly = State(initialValue: false)
        }
    }
    
    private var canSaveForm: Bool {
        // Her zaman kaydedilebilir (auto-save ile çelişmesin diye)
        return true
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Günlük veriler (Pazartesi - Cuma) - Stable sıralama için sorted
                    ForEach(Array(form.gunlukVeriler.sorted(by: { $0.tarih < $1.tarih }).enumerated()), id: \.element.id) { index, gunVerisi in
                        VStack(spacing: 0) {
                            // Gün başlığı
                            gunBasligi(for: gunVerisi)
                            
                            // Kartlar - Yatay scroll
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 16) {
                                    // Tezgah kartları (ikişer tane)
                                    tezgahCard(for: gunVerisi, cardIndex: 1)
                                    tezgahCard(for: gunVerisi, cardIndex: 2)
                                    
                                    // Cila kartı (birer tane)
                                    cilaCard(for: gunVerisi)
                                    
                                    // Ocak kartı (birer tane)
                                    ocakCard(for: gunVerisi)
                                    
                                    // Patlatma kartı (birer tane)
                                    patlatmaCard(for: gunVerisi)
                                    
                                    // Tambur kartı (birer tane)
                                    tamburCard(for: gunVerisi)
                                    
                                    // Makine Kesme kartı (sonda, birer tane) 
                                    makineKesmeCard(for: gunVerisi, cardIndex: 1)
                                    
                                    // Testere Kesme kartı (sonda, birer tane)
                                    testereKesmeCard(for: gunVerisi, cardIndex: 1)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)
                                .padding(.top, 20)
                            }
                        }
                        
                        // Haftalık Fire Özeti - sadece son gün (Cuma) için
                        if index == form.gunlukVeriler.count - 1 || isFriday(gunVerisi.tarih) {
                            VStack(spacing: 16) {
                                Spacer()
                                    .frame(height: 40)
                                
                                WeeklyFireSummaryTable(fireData: calculateWeeklyFireSummary())
                                    .padding(.horizontal, 16)
                                
                                Spacer()
                                    .frame(height: 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNewForm ? "Yeni Günlük İşlemler" : "Günlük İşlemler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        if isNewForm {
                            requestPasswordForCancel()
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isReadOnly {
                            Button("Kaydet") {
                                saveForm()
                            }
                            .disabled(!canSaveForm)
                            
                            // 3 nokta menü butonu
                            Button(action: {
                                showingWeeklyFinishMenu = true
                            }) {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(NomisTheme.primary)
                            }
                            .confirmationDialog("Hafta İşlemleri", isPresented: $showingWeeklyFinishMenu) {
                                Button("Haftayı Bitir") {
                                    showingWeeklyFinishAlert = true
                                }
                                Button("İptal", role: .cancel) {}
                            }
                        }
                    }
                }
            }
        }
        .alert("Tarih Bilgisi", isPresented: $showingDateAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingCancelAuth) {
            AdminAuthSheet(
                title: "İptal İşlemi",
                message: "Formu iptal etmek için admin şifresini girin.",
                onSuccess: cancelFormWithAuth
            )
        }
        .sheet(isPresented: $showingWeeklyFinishAlert) {
            WeeklyFinishSheet(
                isPresented: $showingWeeklyFinishAlert,
                onFinish: { 
                    finishWeeklyForm()
                }
            )
        }
        .alert("İşlem Onayı", isPresented: $showingTezgahConfirmation) {
            Button("Evet") {
                // Değerler kalır
                confirmTezgahEntry()
            }
            Button("Hayır", role: .destructive) {
                // Değerleri sil
                cancelTezgahEntry()
            }
        } message: {
            Text("Bu işlemi yapmak istediğinizden emin misiniz?")
        }
        .onChange(of: focusedTezgahField) { oldValue, newValue in
            // Focus değiştiğinde onay kontrolü yap
            handleFocusChange(from: oldValue, to: newValue)
        }
        .onAppear {
            if !isNewForm {
                // Mevcut form için orderIndex kontrolü yap
                ensureOrderIndexForExistingRows()
                
                // ❌ sortAllCardRows() KALDIRILDI - Satırların yerini değiştiriyor
                // ForEach zaten orderIndex'e göre sıralı gösteriyor
                
                // Değişiklikleri kaydet ki orderIndex'ler kalıcı olsun
                do {
                    try modelContext.save()
                } catch {
                    print("OrderIndex kaydetme hatası: \(error)")
                }
                // Local array'leri sync et - SwiftData array sıralaması sorununu bypass et
                if let firstGunVerisi = form.gunlukVeriler.first {
                    syncLocalArrays(for: firstGunVerisi)
                }
            }
        }
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func ensureCilaKarti(for gunVerisi: GunlukGunVerisi) {
        if gunVerisi.cilaKarti == nil {
            gunVerisi.cilaKarti = CilaKarti()
        }
    }
    
    private func ensureOcakKarti(for gunVerisi: GunlukGunVerisi) {
        if gunVerisi.ocakKarti == nil {
            gunVerisi.ocakKarti = OcakKarti()
        }
    }
    
    private func ensurePatlatmaKarti(for gunVerisi: GunlukGunVerisi) {
        if gunVerisi.patlatmaKarti == nil {
            gunVerisi.patlatmaKarti = PatlatmaKarti()
        }
    }
    
    private func ensureTamburKarti(for gunVerisi: GunlukGunVerisi) {
        if gunVerisi.tamburKarti == nil {
            gunVerisi.tamburKarti = TamburKarti()
        }
    }
    
    private func formatDate(_ date: Date, gunAdi: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMMM yyyy"
        let dateString = formatter.string(from: date)
        return "\(gunAdi.capitalized), \(dateString)"
    }
    
    // MARK: - Gün Başlığı
    private func gunBasligi(for gunVerisi: GunlukGunVerisi) -> some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(NomisTheme.goldAccent)
                .frame(height: 2)
            
            HStack {
                Text(formatDate(gunVerisi.tarih, gunAdi: gunVerisi.gunAdi))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(NomisTheme.primary)
                    .padding(.vertical, 12)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Rectangle()
                .fill(NomisTheme.goldAccent)
                .frame(height: 2)
        }
    }
    
    // MARK: - Tezgah Kartı
    private func tezgahCard(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> some View {
        VStack(spacing: 0) {
            // Header
            Text("TEZGAH \(cardIndex)")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Ayar alanı
            if let tezgahKarti = getTezgahKarti(for: gunVerisi, cardIndex: cardIndex) {
                HStack {
                    Text("Ayar:")
                        .font(.system(size: NomisTheme.bodySize, weight: .semibold))
                        .foregroundColor(NomisTheme.secondaryText)
                        .frame(width: 60, alignment: .leading)
                    
                    Picker("Ayar", selection: Binding(
                        get: { tezgahKarti.ayar ?? 0 },
                        set: { newValue in
                            tezgahKarti.ayar = newValue == 0 ? nil : newValue
                            triggerAutoSave()
                        }
                    )) {
                        Text("Seçiniz").tag(0)
                        Text("14").tag(14)
                        Text("18").tag(18)
                        Text("21").tag(21)
                        Text("22").tag(22)
                    }
                    .disabled(!(authManager.currentUsername == "admin") || isReadOnly)
                    .font(.system(size: NomisTheme.headlineSize, weight: .bold))
                    .foregroundColor(NomisTheme.prominentText)
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(NomisTheme.lightCream)
                    .overlay(
                        Rectangle()
                            .stroke(NomisTheme.primaryGreen, lineWidth: 2)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            
            // Tablo
            tezgahTable(for: gunVerisi, cardIndex: cardIndex)
            
            // Fire section
            tezgahFireSection(for: gunVerisi, cardIndex: cardIndex)
        }
        .luxuryTableContainer()
        .frame(width: 750)
        .onAppear {
            ensureTezgahKarti(for: gunVerisi, cardIndex: cardIndex)
        }
    }
    
    private func tezgahTable(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> some View {
        VStack(spacing: 0) {
            // Stable Header
            StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Açıklama"])
            
            // ULTRA STABLE ROWS - HİÇBİR ŞEKILDE YER DEĞİŞTİRMEZ
            if let tezgahKarti = getTezgahKarti(for: gunVerisi, cardIndex: cardIndex) {
                // OrderIndex'e göre sıralı ama SÜREKLİ sabit snapshot
                let stableSatirlar = tezgahKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
                
                ForEach(Array(stableSatirlar.enumerated()), id: \.element.id) { index, satir in
                    tezgahTableRow(satir: satir, index: index, cardIndex: cardIndex)
                        .id(satir.id) // UUID bazlı stable ID
                }
                
                // Toplam satırı
                tezgahTotalRow(for: tezgahKarti)
                
                // Stable Add Row Button
                if !isReadOnly && authManager.currentUsername == "admin" {
                    StableAddRowButton(title: "Satır Ekle") {
                        addTezgahRow(to: tezgahKarti)
                    }
                }
            }
        }
        .background(NomisTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
        )
        .animation(.none, value: UUID()) // Disable table animations completely
    }
    
    private func tezgahTableRow(satir: TezgahSatiri, index: Int, cardIndex: Int) -> some View {
        HStack(spacing: 0) {
            // Açıklama (Giriş) - Giriş değeri girilmedikçe disabled
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaGiris },
                    set: { newValue in
                        satir.aciklamaGiris = newValue
                        if !newValue.isEmpty && satir.aciklamaGirisTarihi == nil {
                            satir.aciklamaGirisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .focused($focusedTezgahField, equals: .solAciklama(cardIndex: cardIndex, satirIndex: index))
                .disabled(isReadOnly || authManager.currentUsername != "admin" || !hasGirisValue(satir))
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaGiris.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaGirisTarihi {
                            alertMessage = "Giriş açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
            
            // Giriş
            TextField("0", value: Binding(
                get: { satir.girisValue },
                set: { newValue in
                    satir.girisValue = newValue
                    if (newValue ?? 0) > 0 && satir.aciklamaGirisTarihi == nil {
                        satir.aciklamaGirisTarihi = Date()
                    }
                    triggerAutoSave()
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .focused($focusedTezgahField, equals: .giris(cardIndex: cardIndex, satirIndex: index))
            .disabled(isReadOnly || authManager.currentUsername != "admin")
            .multilineTextAlignment(.center)
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
            .foregroundColor(NomisTheme.darkText)
            .onSubmit {
                // Giriş değeri girildikten sonra hemen SOLUNDAKİ açıklamaya geç
                if hasGirisValue(satir) {
                    focusedTezgahField = .solAciklama(cardIndex: cardIndex, satirIndex: index)
                }
            }
            .luxuryTableCell()
            
            // Çıkış
            TextField("0", value: Binding(
                get: { satir.cikisValue },
                set: { newValue in
                    satir.cikisValue = newValue
                    if (newValue ?? 0) > 0 && satir.aciklamaCikisTarihi == nil {
                        satir.aciklamaCikisTarihi = Date()
                    }
                    triggerAutoSave()
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .focused($focusedTezgahField, equals: .cikis(cardIndex: cardIndex, satirIndex: index))
            .disabled(isReadOnly || authManager.currentUsername != "admin")
            .multilineTextAlignment(.center)
            .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
            .foregroundColor(NomisTheme.darkText)
            .onSubmit {
                // Çıkış değeri girildikten sonra sağ açıklamaya geç
                if hasCikisValue(satir) {
                    focusedTezgahField = .sagAciklama(cardIndex: cardIndex, satirIndex: index)
                }
            }
            .luxuryTableCell()
            
            // Açıklama (Çıkış) - Çıkış değeri girilmedikçe disabled
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaCikis },
                    set: { newValue in
                        satir.aciklamaCikis = newValue
                        if !newValue.isEmpty && satir.aciklamaCikisTarihi == nil {
                            satir.aciklamaCikisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .focused($focusedTezgahField, equals: .sagAciklama(cardIndex: cardIndex, satirIndex: index))
                .disabled(isReadOnly || authManager.currentUsername != "admin" || !hasCikisValue(satir))
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaCikis.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaCikisTarihi {
                            alertMessage = "Çıkış açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
        }
    }
    
    // Helper functions for checking if values are entered
    private func hasGirisValue(_ satir: TezgahSatiri) -> Bool {
        return (satir.girisValue ?? 0) > 0
    }
    
    private func hasCikisValue(_ satir: TezgahSatiri) -> Bool {
        return (satir.cikisValue ?? 0) > 0
    }
    
    private func tezgahTotalRow(for tezgahKarti: TezgahKarti) -> some View {
        HStack(spacing: 0) {
            Text("Toplam")
                .font(.system(size: NomisTheme.bodySize, weight: .bold))
                .luxuryTableCell()
            
            Text("\(tezgahKarti.toplamGiris, specifier: "%.2f")")
                .font(.system(size: NomisTheme.bodySize, weight: .bold))
                .luxuryTableCell()
            
            Text("\(tezgahKarti.toplamCikis, specifier: "%.2f")")
                .font(.system(size: NomisTheme.bodySize, weight: .bold))
                .luxuryTableCell()
            
            Text("Toplam")
                .font(.system(size: NomisTheme.bodySize, weight: .bold))
                .luxuryTableCell()
        }
    }
    
    private func tezgahFireSection(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> some View {
        VStack(spacing: 0) {
            if let tezgahKarti = getTezgahKarti(for: gunVerisi, cardIndex: cardIndex) {
                VStack {
                    Text("FIRE")
                        .font(.system(size: NomisTheme.bodySize, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("\(tezgahKarti.fire, specifier: "%.2f") gr")
                        .font(.system(size: NomisTheme.bodySize))
                        .foregroundColor(.red)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Diğer Kartlar (Basit İmplementasyon)
    private func cilaCard(for gunVerisi: GunlukGunVerisi) -> some View {
        VStack(spacing: 0) {
            Text("CİLA")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası
            Spacer()
                .frame(height: 10)
            
            if let cilaKarti = gunVerisi.cilaKarti {
                // Direkt sıralama - SwiftData array sıralaması sorununu bypass et
                let sortedSatirlar = cilaKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
                
                // Ayar sütunlu tablo - direkt ForEach kullan
                VStack(spacing: 0) {
                    // Stable Header (6 sütun - açıklama + ayar sütunuyla birlikte)
                    StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
                    
                    // Direkt ForEach ile sıralı satırlar - SwiftData array sıralaması sorununu bypass et
                    ForEach(Array(sortedSatirlar.enumerated()), id: \.element.id) { index, satir in
                        StableIslemTableRow(
                            satir: satir, 
                            index: index, 
                            ayar: cilaKarti.ayar ?? 14,
                            isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                            allowExpandableCikis: false, // Cila kartı için çıkış genişletme kapalı
                            showAyarColumn: true, // Bu kartlarda ayar sütunu var
                            onAddRowAfter: nil // Bu kartlarda çıkış genişletme yok
                        )
                    }
                    
                    // Stable Add Row Button
                    if !isReadOnly && authManager.currentUsername == "admin" {
                        StableAddRowButton(title: "Satır Ekle") {
                            addCilaRow(to: cilaKarti)
                        }
                    }
                }
                .background(NomisTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
                )
                .animation(.none, value: UUID()) // Disable table animations completely
                
                // Fire Summary Table
                let fireData = calculateFireByAyar(for: cilaKarti.satirlar)
                FireSummaryTable(fireData: fireData)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
            }
        }
        .luxuryTableContainer()
        .frame(width: 750) // Ayar sütunu için daha geniş
        .onAppear {
            ensureCilaKarti(for: gunVerisi)
        }
    }
    
    private func ocakCard(for gunVerisi: GunlukGunVerisi) -> some View {
        VStack(spacing: 0) {
            Text("OCAK")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası
            Spacer()
                .frame(height: 10)
            
            if let ocakKarti = gunVerisi.ocakKarti {
                // Direkt sıralama - SwiftData array sıralaması sorununu bypass et
                let sortedSatirlar = ocakKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
                
                // Ayar sütunlu tablo - direkt ForEach kullan
                VStack(spacing: 0) {
                    // Stable Header (6 sütun - açıklama + ayar sütunuyla birlikte)
                    StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
                    
                    // Direkt ForEach ile sıralı satırlar - SwiftData array sıralaması sorununu bypass et
                    ForEach(Array(sortedSatirlar.enumerated()), id: \.element.id) { index, satir in
                        StableIslemTableRow(
                            satir: satir, 
                            index: index, 
                            ayar: ocakKarti.ayar ?? 14,
                            isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                            allowExpandableCikis: false, // Ocak kartı için çıkış genişletme kapalı
                            showAyarColumn: true, // Bu kartlarda ayar sütunu var
                            onAddRowAfter: nil // Bu kartlarda çıkış genişletme yok
                        )
                    }
                    
                    // Stable Add Row Button
                    if !isReadOnly && authManager.currentUsername == "admin" {
                        StableAddRowButton(title: "Satır Ekle") {
                            addOcakRow(to: ocakKarti)
                        }
                    }
                }
                .background(NomisTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
                )
                .animation(.none, value: UUID()) // Disable table animations completely
                
                // Fire Summary Table
                let fireData = calculateFireByAyar(for: ocakKarti.satirlar)
                FireSummaryTable(fireData: fireData)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
            }
        }
        .luxuryTableContainer()
        .frame(width: 750)
        .onAppear {
            ensureOcakKarti(for: gunVerisi)
        }
    }
    
    private func patlatmaCard(for gunVerisi: GunlukGunVerisi) -> some View {
        VStack(spacing: 0) {
            Text("PATLATMA")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası
            Spacer()
                .frame(height: 10)
            
            if let patlatmaKarti = gunVerisi.patlatmaKarti {
                // Ayar sütunlu tablo
                cardTableWithAyar(
                    satirlar: patlatmaKarti.satirlar, 
                    ayar: Binding(
                        get: { patlatmaKarti.ayar ?? 14 },
                        set: { newValue in
                            patlatmaKarti.ayar = newValue
                            triggerAutoSave()
                        }
                    ),
                    addAction: {
                        addPatlatmaRow(to: patlatmaKarti)
                    }
                )
                
                // Fire Summary Table
                let fireData = calculateFireByAyar(for: patlatmaKarti.satirlar)
                FireSummaryTable(fireData: fireData)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
            }
        }
        .luxuryTableContainer()
        .frame(width: 750)
        .onAppear {
            ensurePatlatmaKarti(for: gunVerisi)
        }
    }
    
    private func tamburCard(for gunVerisi: GunlukGunVerisi) -> some View {
        VStack(spacing: 0) {
            Text("TAMBUR")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası
            Spacer()
                .frame(height: 10)
            
            if let tamburKarti = gunVerisi.tamburKarti {
                // Ayar sütunlu tablo
                cardTableWithAyar(
                    satirlar: tamburKarti.satirlar, 
                    ayar: Binding(
                        get: { tamburKarti.ayar ?? 14 },
                        set: { newValue in
                            tamburKarti.ayar = newValue
                            triggerAutoSave()
                        }
                    ),
                    addAction: {
                        addTamburRow(to: tamburKarti)
                    }
                )
                
                // Fire Summary Table
                let fireData = calculateFireByAyar(for: tamburKarti.satirlar)
                FireSummaryTable(fireData: fireData)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
            }
        }
        .luxuryTableContainer()
        .frame(width: 750)
        .onAppear {
            ensureTamburKarti(for: gunVerisi)
        }
    }
    
    private func makineKesmeCard(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> some View {
        VStack(spacing: 0) {
            Text("MAKİNE KESME")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası (Cila kartı gibi)
            Spacer()
                .frame(height: 10)
            
            if let makineKesmeKarti = getMakineKesmeKarti(for: gunVerisi, cardIndex: cardIndex) {
                // Makine Kesme tablosu (expandable çıkış ile)
                VStack(spacing: 0) {
                    // Stable Header
                    StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
                    
                    // Stable Rows
                    StableTableView(rows: makineKesmeKarti.satirlar) { satir, index in
                        AnyView(
                            StableIslemTableRow(
                                satir: satir, 
                                index: index, 
                                ayar: makineKesmeKarti.ayar,
                                isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                                allowExpandableCikis: true, // Makine Kesme için çıkış genişletme açık
                                showAyarColumn: true, // Makine Kesme için ayar sütunu açık
                                onAddRowAfter: nil // Çıkış genişletme sistemi için gerek yok
                            )
                        )
                    }
                    
                    // Stable Add Row Button
                    if !isReadOnly && authManager.currentUsername == "admin" {
                        StableAddRowButton(title: "Satır Ekle") {
                            addMakineKesmeRow(to: makineKesmeKarti)
                        }
                    }
                    
                    // Fire Summary Table
                    let fireData = calculateFireByAyar(for: makineKesmeKarti.satirlar)
                    FireSummaryTable(fireData: fireData)
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                }
                .background(NomisTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
                )
                .animation(.none, value: UUID()) // Disable table animations completely
            }
        }
        .luxuryTableContainer()
        .frame(width: 750) // Cila kartı ile aynı genişlik
        .onAppear {
            ensureMakineKesmeKarti(for: gunVerisi, cardIndex: cardIndex)
        }
    }
    
    private func testereKesmeCard(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> some View {
        VStack(spacing: 0) {
            Text("TESTERE KESME")
                .font(.headline.weight(.bold))
                .foregroundColor(NomisTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NomisTheme.lightCream)
                .luxuryTableHeader()
            
            // Minimal spacing - header ile tablo arası (Cila kartı gibi)
            Spacer()
                .frame(height: 10)
            
            if let testereKesmeKarti = getTestereKesmeKarti(for: gunVerisi, cardIndex: cardIndex) {
                // Testere Kesme tablosu (expandable çıkış ile)
                VStack(spacing: 0) {
                    // Stable Header
                    StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
                    
                    // Stable Rows
                    StableTableView(rows: testereKesmeKarti.satirlar) { satir, index in
                        AnyView(
                            StableIslemTableRow(
                                satir: satir, 
                                index: index, 
                                ayar: testereKesmeKarti.ayar,
                                isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                                allowExpandableCikis: true, // Testere Kesme için çıkış genişletme açık
                                showAyarColumn: true, // Testere Kesme için ayar sütunu açık
                                onAddRowAfter: nil // Çıkış genişletme sistemi için gerek yok
                            )
                        )
                    }
                    
                    // Stable Add Row Button
                    if !isReadOnly && authManager.currentUsername == "admin" {
                        StableAddRowButton(title: "Satır Ekle") {
                            addTestereKesmeRow(to: testereKesmeKarti)
                        }
                    }
                    
                    // Fire Summary Table
                    let fireData = calculateFireByAyar(for: testereKesmeKarti.satirlar)
                    FireSummaryTable(fireData: fireData)
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                }
                .background(NomisTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
                )
                .animation(.none, value: UUID()) // Disable table animations completely
            }
        }
        .luxuryTableContainer()
        .frame(width: 750) // Cila kartı ile aynı genişlik
        .onAppear {
            ensureTestereKesmeKarti(for: gunVerisi, cardIndex: cardIndex)
        }
    }
    
    // MARK: - Row Addition Functions
    
    private func addMakineKesmeRow(to makineKesmeKarti: MakineKesmeKarti) {
        let newRow = IslemSatiri()
        
        // Animasyon olmadan, direkt ekle
        makineKesmeKarti.satirlar.append(newRow)
        
        // ❌ SORT KALDIRILDI - Satırların yerini değiştiriyor, orderIndex zaten var
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Makine Kesme satır ekleme hatası: \(error)")
        }
    }
    
    private func addTestereKesmeRow(to testereKesmeKarti: TestereKesmeKarti) {
        let newRow = IslemSatiri()
        
        // Animasyon olmadan, direkt ekle
        testereKesmeKarti.satirlar.append(newRow)
        
        // ❌ SORT KALDIRILDI - Satırların yerini değiştiriyor, orderIndex zaten var
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Testere Kesme satır ekleme hatası: \(error)")
        }
    }
    
    // MARK: - Helper Functions for Multiple Cards
    
    private func getTezgahKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> TezgahKarti? {
        switch cardIndex {
        case 1:
            return gunVerisi.tezgahKarti1
        case 2:
            return gunVerisi.tezgahKarti2
        default:
            return nil
        }
    }
    
    private func ensureTezgahKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) {
        switch cardIndex {
        case 1:
            if gunVerisi.tezgahKarti1 == nil {
                gunVerisi.tezgahKarti1 = TezgahKarti()
            }
        case 2:
            if gunVerisi.tezgahKarti2 == nil {
                gunVerisi.tezgahKarti2 = TezgahKarti()
            }
        default:
            break
        }
    }
    
    private func getMakineKesmeKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> MakineKesmeKarti? {
        // Sadece cardIndex 1 destekleniyor (tek kart)
        return cardIndex == 1 ? gunVerisi.makineKesmeKarti1 : nil
    }
    
    private func getTestereKesmeKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) -> TestereKesmeKarti? {
        // Sadece cardIndex 1 destekleniyor (tek kart)
        return cardIndex == 1 ? gunVerisi.testereKesmeKarti1 : nil
    }
    
    private func ensureMakineKesmeKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) {
        // Sadece cardIndex 1 destekleniyor (tek kart)
        if cardIndex == 1 && gunVerisi.makineKesmeKarti1 == nil {
            gunVerisi.makineKesmeKarti1 = MakineKesmeKarti()
        }
    }
    
    private func ensureTestereKesmeKarti(for gunVerisi: GunlukGunVerisi, cardIndex: Int) {
        // Sadece cardIndex 1 destekleniyor (tek kart)
        if cardIndex == 1 && gunVerisi.testereKesmeKarti1 == nil {
            gunVerisi.testereKesmeKarti1 = TestereKesmeKarti()
        }
    }
    
    // MARK: - Yardımcı View'lar
    
    private func cardTable(satirlar: [IslemSatiri], ayar: Binding<Int>, addAction: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            // Stable Header (6 sütun - açıklama + ayar sütunuyla birlikte)
            StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
            
            // Stable Rows
            StableTableView(rows: satirlar) { satir, index in
                AnyView(
                    StableIslemTableRow(
                        satir: satir, 
                        index: index, 
                        ayar: ayar.wrappedValue,
                        isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                        allowExpandableCikis: false, // Default olarak expandable çıkış kapalı
                        showAyarColumn: true, // Artık ayar sütunu var
                        onAddRowAfter: nil // Bu kartlarda çıkış genişletme yok
                    )
                )
            }
            
            // Stable Add Row Button
            if !isReadOnly && authManager.currentUsername == "admin" {
                StableAddRowButton(title: "Satır Ekle", action: addAction)
            }
        }
        .background(NomisTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
        )
        .animation(.none, value: UUID()) // Disable table animations completely
    }
    
    private func cardTableWithAyar(satirlar: [IslemSatiri], ayar: Binding<Int>, addAction: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            // Stable Header (6 sütun - açıklama + ayar sütunuyla birlikte)
            StableTableHeader(columns: ["Açıklama", "Giriş", "Çıkış", "Fire", "Açıklama", "Ayar"])
            
            // Stable Rows
            StableTableView(rows: satirlar) { satir, index in
                AnyView(
                    StableIslemTableRow(
                        satir: satir, 
                        index: index, 
                        ayar: ayar.wrappedValue,
                        isReadOnly: isReadOnly || authManager.currentUsername != "admin",
                        allowExpandableCikis: false, // Cila, Ocak, Patlatma, Tambur kartları için çıkış genişletme kapalı
                        showAyarColumn: true, // Bu kartlarda ayar sütunu var
                        onAddRowAfter: nil // Bu kartlarda çıkış genişletme yok
                    )
                )
            }
            
            // Stable Add Row Button
            if !isReadOnly && authManager.currentUsername == "admin" {
                StableAddRowButton(title: "Satır Ekle", action: addAction)
            }
        }
        .background(NomisTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(NomisTheme.primaryGreen.opacity(0.8), lineWidth: 2)
        )
        .animation(.none, value: UUID()) // Disable table animations completely
    }
    
    private func cardTableRow(satir: IslemSatiri) -> some View {
        HStack(spacing: 0) {
            // Açıklama (Giriş)
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaGiris },
                    set: { newValue in
                        satir.aciklamaGiris = newValue
                        if !newValue.isEmpty && satir.aciklamaGirisTarihi == nil {
                            satir.aciklamaGirisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .disabled(isReadOnly || authManager.currentUsername != "admin")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaGiris.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaGirisTarihi {
                            alertMessage = "Giriş açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
            
            // Giriş
            NumberTableCell(
                value: Binding(
                    get: { satir.giris == 0 ? nil : satir.giris },
                    set: { newValue in
                        satir.giris = newValue ?? 0
                        triggerAutoSave()
                    }
                ),
                isEnabled: !isReadOnly && authManager.currentUsername == "admin"
            )
            .luxuryTableCell()
            
            // Çıkış
            NumberTableCell(
                value: Binding(
                    get: { satir.cikis == 0 ? nil : satir.cikis },
                    set: { newValue in
                        satir.cikis = newValue ?? 0
                        triggerAutoSave()
                    }
                ),
                isEnabled: !isReadOnly && authManager.currentUsername == "admin"
            )
            .luxuryTableCell()
            
            // Fire (otomatik hesaplanır)
            Text("\(satir.fire, specifier: "%.2f")")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(.red)
                .luxuryTableCell()
            
            // Açıklama (Çıkış)
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaCikis },
                    set: { newValue in
                        satir.aciklamaCikis = newValue
                        if !newValue.isEmpty && satir.aciklamaCikisTarihi == nil {
                            satir.aciklamaCikisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .disabled(isReadOnly || authManager.currentUsername != "admin")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaCikis.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaCikisTarihi {
                            alertMessage = "Çıkış açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
        }
    }
    
    private func cardTableRowWithAyar(satir: IslemSatiri, ayar: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            // Açıklama (Giriş)
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaGiris },
                    set: { newValue in
                        satir.aciklamaGiris = newValue
                        if !newValue.isEmpty && satir.aciklamaGirisTarihi == nil {
                            satir.aciklamaGirisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .disabled(isReadOnly || authManager.currentUsername != "admin")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaGiris.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaGirisTarihi {
                            alertMessage = "Giriş açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
            
            // Giriş
            NumberTableCell(
                value: Binding(
                    get: { satir.giris == 0 ? nil : satir.giris },
                    set: { newValue in
                        satir.giris = newValue ?? 0
                        triggerAutoSave()
                    }
                ),
                isEnabled: !isReadOnly && authManager.currentUsername == "admin"
            )
            .luxuryTableCell()
            
            // Çıkış
            NumberTableCell(
                value: Binding(
                    get: { satir.cikis == 0 ? nil : satir.cikis },
                    set: { newValue in
                        satir.cikis = newValue ?? 0
                        triggerAutoSave()
                    }
                ),
                isEnabled: !isReadOnly && authManager.currentUsername == "admin"
            )
            .luxuryTableCell()
            
            // Fire
            Text("\(satir.fire, specifier: "%.2f")")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(.red)
                .luxuryTableCell()
            
            // Açıklama (Çıkış)
            HStack(spacing: 4) {
                TextField("Açıklama", text: Binding(
                    get: { satir.aciklamaCikis },
                    set: { newValue in
                        satir.aciklamaCikis = newValue
                        if !newValue.isEmpty && satir.aciklamaCikisTarihi == nil {
                            satir.aciklamaCikisTarihi = Date()
                        }
                        triggerAutoSave()
                    }
                ))
                .disabled(isReadOnly || authManager.currentUsername != "admin")
                .font(.system(size: NomisTheme.bodySize))
                .foregroundColor(NomisTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                
                if !satir.aciklamaCikis.isEmpty {
                    Button(action: {
                        if let date = satir.aciklamaCikisTarihi {
                            alertMessage = "Çıkış açıklama tarihi:\n\(NomisFormatters.dateTimeFormatter.string(from: date))"
                            showingDateAlert = true
                        }
                    }) {
                        Text("?")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .disabled(isReadOnly || authManager.currentUsername != "admin")
                    .padding(.trailing, 4)
                } else {
                    Spacer()
                        .frame(width: 20) // Soru işareti için yer ayır
                }
            }
            .luxuryTableCell()
            
            // Ayar - Sadece o satır için
            Picker("Ayar", selection: Binding(
                get: { satir.ayar ?? 0 },
                set: { newValue in
                    satir.ayar = newValue == 0 ? nil : newValue
                    triggerAutoSave()
                }
            )) {
                Text("Seçiniz").tag(0)
                Text("14").tag(14)
                Text("18").tag(18)
                Text("21").tag(21)
                Text("22").tag(22)
            }
            .disabled(isReadOnly || authManager.currentUsername != "admin")
            .font(.system(size: NomisTheme.bodySize, weight: .semibold))
            .foregroundColor(NomisTheme.prominentText)
            .pickerStyle(MenuPickerStyle())
            .luxuryTableCell()
        }
    }
    
    // MARK: - Local Satır Ekleme Fonksiyonları (SwiftData Bug'unu Bypass Et)
    private func addCilaRowLocal(to cilaKarti: CilaKarti, gunVerisi: GunlukGunVerisi) {
        let newSatir = IslemSatiri()
        
        // SADECE Local array'e ekle - SwiftData'yı tamamen bypass et
        localCilaSatirlar.append(newSatir)
        // ❌ SORT KALDIRILDI - OrderIndex zaten var, ForEach'te sorted() kullanılıyor
        
        // SwiftData'ya EKLEME - sadece kaydetme için
        if !useLocalOnly {
            cilaKarti.satirlar.append(newSatir)
            // ❌ SORT KALDIRILDI - OrderIndex zaten var, ForEach'te sorted() kullanılıyor
            
            // Hemen save et
            do {
                try modelContext.save()
            } catch {
                print("Cila local satır ekleme hatası: \(error)")
            }
        }
    }
    
    // MARK: - Satır Ekleme Fonksiyonları
    private func addTezgahRow(to tezgahKarti: TezgahKarti) {
        let newSatir = TezgahSatiri()
        // UUID ve orderIndex zaten init'te benzersiz atanıyor
        
        // Direkt ekle - SORT YAPMA, orderIndex zaten unique ve sıralı
        tezgahKarti.satirlar.append(newSatir)
        
        // ❌ SORT KALDIRILDI - Satırların yerini değiştiriyor
        // ForEach zaten orderIndex'e göre sıralı gösteriyor
        
        // Hemen save et
        do {
            try modelContext.save()
        } catch {
            print("Tezgah satır ekleme hatası: \(error)")
        }
    }
    
    private func addCilaRow(to cilaKarti: CilaKarti) {
        let newSatir = IslemSatiri()
        // UUID ve orderIndex zaten init'te benzersiz atanıyor
        
        // Direkt ekle - SORT YAPMA
        cilaKarti.satirlar.append(newSatir)
        
        // ❌ SORT KALDIRILDI - Satırların yerini değiştiriyor
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Satır ekleme hatası: \(error)")
        }
    }
    
    private func addOcakRow(to ocakKarti: OcakKarti) {
        let newSatir = IslemSatiri()
        // UUID zaten init'te atanıyor, tekrar atlamaya gerek yok
        
        // Animasyon olmadan, direkt ekle
        ocakKarti.satirlar.append(newSatir)
        
        // ❌ SORT KALDIRILDI - OrderIndex zaten var, ForEach'te sorted() kullanılıyor
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Satır ekleme hatası: \(error)")
        }
    }
    
    private func addPatlatmaRow(to patlatmaKarti: PatlatmaKarti) {
        let newSatir = IslemSatiri()
        // UUID zaten init'te atanıyor, tekrar atlamaya gerek yok
        
        // Animasyon olmadan, direkt ekle
        patlatmaKarti.satirlar.append(newSatir)
        
        // ❌ SORT KALDIRILDI - OrderIndex zaten var, ForEach'te sorted() kullanılıyor
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Satır ekleme hatası: \(error)")
        }
    }
    
    private func addTamburRow(to tamburKarti: TamburKarti) {
        let newSatir = IslemSatiri()
        // UUID zaten init'te atanıyor, tekrar atlamaya gerek yok
        
        // Animasyon olmadan, direkt ekle
        tamburKarti.satirlar.append(newSatir)
        
        // ❌ SORT KALDIRILDI - OrderIndex zaten var, ForEach'te sorted() kullanılıyor
        
        // Hemen save et - row reordering'i engellemek için
        do {
            try modelContext.save()
        } catch {
            print("Satır ekleme hatası: \(error)")
        }
    }
    
    // MARK: - Helper Functions for Row Sorting
    
    // Local array sync fonksiyonları - SwiftData array sıralaması sorununu tamamen bypass et
    private func syncLocalArrays(for gunVerisi: GunlukGunVerisi) {
        currentGunVerisi = gunVerisi
        
        // SwiftData bug'unu bypass etmek için tamamen local yönetim
        if useLocalOnly {
            // Sadece local array'leri kullan - SwiftData'yı tamamen bypass et
            print("🚨 SwiftData bug'unu bypass ediyoruz - tamamen local yönetim")
            return
        }
        
        // Sadece aktif günlük veri için local array'leri sync et
        // Tezgah kartları
        if let tezgahKarti1 = gunVerisi.tezgahKarti1 {
            localTezgahSatirlar1 = tezgahKarti1.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        if let tezgahKarti2 = gunVerisi.tezgahKarti2 {
            localTezgahSatirlar2 = tezgahKarti2.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        
        // Diğer kartlar
        if let cilaKarti = gunVerisi.cilaKarti {
            localCilaSatirlar = cilaKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        if let ocakKarti = gunVerisi.ocakKarti {
            localOcakSatirlar = ocakKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        if let patlatmaKarti = gunVerisi.patlatmaKarti {
            localPatlatmaSatirlar = patlatmaKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        if let tamburKarti = gunVerisi.tamburKarti {
            localTamburSatirlar = tamburKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        
        // Makine ve Testere Kesme kartları
        if let makineKesmeKarti1 = gunVerisi.makineKesmeKarti1 {
            localMakineKesmeSatirlar = makineKesmeKarti1.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
        if let testereKesmeKarti1 = gunVerisi.testereKesmeKarti1 {
            localTestereKesmeSatirlar = testereKesmeKarti1.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        }
    }
    
    private func syncToSwiftData() {
        // Local array'lerden SwiftData'ya sync et
        for gunVerisi in form.gunlukVeriler {
            // Tezgah kartları
            if let tezgahKarti1 = gunVerisi.tezgahKarti1 {
                tezgahKarti1.satirlar = localTezgahSatirlar1
            }
            if let tezgahKarti2 = gunVerisi.tezgahKarti2 {
                tezgahKarti2.satirlar = localTezgahSatirlar2
            }
            
            // Diğer kartlar
            if let cilaKarti = gunVerisi.cilaKarti {
                cilaKarti.satirlar = localCilaSatirlar
            }
            if let ocakKarti = gunVerisi.ocakKarti {
                ocakKarti.satirlar = localOcakSatirlar
            }
            if let patlatmaKarti = gunVerisi.patlatmaKarti {
                patlatmaKarti.satirlar = localPatlatmaSatirlar
            }
            if let tamburKarti = gunVerisi.tamburKarti {
                tamburKarti.satirlar = localTamburSatirlar
            }
            
            // Makine ve Testere Kesme kartları
            if let makineKesmeKarti1 = gunVerisi.makineKesmeKarti1 {
                makineKesmeKarti1.satirlar = localMakineKesmeSatirlar
            }
            if let testereKesmeKarti1 = gunVerisi.testereKesmeKarti1 {
                testereKesmeKarti1.satirlar = localTestereKesmeSatirlar
            }
        }
    }
    
    // Query ile sıralı satırları çek - SwiftData array sıralaması sorununu bypass et
    private func getSortedTezgahSatirlar(for tezgahKarti: TezgahKarti) -> [TezgahSatiri] {
        return allTezgahSatirlar
            .filter { satir in
                // Bu tezgah kartına ait satırları filtrele
                tezgahKarti.satirlar.contains { $0.id == satir.id }
            }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    private func getSortedIslemSatirlar(for kart: any IslemKartiProtocol) -> [IslemSatiri] {
        return allIslemSatirlar
            .filter { satir in
                // Bu karta ait satırları filtrele
                kart.satirlar.contains { $0.id == satir.id }
            }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    private func ensureOrderIndexForExistingRows() {
        // SADECE orderIndex olmayan (eski) satırlar için orderIndex ata
        // ❌ ASLA SORT YAPMA - Satırların mevcut sırasını KORUMALI
        for gunVerisi in form.gunlukVeriler {
            // Multiple Tezgah kartları
            if let tezgahKarti1 = gunVerisi.tezgahKarti1 {
                // SADECE orderIndex == 0 olanları güncelle (eski satırlar)
                let hasOldRows = tezgahKarti1.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    // Mevcut sıraya göre orderIndex ata (SORT YAPMA!)
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
                    for (index, satir) in tezgahKarti1.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            if let tezgahKarti2 = gunVerisi.tezgahKarti2 {
                // SADECE orderIndex == 0 olanları güncelle (eski satırlar)
                let hasOldRows = tezgahKarti2.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    // Mevcut sıraya göre orderIndex ata (SORT YAPMA!)
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 100
                    for (index, satir) in tezgahKarti2.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            // Diğer kartlar - aynı mantık
            if let cilaKarti = gunVerisi.cilaKarti {
                let hasOldRows = cilaKarti.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 200
                    for (index, satir) in cilaKarti.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            if let ocakKarti = gunVerisi.ocakKarti {
                let hasOldRows = ocakKarti.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 300
                    for (index, satir) in ocakKarti.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            if let patlatmaKarti = gunVerisi.patlatmaKarti {
                let hasOldRows = patlatmaKarti.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 400
                    for (index, satir) in patlatmaKarti.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            if let tamburKarti = gunVerisi.tamburKarti {
                let hasOldRows = tamburKarti.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 500
                    for (index, satir) in tamburKarti.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            
            // Makine ve Testere Kesme kartları
            if let makineKesmeKarti1 = gunVerisi.makineKesmeKarti1 {
                let hasOldRows = makineKesmeKarti1.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 600
                    for (index, satir) in makineKesmeKarti1.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
            if let testereKesmeKarti1 = gunVerisi.testereKesmeKarti1 {
                let hasOldRows = testereKesmeKarti1.satirlar.contains { $0.orderIndex == 0 }
                if hasOldRows {
                    let baseTime = Int(Date().timeIntervalSince1970 * 1000000) + 700
                    for (index, satir) in testereKesmeKarti1.satirlar.enumerated() {
                        if satir.orderIndex == 0 {
                            satir.orderIndex = baseTime + index
                        }
                    }
                }
            }
        }
    }
    
    // ❌ KALDIRILDI - sortAllCardRows() fonksiyonu satırların yerini değiştiriyordu
    // ForEach zaten orderIndex'e göre sıralı gösteriyor, ekstra sort'a gerek yok
    
    // MARK: - Weekly Finish
    private func finishWeeklyForm() {
        do {
            form.lastEditedAt = Date()
            form.isWeeklyCompleted = true
            form.isCompleted = true // Her ikisi de tamamlandı olarak işaretle
            form.weeklyCompletedAt = Date()
            
            if isNewForm {
                modelContext.insert(form)
                isNewForm = false
            }
            
            // ❌ sortAllRows() KALDIRILDI - Satırların yerini değiştiriyor
            
            try modelContext.save()
            hasChanges = false
            dismiss()
        } catch {
            print("❌ Haftalık form bitirme hatası: \(error)")
        }
    }
    
    // ❌ KALDIRILDI - sortAllRows() fonksiyonu satırların yerini değiştiriyordu

    // MARK: - Auto Save ve İptal İşlemleri
    private func triggerAutoSave() {
        hasChanges = true
        
        // AUTO-SAVE DISABLED TO PREVENT ROW REORDERING
        // Only manual save to maintain stability
        autoSaveTimer?.invalidate()
        
        // Satırları yeniden sıralama - zaten StableTableView orderIndex'e göre gösteriyor
        // sortAllCardRows() kaldırıldı çünkü satırların yerini değiştiriyordu
    }
    
    private func autoSave() {
        if isReadOnly {
            return
        } else if isNewForm && !hasUserInput() {
            return
        }
        
        do {
            form.lastEditedAt = Date()
            
            if isNewForm {
                modelContext.insert(form)
                isNewForm = false
            }
            
            // ❌ sortAllCardRows() KALDIRILDI - Satırların yerini değiştiriyor
            
            try modelContext.save()
            hasChanges = false
            print("✅ Auto-save başarılı")
        } catch {
            print("❌ Auto-save hatası: \(error)")
        }
    }
    
    private func saveForm() {
        do {
            form.lastEditedAt = Date()
            
            if isNewForm {
                modelContext.insert(form)
                isNewForm = false
            }
            
            // ❌ sortAllCardRows() KALDIRILDI - Satırların yerini değiştiriyor
            
            try modelContext.save()
            hasChanges = false
            dismiss()
        } catch {
            print("❌ Kaydetme hatası: \(error)")
        }
    }
    
    private func requestPasswordForCancel() {
        // Admin şifresi kontrolü yap
        showingCancelAuth = true
    }
    
    private func cancelFormWithAuth() {
        // İptal işlemi onaylandı, formu iptal et
        if isNewForm {
            // Yeni form iptal edildiğinde form DB'ye kaydedilmedi zaten, sadece kapat
            print("✅ Yeni form iptal edildi")
        }
        dismiss()
    }
    
    // MARK: - Fire Calculation Helpers
    private func calculateWeeklyFireSummary() -> [AyarFireData] {
        var weeklyFireByAyar: [Int: Double] = [:]
        
        // Tüm günlerin tüm kartlarından fire topla
        for gunVerisi in form.gunlukVeriler {
            // Cila kartı
            if let cilaKarti = gunVerisi.cilaKarti {
                for satir in cilaKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Ocak kartı
            if let ocakKarti = gunVerisi.ocakKarti {
                for satir in ocakKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Patlatma kartı
            if let patlatmaKarti = gunVerisi.patlatmaKarti {
                for satir in patlatmaKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Tambur kartı
            if let tamburKarti = gunVerisi.tamburKarti {
                for satir in tamburKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Makine Kesme kartı
            if let makineKesmeKarti = gunVerisi.makineKesmeKarti1 {
                for satir in makineKesmeKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Testere Kesme kartı
            if let testereKesmeKarti = gunVerisi.testereKesmeKarti1 {
                for satir in testereKesmeKarti.satirlar {
                    if let ayar = satir.ayar, ayar > 0 {
                        weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + satir.fire
                    }
                }
            }
            
            // Tezgah kartları (tek ayar sistemi) - computed fire property kullan
            if let tezgahKarti1 = gunVerisi.tezgahKarti1, let ayar = tezgahKarti1.ayar, ayar > 0 {
                weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + tezgahKarti1.fire
            }
            
            if let tezgahKarti2 = gunVerisi.tezgahKarti2, let ayar = tezgahKarti2.ayar, ayar > 0 {
                weeklyFireByAyar[ayar] = (weeklyFireByAyar[ayar] ?? 0.0) + tezgahKarti2.fire
            }
        }
        
        // Tüm ayarları göster (0 olanları da)
        let ayarlar = [14, 18, 21, 22]
        return ayarlar.map { ayar in
            let fire = weeklyFireByAyar[ayar] ?? 0.0
            return AyarFireData(ayar: ayar, fire: fire)
        }
    }
    
    private func calculateFireByAyar(for satirlar: [IslemSatiri]) -> [AyarFireData] {
        var fireByAyar: [Int: Double] = [:]
        
        for satir in satirlar {
            if let ayar = satir.ayar, ayar > 0 {
                let currentFire = fireByAyar[ayar] ?? 0.0
                fireByAyar[ayar] = currentFire + satir.fire
            }
        }
        
        // Tüm ayarları göster (0 olanları da)
        let ayarlar = [14, 18, 21, 22]
        return ayarlar.map { ayar in
            let fire = fireByAyar[ayar] ?? 0.0
            return AyarFireData(ayar: ayar, fire: fire)
        }
    }
    

    private func isFriday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: date) == 6 // 6 = Friday
    }
    
    // MARK: - Tezgah Onay Fonksiyonları
    private func confirmTezgahEntry() {
        // Evet seçildi, değerler kalır - hiçbir şey yapma
        pendingTezgahSatir = nil
        pendingTezgahIndex = nil
        confirmationType = nil
    }
    
    private func cancelTezgahEntry() {
        // Hayır seçildi, değerleri sil
        guard let satir = pendingTezgahSatir else { return }
        
        switch confirmationType {
        case .giris:
            // Giriş ve giriş açıklamasını sil
            satir.girisValue = nil
            satir.aciklamaGiris = ""
            satir.aciklamaGirisTarihi = nil
        case .cikis:
            // Çıkış ve çıkış açıklamasını sil
            satir.cikisValue = nil
            satir.aciklamaCikis = ""
            satir.aciklamaCikisTarihi = nil
        case .none:
            break
        }
        
        // State'leri temizle
        pendingTezgahSatir = nil
        pendingTezgahIndex = nil
        confirmationType = nil
        
        // Auto-save zaten çalışıyor, manuel save yapmaya gerek yok
    }
    
    private func handleFocusChange(from oldValue: TezgahFocusedField?, to newValue: TezgahFocusedField?) {
        // Eğer zaten bir onay bekleniyorsa, işlem yapma
        guard !showingTezgahConfirmation else { return }
        
        // Eski focus'tan çıkıyoruz - açıklama alanından mı?
        guard let oldFocus = oldValue else { return }
        
        // Yeni focus farklı olmalı (aynı alandan çıkmıyorsak kontrol etmeye gerek yok)
        guard oldValue != newValue else { return }
        
        // Hangi açıklama alanından çıkıldı?
        switch oldFocus {
        case .solAciklama(let cardIndex, let satirIndex):
            // Giriş açıklamasından çıkıldı
            checkAndConfirmGirisAciklama(cardIndex: cardIndex, satirIndex: satirIndex)
            
        case .sagAciklama(let cardIndex, let satirIndex):
            // Çıkış açıklamasından çıkıldı
            checkAndConfirmCikisAciklama(cardIndex: cardIndex, satirIndex: satirIndex)
            
        default:
            break
        }
    }
    
    private func checkAndConfirmGirisAciklama(cardIndex: Int, satirIndex: Int) {
        guard let gunVerisi = form.gunlukVeriler.first else { return }
        guard let tezgahKarti = getTezgahKarti(for: gunVerisi, cardIndex: cardIndex) else { return }
        
        let stableSatirlar = tezgahKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        guard satirIndex < stableSatirlar.count else { return }
        
        let satir = stableSatirlar[satirIndex]
        
        // Açıklama dolu mu ve giriş değeri var mı?
        if !satir.aciklamaGiris.isEmpty && (satir.girisValue ?? 0) > 0 {
            pendingTezgahSatir = satir
            pendingTezgahIndex = satirIndex
            confirmationType = .giris
            showingTezgahConfirmation = true
        }
    }
    
    private func checkAndConfirmCikisAciklama(cardIndex: Int, satirIndex: Int) {
        guard let gunVerisi = form.gunlukVeriler.first else { return }
        guard let tezgahKarti = getTezgahKarti(for: gunVerisi, cardIndex: cardIndex) else { return }
        
        let stableSatirlar = tezgahKarti.satirlar.sorted { $0.orderIndex < $1.orderIndex }
        guard satirIndex < stableSatirlar.count else { return }
        
        let satir = stableSatirlar[satirIndex]
        
        // Açıklama dolu mu ve çıkış değeri var mı?
        if !satir.aciklamaCikis.isEmpty && (satir.cikisValue ?? 0) > 0 {
            pendingTezgahSatir = satir
            pendingTezgahIndex = satirIndex
            confirmationType = .cikis
            showingTezgahConfirmation = true
        }
    }
    
    private func hasUserInput() -> Bool {
        for gunVerisi in form.gunlukVeriler {
            // Multiple Tezgah kartları
            if let tezgahKarti1 = gunVerisi.tezgahKarti1 {
                for satir in tezgahKarti1.satirlar {
                    if (satir.girisValue ?? 0) > 0 || (satir.cikisValue ?? 0) > 0 {
                        return true
                    }
                }
            }
            if let tezgahKarti2 = gunVerisi.tezgahKarti2 {
                for satir in tezgahKarti2.satirlar {
                    if (satir.girisValue ?? 0) > 0 || (satir.cikisValue ?? 0) > 0 {
                        return true
                    }
                }
            }
            
            if let cilaKarti = gunVerisi.cilaKarti {
                for satir in cilaKarti.satirlar {
                    if satir.giris > 0 || satir.cikis > 0 {
                        return true
                    }
                }
            }
            
            if let ocakKarti = gunVerisi.ocakKarti {
                for satir in ocakKarti.satirlar {
                    if satir.giris > 0 || satir.cikis > 0 {
                        return true
                    }
                }
            }
            
            if let patlatmaKarti = gunVerisi.patlatmaKarti {
                for satir in patlatmaKarti.satirlar {
                    if satir.giris > 0 || satir.cikis > 0 {
                        return true
                    }
                }
            }
            
            if let tamburKarti = gunVerisi.tamburKarti {
                for satir in tamburKarti.satirlar {
                    if satir.giris > 0 || satir.cikis > 0 {
                        return true
                    }
                }
            }
            
            // Makine ve Testere Kesme kartları
            if let makineKesmeKarti1 = gunVerisi.makineKesmeKarti1 {
                for satir in makineKesmeKarti1.satirlar {
                    if satir.toplamGiris > 0 || satir.toplamCikis > 0 {
                        return true
                    }
                }
            }
            if let testereKesmeKarti1 = gunVerisi.testereKesmeKarti1 {
                for satir in testereKesmeKarti1.satirlar {
                    if satir.toplamGiris > 0 || satir.toplamCikis > 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}

// MARK: - WeeklyFinishSheet
struct WeeklyFinishSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var password = ""
    @State private var showingError = false
    
    let onFinish: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(NomisTheme.primaryGreen)
                
                VStack(spacing: 12) {
                    Text("Haftayı Bitir")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.primary)
                    
                    Text("Bu haftalık formu tamamlamak ve kaydetmek için admin şifrenizi girin.")
                        .font(.body)
                        .foregroundColor(NomisTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    SecureField("Admin Şifresi", text: $password)
                        .font(.title3)
                        .padding()
                        .background(NomisTheme.lightCream)
                        .overlay(
                            Rectangle()
                                .stroke(showingError ? Color.red : NomisTheme.primaryGreen, lineWidth: 2)
                        )
                        .onSubmit {
                            handleFinish()
                        }
                    
                    if showingError {
                        Text("Yanlış şifre!")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("İptal") {
                        isPresented = false
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.cardBackground)
                    .foregroundColor(NomisTheme.secondaryText)
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    
                    Button("Haftayı Bitir") {
                        handleFinish()
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    .disabled(password.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func handleFinish() {
        if authManager.authenticateAdmin(password: password) {
            isPresented = false
            onFinish()
        } else {
            showingError = true
            password = ""
            
            // Hatayı 2 saniye sonra gizle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingError = false
            }
        }
    }
}

#Preview {
    DailyOperationsEditorView()
        .environmentObject(AuthenticationManager())
}
