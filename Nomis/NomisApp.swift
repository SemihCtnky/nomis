import SwiftUI
import SwiftData

@main
struct NomisApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // SAFE ModelContainer - ASLA CRASH OLMAZ
    let sharedModelContainer: ModelContainer? = {
        // TEST 1: Sadece User modeli
        print("🔍 TEST 1: Sadece User...")
        do {
            let schema1 = Schema([User.self])
            let container1 = try ModelContainer(for: schema1, configurations: [ModelConfiguration(schema: schema1, isStoredInMemoryOnly: true)])
            print("✅ User.self çalışıyor!")
        } catch {
            print("❌ User.self FAIL: \(error)")
            return nil
        }
        
        // TEST 2: Core models
        print("🔍 TEST 2: Core models...")
        do {
            let schema2 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self])
            let container2 = try ModelContainer(for: schema2, configurations: [ModelConfiguration(schema: schema2, isStoredInMemoryOnly: true)])
            print("✅ Core models çalışıyor!")
        } catch {
            print("❌ Core models FAIL: \(error)")
            return nil
        }
        
        // TEST 3: Sarnel forms
        print("🔍 TEST 3: Sarnel forms...")
        do {
            let schema3 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self, SarnelForm.self, AsitItem.self, FireItem.self])
            let container3 = try ModelContainer(for: schema3, configurations: [ModelConfiguration(schema: schema3, isStoredInMemoryOnly: true)])
            print("✅ Sarnel forms çalışıyor!")
        } catch {
            print("❌ Sarnel forms FAIL: \(error)")
            return nil
        }
        
        // TEST 4: Kilit forms
        print("🔍 TEST 4: Kilit forms...")
        do {
            let schema4 = Schema([User.self, Note.self, ModelItem.self, CompanyItem.self, SarnelForm.self, AsitItem.self, FireItem.self, KilitToplamaForm.self, KilitItem.self])
            let container4 = try ModelContainer(for: schema4, configurations: [ModelConfiguration(schema: schema4, isStoredInMemoryOnly: true)])
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
            let container5 = try ModelContainer(for: schema5, configurations: [ModelConfiguration(schema: schema5, isStoredInMemoryOnly: true)])
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
            let container6 = try ModelContainer(for: schema6, configurations: [ModelConfiguration(schema: schema6, isStoredInMemoryOnly: true)])
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
        
        // Try 1: Default
        do {
            return try ModelContainer(for: schema)
        } catch {
            print("❌ Default failed: \(error)")
        }
        
        // Try 2: In-memory
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("❌ In-memory failed: \(error)")
        }
        
        // Try 3: Minimal schema
        do {
            let minimalSchema = Schema([User.self])
            return try ModelContainer(for: minimalSchema)
        } catch {
            print("❌ Even User.self failed: \(error)")
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
