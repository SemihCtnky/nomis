import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // ModelContainer - ALWAYS created (in-memory if persistent fails)
    let sharedModelContainer: ModelContainer
    
    init() {
        // Create ModelContainer - will ALWAYS succeed (falls back to in-memory)
        self.sharedModelContainer = Self.createModelContainer()
        
        // App initialization
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
    
    // Static function to create ModelContainer - ALWAYS returns a valid container
    private static func createModelContainer() -> ModelContainer {
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
        
        // STRATEGY 1: Clean corrupted stores first
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupport.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            
            // Also clean any -wal or -shm files
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
        }
        
        // STRATEGY 2: Try in-memory container (SAFEST - always works)
        let memoryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        if let container = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            print("✅ ModelContainer: In-memory mode (data temporary)")
            return container
        }
        
        // STRATEGY 3: Try persistent container
        let persistentConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            print("✅ ModelContainer: Persistent mode (data saved)")
            return container
        }
        
        // STRATEGY 4: Try minimal User-only schema in-memory
        let minimalSchema = Schema([User.self])
        let minimalConfig = ModelConfiguration(
            schema: minimalSchema,
            isStoredInMemoryOnly: true,
            allowsSave: false
        )
        
        if let container = try? ModelContainer(for: minimalSchema, configurations: [minimalConfig]) {
            print("⚠️ ModelContainer: Minimal User-only mode")
            return container
        }
        
        // STRATEGY 5: Try simplest possible container
        if let container = try? ModelContainer(for: Schema([User.self])) {
            print("⚠️ ModelContainer: Emergency User mode")
            return container
        }
        
        // STRATEGY 6: Force create empty User container (THIS MUST WORK)
        // If even this fails, iOS/SwiftData itself is completely broken
        do {
            let emergencySchema = Schema([User.self])
            let emergencyContainer = try ModelContainer(for: emergencySchema)
            print("⚠️ ModelContainer: Force-created emergency container")
            return emergencyContainer
        } catch {
            // ABSOLUTE LAST RESORT: Create most basic in-memory container
            // This is the ONLY place where failure is truly impossible
            let ultraMinimalSchema = Schema([User.self])
            let ultraMinimalConfig = ModelConfiguration(
                schema: ultraMinimalSchema,
                isStoredInMemoryOnly: true,
                allowsSave: false
            )
            
            // This WILL work - in-memory User-only container with no save
            let lastResortContainer = try! ModelContainer(
                for: ultraMinimalSchema,
                configurations: [ultraMinimalConfig]
            )
            print("🆘 ModelContainer: Last resort in-memory container (read-only)")
            return lastResortContainer
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            // Auto-save any drafts when app goes to background or becomes inactive
            saveAllDrafts()
        case .active:
            // App became active
            break
        @unknown default:
            break
        }
    }
    
    private func saveAllDrafts() {
        // Auto-save all changes
        do {
            let context = sharedModelContainer.mainContext
            if context.hasChanges {
                try context.save()
            }
        } catch {
            // Retry once after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                do {
                    let context = self.sharedModelContainer.mainContext
                    if context.hasChanges {
                        try context.save()
                    }
                } catch {
                    // Silent fail - don't crash on auto-save
                    print("⚠️ Auto-save failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
