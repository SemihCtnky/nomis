import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncService = CloudKitSyncService.shared
    
    @State private var selectedModule: HomeModule?
    @State private var showingSyncError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(HomeModule.allCases, id: \.self) { module in
                        HomeCard(module: module) {
                            selectedModule = module
                        }
                    }
                }
                .padding(16)
            }
            .background(NomisTheme.background)
            .navigationTitle("KİLİTÇİM")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    syncStatusView
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Sync button
                        Button(action: {
                            Task {
                                await syncService.performFullSync(modelContext: modelContext)
                            }
                        }) {
                            if syncService.isSyncing {
                                ProgressView()
                                    .tint(NomisTheme.primary)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(NomisTheme.primary)
                            }
                        }
                        .disabled(syncService.isSyncing)
                        
                        // User menu
                        Menu {
                            Button("Çıkış Yap") {
                                authManager.logout()
                            }
                        } label: {
                            Image(systemName: "person.circle")
                                .foregroundColor(NomisTheme.primary)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(item: $selectedModule) { module in
            moduleView(for: module)
        }
        .onAppear {
            // Auto-sync on app launch (only if user manually triggers sync)
            // Disabled by default to avoid crashes on simulator without iCloud
        }
        .onChange(of: syncService.syncStatus) { _, newStatus in
            if case .error = newStatus {
                showingSyncError = true
            }
        }
        .alert("Senkronizasyon Hatası", isPresented: $showingSyncError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(syncService.syncError ?? "Bilinmeyen hata")
        }
    }
    
    private var syncStatusView: some View {
        Group {
            switch syncService.syncStatus {
            case .idle:
                if let lastSync = syncService.lastSyncDate {
                    Text("Son: \(formatSyncDate(lastSync))")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                } else {
                    EmptyView()
                }
            case .syncing:
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Senkronize...")
                        .font(.caption)
                }
                .foregroundColor(NomisTheme.secondaryText)
            case .success:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Başarılı")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                }
            case .error:
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Hata")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .onTapGesture {
                    showingSyncError = true
                }
            }
        }
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var gridColumns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        } else {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        }
    }
    
    @ViewBuilder
    private func moduleView(for module: HomeModule) -> some View {
        switch module {
        case .gunlukIslerim:
            DailyOperationsListView()
        case .sarnel:
            SarnelListView()
        case .kilitToplama:
            KilitListView()
        case .analiz:
            AnalizView()
        case .yedekleme:
            BackupView()
        case .notlar:
            NotesListView()
        case .ayarlar:
            SettingsView()
        }
    }
}

struct HomeCard: View {
    let module: HomeModule
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: module.iconName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(NomisTheme.primary)
                
                Text(module.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(NomisTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .nomisCard()
    }
}

enum HomeModule: CaseIterable, Identifiable {
    case gunlukIslerim
    case sarnel
    case kilitToplama
    case analiz
    case yedekleme
    case notlar
    case ayarlar
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .gunlukIslerim: return "Günlük İşlerim"
        case .sarnel: return "Şarnel"
        case .kilitToplama: return "Kilit Toplama"
        case .analiz: return "Analiz"
        case .yedekleme: return "Yedekleme"
        case .notlar: return "Notlar"
        case .ayarlar: return "Ayarlar"
        }
    }
    
    var iconName: String {
        switch self {
        case .gunlukIslerim: return "chart.bar.xaxis"
        case .sarnel: return "flame.fill"
        case .kilitToplama: return "lock.fill"
        case .analiz: return "chart.line.uptrend.xyaxis"
        case .yedekleme: return "externaldrive.fill"
        case .notlar: return "note.text"
        case .ayarlar: return "gearshape.fill"
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
}
