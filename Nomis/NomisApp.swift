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
            self.container = container
            return
        }
        
        // STRATEGY 3: Try persistent container
        let persistentConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            print("✅ ModelContainer: Persistent mode (data saved)")
            self.container = container
            return
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
            self.container = container
            return
        }
        
        // STRATEGY 5: Try simplest possible container
        if let container = try? ModelContainer(for: Schema([User.self])) {
            print("⚠️ ModelContainer: Emergency User mode")
            self.container = container
            return
        }
        
        // If ALL strategies fail, set error but DON'T crash
        print("❌ ModelContainer: Failed to create - App will show error screen")
        self.error = "Veri yöneticisi başlatılamadı. Lütfen uygulamayı yeniden başlatın."
        self.container = nil
    }
}
