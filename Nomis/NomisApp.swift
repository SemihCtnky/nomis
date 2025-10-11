import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // SAFE ModelContainer - CloudKit OTOMATIK SYNC KAPALI!
    let sharedModelContainer: ModelContainer? = {
        // TEST 1: Sadece User modeli (CloudKit .none)
        print("🔍 TEST 1: Sadece User (CloudKit KAPALI)...")
        do {
            let schema1 = Schema([User.self])
            var config1 = ModelConfiguration(schema: schema1)
            config1.cloudKitDatabase = .none  // ← KRITIK: CloudKit otomatik sync KAPALI!
            let container1 = try ModelContainer(for: schema1, configurations: [config1])
            print("✅ User.self çalışıyor!")
        } catch {
            print("❌ User.self FAIL: \(error)")
            return nil
        }
        
        // TEST 2: Core models
        print("🔍 TEST 2: Core models...")
        do {
            let schema2 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self])
            var config2 = ModelConfiguration(schema: schema2)
            config2.cloudKitDatabase = .none
            let container2 = try ModelContainer(for: schema2, configurations: [config2])
            print("✅ Core models çalışıyor!")
        } catch {
            print("❌ Core models FAIL: \(error)")
            return nil
        }
        
        // TEST 3: Sarnel forms
        print("🔍 TEST 3: Sarnel forms...")
        do {
            let schema3 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self, SarnelForm.self, AsitItem.self, FireItem.self])
            var config3 = ModelConfiguration(schema: schema3)
            config3.cloudKitDatabase = .none
            let container3 = try ModelContainer(for: schema3, configurations: [config3])
            print("✅ Sarnel forms çalışıyor!")
        } catch {
            print("❌ Sarnel forms FAIL: \(error)")
            return nil
        }
        
        // TEST 4: Kilit forms
        print("🔍 TEST 4: Kilit forms...")
        do {
            let schema4 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self, SarnelForm.self, AsitItem.self, FireItem.self, KilitToplamaForm.self, KilitItem.self])
            var config4 = ModelConfiguration(schema: schema4)
            config4.cloudKitDatabase = .none
            let container4 = try ModelContainer(for: schema4, configurations: [config4])
            print("✅ Kilit forms çalışıyor!")
        } catch {
            print("❌ Kilit forms FAIL: \(error)")
            return nil
        }
        
        // TEST 5: Legacy Gunluk (FULL)
        print("🔍 TEST 5: Legacy Gunluk (FULL)...")
        do {
            let schema5 = Schema([
                User.self, Note.self, ModelItem.self, CompanyItem.self,
                SarnelForm.self, AsitItem.self, FireItem.self,
                KilitToplamaForm.self, KilitItem.self,
                GunlukForm.self,
                TezgahCard.self, TezgahRow.self, ParcaDeger.self,
                OcakCard.self, OcakRow.self,
                PatlatmaCard.self, CilaCard.self, TamburCard.self,
                MakineKesmeCard.self, TestereKesmeCard.self
            ])
            var config5 = ModelConfiguration(schema: schema5)
            config5.cloudKitDatabase = .none
            let container5 = try ModelContainer(for: schema5, configurations: [config5])
            print("✅ Legacy Gunluk (FULL) çalışıyor!")
        } catch {
            print("❌ Legacy Gunluk (FULL) FAIL: \(error)")
            return nil
        }
        
        // TEST 6: Yeni Gunluk (ŞÜPHELİ!)
        print("🔍 TEST 6: Yeni Gunluk models...")
        do {
            let schema6 = Schema([
                User.self, Note.self, ModelItem.self, CompanyItem.self,
                SarnelForm.self, AsitItem.self, FireItem.self,
                KilitToplamaForm.self, KilitItem.self,
                GunlukForm.self,
                YeniGunlukForm.self, GunlukGunVerisi.self,
                TezgahKarti.self, TezgahSatiri.self,
                CilaKarti.self, OcakKarti.self,
                PatlatmaKarti.self, TamburKarti.self,
                MakineKesmeKarti.self, TestereKesmeKarti.self,
                FireEklemesi.self, GenisletilebilirDeger.self, IslemSatiri.self
            ])
            var config6 = ModelConfiguration(schema: schema6)
            config6.cloudKitDatabase = .none
            let container6 = try ModelContainer(for: schema6, configurations: [config6])
            print("✅ Yeni Gunluk çalışıyor!")
            return container6
        } catch {
            print("❌ Yeni Gunluk FAIL: \(error)")
            return nil
        }
        
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
        
        // Fallback: Try default with CloudKit disabled
        print("🔍 FALLBACK: Default schema with CloudKit disabled...")
        do {
            var config = ModelConfiguration(schema: schema)
            config.cloudKitDatabase = .none  // CloudKit otomatik sync KAPALI!
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("❌ Default failed: \(error)")
        }
        
        // Give up - return nil
        print("💥 CANNOT CREATE ANY ModelContainer")
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
            if let container = sharedModelContainer {
                ContentView()
                    .environmentObject(authManager)
                    .modelContainer(container)
                    .onChange(of: scenePhase) { _, newPhase in
                        handleScenePhaseChange(newPhase)
                    }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Veri Sistemi Başlatılamadı")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Uygulamayı yeniden başlatın veya destek alın.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
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
