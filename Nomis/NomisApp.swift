import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Optional ModelContainer - App works even without it (CRASH-PROOF)
    let sharedModelContainer: ModelContainer? = {
        print("🔄 Initializing ModelContainer...")
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
        
        // Fallback 1: Try in-memory storage first (most compatible)
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            print("✅ ModelContainer: In-memory storage initialized")
            return container
        } catch {
            print("⚠️ In-memory storage failed: \(error.localizedDescription)")
        }
        
        // Fallback 2: Try default configuration
        do {
            let container = try ModelContainer(for: schema)
            print("✅ ModelContainer: Default configuration initialized")
            return container
        } catch {
            print("⚠️ Default configuration failed: \(error.localizedDescription)")
        }
        
        // Fallback 3: Minimal schema in-memory
        do {
            let minimalSchema = Schema([User.self])
            let config = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: minimalSchema, configurations: [config])
            print("⚠️ CRITICAL: Using minimal in-memory schema")
            return container
        } catch {
            print("💥 FATAL: Cannot create ModelContainer - \(error.localizedDescription)")
            print("⚠️ App will run without data persistence")
            return nil
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
            Group {
                if let container = sharedModelContainer {
                    ContentView()
                        .environmentObject(authManager)
                        .modelContainer(container)
                        .onChange(of: scenePhase) { _, newPhase in
                            handleScenePhaseChange(newPhase)
                        }
                } else {
                    // Fallback view when ModelContainer is not available
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Veri sistemi başlatılamadı")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Lütfen uygulamayı yeniden başlatın")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
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
        guard let container = sharedModelContainer else { return }
        
        let context = container.mainContext
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
