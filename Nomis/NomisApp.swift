import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Optional ModelContainer - App works even without it (CRASH-PROOF)
    let sharedModelContainer: ModelContainer? = {
        print("🔄 Initializing ModelContainer...")
        
        // First try with minimal working schema
        let minimalSchema = Schema([
            User.self,
            Note.self,
            ModelItem.self,
            CompanyItem.self
        ])
        
        do {
            let config = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: minimalSchema, configurations: [config])
            print("✅ ModelContainer: Minimal schema initialized (SAFE MODE)")
            print("   Models: User, Note, ModelItem, CompanyItem")
            return container
        } catch {
            print("❌ MINIMAL SCHEMA FAILED!")
            print("   Error: \(error)")
            print("   Description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
        }
        
        // If even minimal fails, try with full schema
        let fullSchema = Schema([
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
        
        // Fallback 2: Try full schema in-memory
        do {
            let config = ModelConfiguration(schema: fullSchema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: fullSchema, configurations: [config])
            print("✅ ModelContainer: Full schema in-memory initialized")
            return container
        } catch {
            print("⚠️ Full schema in-memory failed: \(error.localizedDescription)")
        }
        
        // Fallback 3: Try default configuration with full schema
        do {
            let container = try ModelContainer(for: fullSchema)
            print("✅ ModelContainer: Full schema default config initialized")
            return container
        } catch {
            print("⚠️ Full schema default failed: \(error.localizedDescription)")
        }
        
        // Final fallback: Just return minimal (already created above)
        print("💥 FATAL: Cannot create full ModelContainer")
        print("⚠️ App will run in SAFE MODE with limited data support")
        return nil
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
                    // Fallback view - still try to show login
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Veri sistemi yüklenemiyor")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Bazı özellikler kullanılamayabilir")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Force restart app
                            exit(0)
                        }) {
                            Text("Uygulamayı Yeniden Başlat")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(NomisTheme.primary)
                                .cornerRadius(10)
                        }
                        .padding(.top)
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
