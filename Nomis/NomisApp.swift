import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var containerManager = ModelContainerManager()
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
            if let container = containerManager.container {
                ContentView()
                    .environmentObject(authManager)
                    .modelContainer(container)
                    .onChange(of: scenePhase) { _, newPhase in
                        handleScenePhaseChange(newPhase)
                    }
            } else {
                // Loading or error state
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Yükleniyor...")
                        .font(.headline)
                    
                    if let error = containerManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
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
        guard let container = containerManager.container else { return }
        
        // Auto-save all changes
        do {
            let context = container.mainContext
            if context.hasChanges {
                try context.save()
            }
        } catch {
            // Retry once after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard let container = self.containerManager.container else { return }
                do {
                    let context = container.mainContext
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

// Separate class to manage ModelContainer creation asynchronously
@MainActor
class ModelContainerManager: ObservableObject {
    @Published var container: ModelContainer?
    @Published var error: String?
    
    init() {
        // Create container asynchronously to avoid blocking app launch
        Task {
            await createContainer()
        }
    }
    
    private func createContainer() async {
        // Try with minimal schema first
        print("🔍 Attempting to create ModelContainer...")
        
        // ATTEMPT 1: Minimal User-only schema (most likely to work)
        do {
            let minimalSchema = Schema([User.self])
            let minimalConfig = ModelConfiguration(
                schema: minimalSchema,
                isStoredInMemoryOnly: true,
                allowsSave: false
            )
            let container = try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
            print("✅ MINIMAL User-only container created!")
            self.container = container
            return
        } catch {
            print("❌ Minimal container failed: \(error)")
        }
        
        // ATTEMPT 2: Try with full schema
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
        
        print("🔍 Full schema created, attempting container...")
        
        // STRATEGY 1: Clean corrupted stores first
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupport.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            
            // Also clean any -wal or -shm files
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
        }
        
        // STRATEGY 2: Try in-memory container with full schema
        do {
            let memoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
            let container = try ModelContainer(for: schema, configurations: [memoryConfig])
            print("✅ ModelContainer: In-memory mode (data temporary)")
            self.container = container
            return
        } catch {
            print("❌ In-memory container failed: \(error.localizedDescription)")
        }
        
        // STRATEGY 3: Try persistent container
        do {
            let persistentConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            let container = try ModelContainer(for: schema, configurations: [persistentConfig])
            print("✅ ModelContainer: Persistent mode (data saved)")
            self.container = container
            return
        } catch {
            print("❌ Persistent container failed: \(error.localizedDescription)")
        }
        
        // STRATEGY 4: Simple default container
        do {
            let container = try ModelContainer(for: schema)
            print("✅ ModelContainer: Default mode")
            self.container = container
            return
        } catch {
            print("❌ Default container failed: \(error.localizedDescription)")
        }
        
        // If ALL strategies fail, set error but DON'T crash
        print("❌ ModelContainer: Failed to create - App will show error screen")
        print("❌ Error details logged above")
        self.error = "Veri yöneticisi başlatılamadı. Lütfen uygulamayı silin ve yeniden yükleyin."
        self.container = nil
    }
}
