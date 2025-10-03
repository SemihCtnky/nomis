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

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Try to delete existing store and recreate
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Fallback to in-memory only container - app will work but data won't persist
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [fallbackConfig])
                } catch {
                    // As absolute last resort, create minimal in-memory container
                    let minimalSchema = Schema([User.self, Note.self])
                    let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
                    return (try? ModelContainer(for: minimalSchema, configurations: [minimalConfig])) ?? {
                        fatalError("Could not create ModelContainer: \(error)")
                    }()
                }
            }
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
