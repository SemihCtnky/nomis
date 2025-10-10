import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Persistent ModelContainer with proper error handling
    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core Models
            User.self,
            Note.self,
            SarnelForm.self,
            AsitItem.self,
            FireItem.self,
            
            // Settings Models
            ModelItem.self,
            CompanyItem.self,
            
            // Kilit Models
            KilitToplamaForm.self,
            KilitItem.self,
            
            // Legacy Gunluk Models  
            GunlukForm.self,
            
            // New Gunluk Models (Active)
            YeniGunlukForm.self,
            GunlukGunVerisi.self,
            TezgahKarti.self,
            TezgahSatiri.self,
            CilaKarti.self,
            OcakKarti.self,
            PatlatmaKarti.self,
            TamburKarti.self,
            MakineKesmeKarti.self,
            TestereKesmeKarti.self,
            
            // Shared Components
            FireEklemesi.self,
            GenisletilebilirDeger.self,
            IslemSatiri.self
        ])
        
        // Create persistent configuration
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // Try to create persistent container
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // Log error for debugging but don't crash the app
            print("⚠️ Failed to create ModelContainer: \(error.localizedDescription)")
            
            // Try with default configuration as fallback
            do {
                let container = try ModelContainer(for: schema)
                return container
            } catch {
                // Last resort: force try with minimal schema
                // This should only happen in extreme cases
                print("⚠️ Critical: Using minimal schema - \(error.localizedDescription)")
                return try! ModelContainer(for: Schema([User.self]))
            }
        }
    }()
    
    init() {
        setupNavigationBarAppearance()
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(NomisTheme.primary)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor(NomisTheme.primary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .modelContainer(sharedModelContainer)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            saveAllDrafts()
        case .active:
            break
        @unknown default:
            break
        }
    }
    
    private func saveAllDrafts() {
        do {
            let context = sharedModelContainer.mainContext
            if context.hasChanges {
                try context.save()
            }
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    let context = self.sharedModelContainer.mainContext
                    if context.hasChanges {
                        try context.save()
                    }
                } catch {
                    // Silent fail
                }
            }
        }
    }
}
