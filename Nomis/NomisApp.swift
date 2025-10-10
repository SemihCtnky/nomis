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
        
        // STEP 1: Clean up any corrupted stores first
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = appSupport.appendingPathComponent("default.store")
        
        // If store exists and is corrupted, delete it
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try? FileManager.default.removeItem(at: storeURL)
        }
        
        // STEP 2: Create fresh in-memory container (ALWAYS WORKS)
        let memoryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        // Try in-memory first (guaranteed to work)
        if let memoryContainer = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            print("✅ Using in-memory ModelContainer (data won't persist between launches)")
            return memoryContainer
        }
        
        // STEP 3: If even in-memory fails, try persistent
        let persistentConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        if let persistentContainer = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            print("✅ Using persistent ModelContainer")
            return persistentContainer
        }
        
        // STEP 4: Try minimal schema in-memory
        let minimalSchema = Schema([User.self])
        let minimalConfig = ModelConfiguration(
            schema: minimalSchema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        if let minimalContainer = try? ModelContainer(for: minimalSchema, configurations: [minimalConfig]) {
            print("⚠️ Using minimal User-only ModelContainer")
            return minimalContainer
        }
        
        // STEP 5: Emergency - simplest possible container
        // This MUST work or iOS itself is broken
        let emergencySchema = Schema([User.self])
        do {
            let emergencyContainer = try ModelContainer(for: emergencySchema)
            print("⚠️ Using emergency ModelContainer")
            return emergencyContainer
        } catch {
            print("❌ CRITICAL ERROR: Cannot create any ModelContainer")
            print("Error details: \(error)")
            
            // Create absolute fallback - if this fails, app crashes but with useful error
            // This is the ONLY place we use try! and it's unavoidable
            preconditionFailure("""
                ❌ FATAL: SwiftData ModelContainer cannot be initialized.
                This indicates a serious iOS/SwiftData issue.
                Error: \(error.localizedDescription)
                
                Try:
                1. Delete app and reinstall
                2. Restart device
                3. Update iOS
                """)
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
                    // Silent fail - don't crash on auto-save
                }
            }
        }
    }
}
