import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncService = CloudKitSyncService.shared
    
    @State private var selectedModule: HomeModule?
    @State private var autoFetchTimer: Timer?
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(item: $selectedModule) { module in
            moduleView(for: module)
        }
        .onAppear {
            // CRITICAL: Fetch data on app launch for read-only users
            startAutoFetch()
        }
        .onDisappear {
            // Stop timer when view disappears
            stopAutoFetch()
        }
    }
    
    // MARK: - Auto Fetch for Read-Only Users
    
    private func startAutoFetch() {
        print("🏠 [HOME] AUTO-FETCH STARTED: Initial fetch + 30s periodic timer")
        
        // Initial fetch on app launch
        Task {
            await syncService.performIncrementalSync(modelContext: modelContext)
        }
        
        // Setup periodic fetch (every 30 seconds)
        // This ensures read-only users see updates from admin users
        autoFetchTimer?.invalidate()
        autoFetchTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak syncService, modelContext] _ in
            print("🏠 [HOME] AUTO-FETCH TRIGGERED: 30s timer fired")
            Task { @MainActor in
                await syncService?.performIncrementalSync(modelContext: modelContext)
            }
        }
    }
    
    private func stopAutoFetch() {
        autoFetchTimer?.invalidate()
        autoFetchTimer = nil
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
