import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // ModelContainer - CloudKit otomatik sync devre dışı (manuel sync kullanıyoruz)
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
            TezgahCard.self,
            TezgahRow.self,
            ParcaDeger.self,
            OcakCard.self,
            OcakRow.self,
            PatlatmaCard.self,
            CilaCard.self,
            TamburCard.self,
            MakineKesmeCard.self,
            TestereKesmeCard.self,
            
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
        
        // CloudKit otomatik sync KAPALI (.none) - manuel sync kullanıyoruz
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch let persistentError {
            // Fallback: in-memory database
            print("⚠️ Persistent storage failed: \(persistentError)")
            do {
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                print("✅ Using in-memory database as fallback")
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch let inMemoryError {
                // Son çare: Minimal schema ile in-memory
                print("❌ In-memory also failed: \(inMemoryError)")
                let minimalSchema = Schema([User.self])
                do {
                    let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                    print("⚠️ Using minimal schema (User only)")
                    return try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
                } catch {
                    // Bu hiçbir zaman olmamalı ama güvenlik için
                    fatalError("CRITICAL: Cannot initialize any ModelContainer: \(error)")
                }
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
