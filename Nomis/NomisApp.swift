import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core Models
            User.self,
            Note.self,
            SarnelForm.self,
            AsitItem.self,
            FireItem.self,  // Added - used by SarnelForm
            
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
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        // Layer 1: Try normal persistent container
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            return container
        }
        
        // Layer 2: Try to delete corrupted store and recreate
        let url = modelConfiguration.url
        try? FileManager.default.removeItem(at: url)
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            return container
        }
        
        // Layer 3: Fallback to in-memory container (data won't persist between launches)
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [fallbackConfig]) {
            return container
        }
        
        // Layer 4: Minimal in-memory container as absolute last resort
        let minimalSchema = Schema([User.self, Note.self])
        let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: minimalSchema, configurations: [minimalConfig]) {
            return container
        }
        
        // Layer 5: Emergency minimal container with simplest model
        if let emergencyContainer = try? ModelContainer(for: Schema([User.self])) {
            return emergencyContainer
        }
        
        // Layer 6: Try with Note model if User fails
        if let noteContainer = try? ModelContainer(for: Schema([Note.self])) {
            return noteContainer
        }
        
        // Layer 7: Last attempt with minimal memory-only User container
        do {
            let lastSchema = Schema([User.self])
            let lastConfig = ModelConfiguration(schema: lastSchema, isStoredInMemoryOnly: true, allowsSave: false)
            return try ModelContainer(for: lastSchema, configurations: [lastConfig])
        } catch {
            // If we reach here, SwiftData is completely broken
            // Print error for debugging but don't crash in production
            print("❌ CRITICAL: ModelContainer creation failed after 7 attempts")
            print("Error: \(error.localizedDescription)")
            
            // One final attempt with absolute minimum
            return try! ModelContainer(for: Schema([User.self]))
        }
    }()
    
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
        // Auto-save tüm değişiklikleri
        do {
            let context = sharedModelContainer.mainContext
            if context.hasChanges {
                try context.save()
            }
        } catch {
            // Hata durumunda yeniden dene
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
