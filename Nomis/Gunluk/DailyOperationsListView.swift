import SwiftUI
import SwiftData

struct DailyOperationsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query(sort: \YeniGunlukForm.createdAt, order: .reverse) private var forms: [YeniGunlukForm]
    @State private var showingNewForm = false
    @State private var selectedForm: YeniGunlukForm?
    @State private var showingAdminAuth = false
    @State private var pendingAction: (() -> Void)?
    @State private var formToDelete: YeniGunlukForm?
    @State private var selectedFormForView: YeniGunlukForm?
    
    var body: some View {
        NavigationStack {
            VStack {
                if forms.isEmpty {
                    Text("Henüz günlük işlem formu eklenmemiş")
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
            .navigationTitle("Günlük İşlemler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.canEdit {
                        Button("Yeni Form") {
                            // Form oluşturmayı geciktir - sadece editor açıldığında oluştur
                            showingNewForm = true
                        }
                        .foregroundColor(NomisTheme.primary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingNewForm) {
            DailyOperationsEditorView()
        }
        .fullScreenCover(item: $selectedForm) { form in
            DailyOperationsEditorView(form: form, isReadOnly: form.isWeeklyCompleted)
        }
        .fullScreenCover(item: $selectedFormForView) { form in
            DailyOperationsEditorView(form: form, isReadOnly: true)
        }
        .sheet(isPresented: $showingAdminAuth) {
            AdminAuthSheet(
                title: "Yönetici Yetkisi Gerekli",
                message: "Bu işlemi gerçekleştirmek için şifrenizi girin.",
                onSuccess: {
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
    }
    
    private func formRowView(for form: YeniGunlukForm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Form başlığı ve tarih
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Haftalık İşlem Formu")
                        .font(.headline.weight(NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.primary)
                    
                    Text("Başlama: \(formatTurkishDate(form.baslamaTarihi))")
                        .font(.subheadline)
                        .foregroundColor(NomisTheme.secondaryText)
                    
                    Text("Bitiş: \(formatTurkishDate(form.bitisTarihi))")
                        .font(.subheadline)
                        .foregroundColor(NomisTheme.secondaryText)
                }
                
                Spacer()
                
                // Status badge
                Text(form.isWeeklyCompleted ? "Tamamlandı" : "Devam Ediyor")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(form.isWeeklyCompleted ? Color.green : Color.orange.opacity(0.7))
                    .cornerRadius(6)
            }
            
            // Hafta günleri özeti
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(form.gunlukVeriler.sorted(by: { $0.tarih < $1.tarih }), id: \.id) { gunVerisi in
                    VStack(spacing: 4) {
                        Text(gunVerisi.gunAdi.prefix(3).uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Circle()
                            .fill(hasData(for: gunVerisi) ? NomisTheme.primaryGreen : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Edit button - Sadece düzenleme yetkisi olanlar görebilir
            if authManager.canEdit && !form.isWeeklyCompleted {
                Button(action: {
                    pendingAction = {
                        selectedForm = form
                    }
                    showingAdminAuth = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.title3)
                        Text("Düzenle")
                            .font(.title3.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(NomisTheme.primaryGreen)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Silme butonu - sadece killeR hesabı için
            if authManager.canDelete && !authManager.canEdit {
                Button(action: {
                    formToDelete = form
                    pendingAction = {
                        deleteForm(form)
                    }
                    showingAdminAuth = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("Sil")
                            .font(.title2.weight(.bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .nomisCard()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedFormForView = form
        }
    }
    
    private func hasData(for gunVerisi: GunlukGunVerisi) -> Bool {
        // Multiple Tezgah kartlarını kontrol et
        let tezgah1HasData = gunVerisi.tezgahKarti1?.satirlar.contains { $0.girisValue != nil || !$0.aciklamaGiris.isEmpty } == true
        let tezgah2HasData = gunVerisi.tezgahKarti2?.satirlar.contains { $0.girisValue != nil || !$0.aciklamaGiris.isEmpty } == true
        
        // Diğer kartları kontrol et
        let cilaHasData = gunVerisi.cilaKarti?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        let ocakHasData = gunVerisi.ocakKarti?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        let patlatmaHasData = gunVerisi.patlatmaKarti?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        let tamburHasData = gunVerisi.tamburKarti?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        let makineHasData = gunVerisi.makineKesmeKarti1?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        let testereHasData = gunVerisi.testereKesmeKarti1?.satirlar.contains { $0.toplamGiris > 0 || !$0.aciklamaGiris.isEmpty } == true
        
        return tezgah1HasData || tezgah2HasData || cilaHasData || ocakHasData || patlatmaHasData || tamburHasData || makineHasData || testereHasData
    }
    
    private func formatTurkishDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func deleteForm(_ form: YeniGunlukForm) {
        DispatchQueue.main.async {
            do {
                self.modelContext.delete(form)
                try self.modelContext.save()
            } catch {
                // Silent fail
            }
        }
    }
    
    
}

#Preview {
    DailyOperationsListView()
        .environmentObject(AuthenticationManager())
}
