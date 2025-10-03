import SwiftUI
import SwiftData

struct KilitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query(sort: \KilitToplamaForm.createdAt, order: .reverse) private var forms: [KilitToplamaForm]
    @State private var showingNewForm = false
    @State private var selectedForm: KilitToplamaForm?
    @State private var selectedFormForView: KilitToplamaForm?
    @State private var showingDeleteAlert = false
    @State private var formToDelete: KilitToplamaForm?
    @State private var showingAdminAuth = false
    @State private var pendingAction: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack {
                if forms.isEmpty {
                    Text("Henüz kilit toplama formu eklenmemiş")
                        .foregroundColor(NomisTheme.secondaryText)
                        .font(.body)
                        .padding()
                } else {
                    List {
                        ForEach(forms) { form in
                            formRowView(for: form)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Kilit Toplama")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.canEdit {
                        Button("Yeni Form") {
                            showingNewForm = true
                        }
                        .foregroundColor(NomisTheme.primary)
                    }
                }
            })
            .fullScreenCover(isPresented: $showingNewForm) {
                KilitEditorView()
            }
            .fullScreenCover(item: $selectedForm) { form in
                KilitEditorView(form: form)
            }
            .fullScreenCover(item: $selectedFormForView) { form in
                KilitEditorView(form: form, isReadOnly: true)
            }
            .alert("Formu Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) {
                    formToDelete = nil
                }
                Button("Sil", role: .destructive) {
                    if let form = formToDelete {
                        deleteForm(form)
                    }
                }
            } message: {
                Text("Bu formu silmek istediğinizden emin misiniz?")
            }
            .sheet(isPresented: $showingAdminAuth) {
                AdminAuthSheet(
                    title: "Yönetici Yetkisi Gerekli",
                    message: "Bu işlemi gerçekleştirmek için admin şifrenizi girin."
                ) {
                    pendingAction?()
                    pendingAction = nil
                }
            }
        }
    }
    
    private func deleteForm(_ form: KilitToplamaForm) {
        withAnimation {
            modelContext.delete(form)
            try? modelContext.save()
        }
        formToDelete = nil
    }
    
    @ViewBuilder
    private func formRowView(for form: KilitToplamaForm) -> some View {
        KilitFormRowView(
            form: form,
            onTap: {
                // Görüntüleme - read-only mode
                selectedFormForView = form
            },
            onEdit: authManager.canEdit ? {
                pendingAction = {
                    selectedForm = form
                }
                showingAdminAuth = true
            } : nil,
            onDelete: authManager.canDelete ? {
                pendingAction = {
                    formToDelete = form
                    showingDeleteAlert = true
                }
                showingAdminAuth = true
            } : nil
        )
    }
}

struct KilitFormRowView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let form: KilitToplamaForm
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    private var isCompleted: Bool {
        form.endedAt != nil
    }
    
    private var statusColor: Color {
        if isCompleted {
            return Color.green
        } else {
            return Color.orange.opacity(0.7)
        }
    }
    
    private var statusText: String {
        if isCompleted {
            return "Tamamlandı"
        } else {
            return "Devam Ediyor"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: NomisTheme.contentSpacing) {
                // Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let model = form.model, !model.isEmpty {
                            Text(model)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(NomisTheme.text)
                        }
                        
                        if let firma = form.firma, !firma.isEmpty {
                            Text(firma)
                                .font(.subheadline)
                                .foregroundColor(NomisTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(statusColor)
                        }
                        
                        Text(Formatters.formatDate(form.createdAt))
                            .font(.caption2)
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        HStack(spacing: 8) {
                            if let onEdit = onEdit {
                                Button(action: onEdit) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(NomisTheme.primaryGreen)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if let onDelete = onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(NomisTheme.destructive)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Info Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: NomisTheme.itemSpacing) {
                    if let ayar = form.ayar {
                        InfoCard(
                            title: "Ayar",
                            value: "\(ayar)",
                            icon: "gauge"
                        )
                    }
                    
                    InfoCard(
                        title: "Toplam Kilit Gramı",
                        value: String(format: "%.2f g", calculateTotalKilitGram(form)),
                        icon: "scalemass"
                    )
                    
                    InfoCard(
                        title: "Kilit Adet",
                        value: "\(calculateToplamKilitAdet(form))",
                        icon: "number"
                    )
                    
                    InfoCard(
                        title: "Kilit Milyemi",
                        value: String(format: "%.2f", calculateKilitMilyemi(form)),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                
                // Date Range (if started)
                if let startDate = form.startedAt {
                    HStack {
                        Text("Başlama: \(Formatters.formatDateTime(startDate))")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Spacer()
                        
                        if let endDate = form.endedAt {
                            Text("Bitiş: \(Formatters.formatDateTime(endDate))")
                                .font(.caption)
                                .foregroundColor(NomisTheme.secondaryText)
                        }
                    }
                }
            }
            .padding(NomisTheme.contentSpacing)
            .background(NomisTheme.cardBackground)
            .cornerRadius(NomisTheme.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Label("Düzenle", systemImage: "pencil")
                }
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Sil", systemImage: "trash")
                }
            }
        }
    }
    
    private func calculateToplamKilitAdet(_ form: KilitToplamaForm) -> Int {
        return Int(form.kilitItems.reduce(0) { total, item in
            total + (item.girisAdet ?? 0) + (item.cikisAdet ?? 0)
        })
    }
    
    private func calculateTotalKilitGram(_ form: KilitToplamaForm) -> Double {
        return form.kilitItems.reduce(0) { $0 + ($1.girisGram ?? 0) + ($1.cikisGram ?? 0) }
    }
    
    private func calculateKilitMilyemi(_ form: KilitToplamaForm) -> Double {
        // Giriş yapılan yay gramından çıkış yapılan yay gramını çıkar
        let girisYayGram = form.yayItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
        let cikisYayGram = form.yayItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
        let yayFire = girisYayGram - cikisYayGram
        
        // Toplam kilit gramı
        let toplamKilitGram = calculateTotalKilitGram(form)
        
        // Yay fire / toplam kilit gramı
        let milyemOrani = toplamKilitGram > 0 ? yayFire / toplamKilitGram : 0
        
        // 1 çıkar
        let milyemEksi1 = milyemOrani - 1
        
        // Ayar değerine göre çarp
        let ayarValue = form.ayar ?? 14
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
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(NomisTheme.primary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(NomisTheme.text)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(NomisTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(NomisTheme.cardBackground)
        .cornerRadius(6)
    }
}
