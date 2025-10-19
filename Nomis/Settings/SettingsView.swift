import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ModelManagementView()) {
                        HStack {
                            Image(systemName: "cube.box.fill")
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(NomisTheme.primaryGreen)
                                .cornerRadius(6)
                            
                            Text("Model Oluştur")
                                .font(.body)
                                .foregroundColor(NomisTheme.darkText)
                        }
                    }
                    
                    NavigationLink(destination: CompanyManagementView()) {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .cornerRadius(6)
                            
                            Text("Firma Oluştur")
                                .font(.body)
                                .foregroundColor(NomisTheme.darkText)
                        }
                    }
                    
                    if authManager.currentUsername == "mert" {
                        NavigationLink(destination: AdminPanelView()) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                                
                                Text("Admin Panel")
                                    .font(.body)
                                    .foregroundColor(NomisTheme.darkText)
                            }
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: AppInfoView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.gray)
                                .cornerRadius(6)
                            
                            Text("Uygulama Bilgileri")
                                .font(.body)
                                .foregroundColor(NomisTheme.darkText)
                        }
                    }
                    
                    Button(action: {
                        authManager.logout()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.red)
                                .cornerRadius(6)
                            
                            Text("Çıkış Yap")
                                .font(.body)
                                .foregroundColor(Color.red)
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitti") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AppInfoView (inline for now)
struct AppInfoView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "app.badge")
                    .font(.system(size: 80))
                    .foregroundColor(NomisTheme.primaryGreen)
                
                Text("KİLİTÇİM")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(NomisTheme.primary)
            }
            
            VStack(spacing: 20) {
                    HStack {
                        Text("Uygulama Adı")
                        Spacer()
                        Text("Kilitçim")
                            .foregroundColor(NomisTheme.secondary)
                    }
                    
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.5.0")
                            .foregroundColor(NomisTheme.secondary)
                    }
                
                HStack {
                    Text("Geliştirici")
                    Spacer()
                    Text("Semih Çetinkaya")
                        .foregroundColor(NomisTheme.secondary)
                }
            }
            .padding()
            .background(NomisTheme.lightCream)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Uygulama Bilgileri")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Model Management (Real Implementation)
struct ModelManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query(sort: \ModelItem.createdAt, order: .reverse) private var models: [ModelItem]
    
    @State private var newModelName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Model")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text("\(models.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.primaryGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Son Eklenen")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text(models.last?.name ?? "Yok")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(NomisTheme.darkText)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding()
            .background(NomisTheme.lightCream)
            
            // Add Model Section - Sadece admin görebilir
            if authManager.canEdit {
                VStack(spacing: 16) {
                    HStack {
                        Text("Yeni Model Ekle")
                            .font(.headline)
                            .foregroundColor(NomisTheme.primary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Model adını girin...", text: $newModelName)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: addModel) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Ekle")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                newModelName.trim().isEmpty ? 
                                Color.gray : 
                                NomisTheme.primaryGreen
                            )
                            .cornerRadius(8)
                        }
                        .disabled(newModelName.trim().isEmpty)
                    }
                }
                .padding()
            }
            
            // Models List
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Kayıtlı Modeller (\(models.count))")
                        .font(.headline)
                        .foregroundColor(NomisTheme.primary)
                    
                    Spacer()
                    
                    if !models.isEmpty {
                        Text("Düzenlemek için dokunun")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
                
                if models.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 48))
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Text("Henüz model eklenmemiş")
                            .font(.headline)
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Text("Yukarıdaki form ile yeni model ekleyebilirsiniz")
                            .font(.subheadline)
                            .foregroundColor(NomisTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(models.sorted(by: { $0.createdAt > $1.createdAt })) { model in
                                ModelRowView(model: model)
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Model Yönetimi")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func addModel() {
        let trimmedName = newModelName.trim()
        guard !trimmedName.isEmpty else { return }
        
        let newModel = ModelItem(name: trimmedName)
        modelContext.insert(newModel)
        
        do {
            try modelContext.save()
            newModelName = ""
        } catch {
            // Silent fail
        }
    }
}

struct ModelRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    let model: ModelItem
    
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var showingAdminAuth = false
    @State private var pendingAction: ModelAction?
    
    enum ModelAction {
        case edit, delete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "cube.box.fill")
                .font(.title3)
                .foregroundColor(NomisTheme.primaryGreen)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Model adı", text: $editedName)
                        .font(.body)
                        .fontWeight(.medium)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(model.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(NomisTheme.darkText)
                }
                
                Text("Oluşturulma: \(model.createdAt.formatted(.dateTime.day().month().year()))")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions - Sadece admin görebilir
            if authManager.canEdit {
                HStack(spacing: 8) {
                    if isEditing {
                        Button("Kaydet") {
                            saveEdit()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NomisTheme.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        
                        Button("İptal") {
                            cancelEdit()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    } else {
                        Button(action: {
                            pendingAction = .edit
                            showingAdminAuth = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(NomisTheme.primaryGreen)
                        }
                        
                        Button(action: {
                            pendingAction = .delete
                            showingAdminAuth = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("Modeli Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                deleteModel()
            }
        } message: {
            Text("'\(model.name)' modelini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
        .sheet(isPresented: $showingAdminAuth) {
            AdminAuthSheet(
                title: "Yetkilendirme Gerekli",
                message: "Model düzenlemek veya silmek için admin şifrenizi girin."
            ) {
                switch pendingAction {
                case .edit:
                    startEdit()
                case .delete:
                    showingDeleteAlert = true
                case .none:
                    break
                }
                pendingAction = nil
            }
        }
        .onAppear {
            editedName = model.name
        }
    }
    
    private func startEdit() {
        editedName = model.name
        isEditing = true
    }
    
    private func cancelEdit() {
        editedName = model.name
        isEditing = false
    }
    
    private func saveEdit() {
        let trimmedName = editedName.trim()
        guard !trimmedName.isEmpty, trimmedName != model.name else {
            cancelEdit()
            return
        }
        
        model.name = trimmedName
        do {
            try modelContext.save()
            isEditing = false
        } catch {
            // Silent fail
        }
    }
    
    private func deleteModel() {
        modelContext.delete(model)
        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }
}

struct CompanyManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query(sort: \CompanyItem.createdAt, order: .reverse) private var companies: [CompanyItem]
    
    @State private var newCompanyName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Firma")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text("\(companies.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.primaryGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Son Eklenen")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text(companies.last?.name ?? "Yok")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(NomisTheme.darkText)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding()
            .background(NomisTheme.lightCream)
            
            // Add Company Section - Sadece admin görebilir
            if authManager.canEdit {
                VStack(spacing: 16) {
                    HStack {
                        Text("Yeni Firma Ekle")
                            .font(.headline)
                            .foregroundColor(NomisTheme.primary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Firma adını girin...", text: $newCompanyName)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: addCompany) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Ekle")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                newCompanyName.trim().isEmpty ? 
                                Color.gray : 
                                NomisTheme.primaryGreen
                            )
                            .cornerRadius(8)
                        }
                        .disabled(newCompanyName.trim().isEmpty)
                    }
                }
                .padding()
            }
            
            // Companies List
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Kayıtlı Firmalar (\(companies.count))")
                        .font(.headline)
                        .foregroundColor(NomisTheme.primary)
                    
                    Spacer()
                    
                    if !companies.isEmpty {
                        Text("Düzenlemek için dokunun")
                            .font(.caption)
                            .foregroundColor(NomisTheme.secondaryText)
                    }
                }
                
                if companies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Text("Henüz firma eklenmemiş")
                            .font(.headline)
                            .foregroundColor(NomisTheme.secondaryText)
                        
                        Text("Yukarıdaki form ile yeni firma ekleyebilirsiniz")
                            .font(.subheadline)
                            .foregroundColor(NomisTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(companies.sorted(by: { $0.createdAt > $1.createdAt })) { company in
                                CompanyRowView(company: company)
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Firma Yönetimi")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func addCompany() {
        let trimmedName = newCompanyName.trim()
        guard !trimmedName.isEmpty else { return }
        
        let newCompany = CompanyItem(name: trimmedName)
        modelContext.insert(newCompany)
        
        do {
            try modelContext.save()
            newCompanyName = ""
        } catch {
            // Silent fail
        }
    }
}

struct CompanyRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    let company: CompanyItem
    
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var showingAdminAuth = false
    @State private var pendingAction: CompanyAction?
    
    enum CompanyAction {
        case edit, delete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(NomisTheme.primaryGreen)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("Firma adı", text: $editedName)
                        .font(.body)
                        .fontWeight(.medium)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(company.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(NomisTheme.darkText)
                }
                
                Text("Oluşturulma: \(company.createdAt.formatted(.dateTime.day().month().year()))")
                    .font(.caption)
                    .foregroundColor(NomisTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions - Sadece admin görebilir
            if authManager.canEdit {
                HStack(spacing: 8) {
                    if isEditing {
                        Button("Kaydet") {
                            saveEdit()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NomisTheme.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        
                        Button("İptal") {
                            cancelEdit()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    } else {
                        Button(action: {
                            pendingAction = .edit
                            showingAdminAuth = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(NomisTheme.primaryGreen)
                        }
                        
                        Button(action: {
                            pendingAction = .delete
                            showingAdminAuth = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                        .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("Firmayı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                deleteCompany()
            }
        } message: {
            Text("'\(company.name)' firmasını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
        .sheet(isPresented: $showingAdminAuth) {
            AdminAuthSheet(
                title: "Yetkilendirme Gerekli",
                message: "Firma düzenlemek veya silmek için admin şifrenizi girin."
            ) {
                switch pendingAction {
                case .edit:
                    startEdit()
                case .delete:
                    showingDeleteAlert = true
                case .none:
                    break
                }
                pendingAction = nil
            }
        }
        .onAppear {
            editedName = company.name
        }
    }
    
    private func startEdit() {
        editedName = company.name
        isEditing = true
    }
    
    private func cancelEdit() {
        editedName = company.name
        isEditing = false
    }
    
    private func saveEdit() {
        let trimmedName = editedName.trim()
        guard !trimmedName.isEmpty, trimmedName != company.name else {
            cancelEdit()
            return
        }
        
        company.name = trimmedName
        do {
            try modelContext.save()
            isEditing = false
        } catch {
            // Silent fail
        }
    }
    
    private func deleteCompany() {
        modelContext.delete(company)
        do {
            try modelContext.save()
        } catch {
            // Silent fail
        }
    }
}


struct AdminPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allForms: [SarnelForm]
    @Query private var allKilitForms: [KilitToplamaForm]
    @Query private var allGunlukForms: [YeniGunlukForm]
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats Cards
            HStack(spacing: 16) {
                AdminStatCard(title: "Şarnel Forms", value: "\(allForms.count)", icon: "doc.fill", color: .green)
                AdminStatCard(title: "Kilit Forms", value: "\(allKilitForms.count)", icon: "lock.fill", color: .orange)
                AdminStatCard(title: "Günlük Forms", value: "\(allGunlukForms.count)", icon: "calendar.badge.clock", color: .purple)
            }
            .padding()
            .background(NomisTheme.lightCream)
            
            // Content Tabs
            Picker("Admin Seçenekleri", selection: $selectedTab) {
                Text("Form İstatistikleri").tag(0)
                Text("Sistem Bilgileri").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                AdminFormStatsTab(
                    sarnelForms: allForms,
                    kilitForms: allKilitForms,
                    gunlukForms: allGunlukForms
                ).tag(0)
                
                AdminSystemInfoTab().tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Admin Paneli")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(NomisTheme.darkText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(NomisTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct AdminFormStatsTab: View {
    let sarnelForms: [SarnelForm]
    let kilitForms: [KilitToplamaForm]
    let gunlukForms: [YeniGunlukForm]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AdminFormTypeCard(
                    title: "Şarnel Formları",
                    count: sarnelForms.count,
                    recentCount: sarnelForms.filter { Calendar.current.isDateInToday($0.createdAt) }.count,
                    icon: "doc.text.fill",
                    color: .green
                )
                
                AdminFormTypeCard(
                    title: "Kilit Toplama Formları",
                    count: kilitForms.count,
                    recentCount: kilitForms.filter { Calendar.current.isDateInToday($0.createdAt) }.count,
                    icon: "lock.doc.fill",
                    color: .orange
                )
                
                AdminFormTypeCard(
                    title: "Günlük İş Formları",
                    count: gunlukForms.count,
                    recentCount: gunlukForms.filter { Calendar.current.isDateInToday($0.createdAt) }.count,
                    icon: "calendar.badge.clock",
                    color: .purple
                )
            }
            .padding()
        }
    }
}

struct AdminFormTypeCard: View {
    let title: String
    let count: Int
    let recentCount: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(NomisTheme.darkText)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Toplam Form")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text("\(count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.darkText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Bugün Oluşturulan")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                    Text("\(recentCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct AdminSystemInfoTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AdminInfoCard(title: "Uygulama Bilgileri", items: [
                    ("Uygulama Adı", "Kilitçim"),
                    ("Versiyon", "1.5.0"),
                    ("Platform", "iOS"),
                    ("Build", "2025.1")
                ])
                
                AdminInfoCard(title: "Sistem Bilgileri", items: [
                    ("Cihaz", UIDevice.current.model),
                    ("iOS Versiyon", UIDevice.current.systemVersion),
                    ("Uygulama Başlangıç", Date().formatted(.dateTime.day().month().year()))
                ])
                
                AdminInfoCard(title: "Veritabanı Bilgileri", items: [
                    ("SwiftData", "Aktif"),
                    ("Senkronizasyon", "Otomatik")
                ])
            }
            .padding()
        }
    }
}

struct AdminInfoCard: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(NomisTheme.primary)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.0) { key, value in
                    HStack {
                        Text(key)
                            .foregroundColor(NomisTheme.secondaryText)
                        Spacer()
                        Text(value)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.darkText)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}