import SwiftUI
import SwiftData

struct SarnelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query(sort: \SarnelForm.createdAt, order: .reverse) private var forms: [SarnelForm]
    @State private var showingNewForm = false
    @State private var selectedForm: SarnelForm?
    @State private var selectedFormForView: SarnelForm?
    @State private var showingDeleteAlert = false
    @State private var formToDelete: SarnelForm?
    @State private var showingAdminAuth = false
    @State private var pendingAction: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack {
                if forms.isEmpty {
                    Text("Henüz şarnel formu eklenmemiş")
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
            .navigationTitle("Şarnel")
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
                SarnelEditorView()
            }
            .fullScreenCover(item: $selectedForm) { form in
                SarnelEditorView(form: form)
            }
            .fullScreenCover(item: $selectedFormForView) { form in
                SarnelEditorView(form: form, isReadOnly: true)
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
                    message: "Bu işlemi gerçekleştirmek için şifrenizi girin."
                ) {
                    pendingAction?()
                    pendingAction = nil
                }
            }
        }
    }
    
    private func deleteForm(_ form: SarnelForm) {
        withAnimation {
            modelContext.delete(form)
            try? modelContext.save()
        }
        formToDelete = nil
    }
    
    @ViewBuilder
    private func formRowView(for form: SarnelForm) -> some View {
        SarnelFormRowView(
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
            onDelete: (authManager.canDelete && !authManager.canEdit) ? {
                formToDelete = form
                pendingAction = {
                    deleteForm(form)
                }
                showingAdminAuth = true
            } : nil
        )
    }
    
    private func completeForm(_ form: SarnelForm) {
        form.state = .completed
        form.endedAt = Date()
        form.lastEditedAt = Date()
        try? modelContext.save()
    }
}

struct SarnelFormRowView: View {
    let form: SarnelForm
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
    
    init(form: SarnelForm, onTap: @escaping () -> Void, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.form = form
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(form.karatAyar) Ayar Şarnel")
                        .font(.headline.weight(NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.text)
                    
                    if let startTime = form.startedAt {
                        Text("Başlangıç: \(Formatters.formatDateTime(startTime))")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        if let endTime = form.endedAt {
                            Text("Bitiş: \(Formatters.formatDateTime(endTime))")
                                .font(.caption)
                                .foregroundColor(NomisTheme.secondaryText)
                        }
                    } else {
                        Text("Oluşturulma: \(Formatters.formatDateTime(form.createdAt))")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Status Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                    
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(24)
                                .background(NomisTheme.primaryGreen)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let duration = formDuration {
                        Text(duration)
                            .font(.caption2)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
            }
            
            if let girisAltin = form.girisAltin {
                HStack {
                    Text("Giriş Altın:")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text(Formatters.formatGrams(girisAltin))
                        .font(.caption.weight(NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.text)
                    
                    Spacer()
                    
                    if let fire = form.totalFinalFire {
                        Text("Fire:")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                        Text(Formatters.formatGrams(fire))
                            .font(.caption.weight(NomisTheme.headlineWeight))
                            .foregroundColor(fire > 0 ? NomisTheme.destructive : NomisTheme.primary)
                    }
                }
            }
            
            if let altinOrani = form.altinOrani {
                HStack {
                    Text("Altın Oranı:")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text(Formatters.formatNumber(altinOrani))
                        .font(.caption.weight(NomisTheme.headlineWeight))
                        .foregroundColor(NomisTheme.primary)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, NomisTheme.smallSpacing)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var formDuration: String? {
        guard let started = form.startedAt else { return nil }
        let endTime = form.endedAt ?? Date()
        let duration = endTime.timeIntervalSince(started)
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SarnelForm.self, configurations: config)
        
        return SarnelListView()
            .environmentObject(AuthenticationManager())
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
