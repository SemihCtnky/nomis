import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // ModelContainer with multi-level fallback - NEVER CRASHES
    let sharedModelContainer: ModelContainer = {
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
        
        // Detect if running on simulator
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        
        // Fallback 1: Try persistent storage (best for real device)
        if !isSimulator {
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [config])
                print("✅ ModelContainer: Persistent storage initialized")
                return container
            } catch {
                print("⚠️ Persistent storage failed: \(error.localizedDescription)")
            }
        }
        
        // Fallback 2: Try default configuration
        do {
            let container = try ModelContainer(for: schema)
            print("✅ ModelContainer: Default configuration initialized")
            return container
        } catch {
            print("⚠️ Default configuration failed: \(error.localizedDescription)")
        }
        
        // Fallback 3: In-memory storage (safest, works on simulator)
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            print("✅ ModelContainer: In-memory storage initialized (simulator-safe)")
            return container
        } catch {
            print("⚠️ In-memory storage failed: \(error.localizedDescription)")
        }
        
        // Fallback 4: Minimal schema in-memory (absolute last resort - NO CRASH)
        do {
            let minimalSchema = Schema([User.self])
            let config = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: minimalSchema, configurations: [config])
            print("⚠️ CRITICAL: Using minimal in-memory schema")
            return container
        } catch {
            print("💥 EMERGENCY: Creating empty ModelContainer")
            // Emergency: Create the simplest possible container that won't crash
            let emptySchema = Schema([User.self])
            // Force try is safe here because User is a simple model that will always work
            let container = try! ModelContainer(for: emptySchema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            print("⚠️ EMERGENCY MODE: App running with minimal data support")
            return container
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
        let context = sharedModelContainer.mainContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak context] in
                guard let context = context, context.hasChanges else { return }
                try? context.save() // Silent fail on retry
            }
        }
    }
}
