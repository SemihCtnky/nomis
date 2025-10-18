import Foundation
import SwiftData
import CloudKit

// MARK: - 🔍 DEBUG LOGGING (TEMPORARY - REMOVE AFTER TESTING!)
private let DEBUG_SYNC = true

private func syncLog(_ message: String, emoji: String = "🔵") {
    if DEBUG_SYNC {
        print("\(emoji) [SYNC] \(message)")
    }
}

/// CloudKit Sync Service
/// Handles bidirectional sync between SwiftData and CloudKit
@MainActor
class CloudKitSyncService: ObservableObject {
    static let shared = CloudKitSyncService()
    
    private let cloudKitManager = CloudKitManager.shared
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var syncStatus: SyncStatus = .idle
    
    // Auto-sync task (debounced)
    private var autoSyncTask: Task<Void, Never>?
    private let autoSyncDelay: TimeInterval = 3.0 // 3 seconds after last change
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
        
        var message: String {
            switch self {
            case .idle: return ""
            case .syncing: return "Senkronize ediliyor..."
            case .success: return "Senkronizasyon başarılı"
            case .error(let msg): return "Hata: \(msg)"
            }
        }
    }
    
    private init() {
        // Load last sync date from UserDefaults
        if let lastSync = UserDefaults.standard.object(forKey: "lastCloudKitSync") as? Date {
            self.lastSyncDate = lastSync
        }
    }
    
    deinit {
        autoSyncTask?.cancel()
    }
    
    // MARK: - Auto Sync (Debounced)
    
    /// Trigger auto-sync after a delay (debounced)
    /// Call this every time data changes
    func scheduleAutoSync(modelContext: ModelContext) {
        syncLog("⏱️  AUTO-SYNC SCHEDULED: Will trigger in \(autoSyncDelay)s", emoji: "⏱️")
        
        // Cancel existing task
        autoSyncTask?.cancel()
        
        // Schedule new task with sleep (no Sendable warning!)
        autoSyncTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Wait for debounce delay
            do {
                try await Task.sleep(for: .seconds(self.autoSyncDelay))
            } catch {
                // Task was cancelled, exit gracefully
                syncLog("⏱️  AUTO-SYNC CANCELLED", emoji: "🚫")
                return
            }
            
            syncLog("⏱️  AUTO-SYNC TRIGGERED: Starting incremental sync", emoji: "🚀")
            
            // Perform sync after delay (modelContext captured in MainActor context - safe!)
            await self.performIncrementalSync(modelContext: modelContext)
        }
    }
    
    /// Cancel auto-sync task
    func cancelAutoSync() {
        autoSyncTask?.cancel()
        autoSyncTask = nil
    }
    
    // MARK: - Full Sync (Initial or Manual)
    
    /// Perform full bidirectional sync
    func performFullSync(modelContext: ModelContext) async {
        guard !isSyncing else {
            syncLog("🔄 FULL SYNC: Already syncing, skipping", emoji: "⏭️")
            return
        }
        
        syncLog("🔄 FULL SYNC START", emoji: "🚀")
        
        isSyncing = true
        syncStatus = .syncing
        
        do {
            // Check iCloud account status
            let accountStatus = try await cloudKitManager.checkAccountStatus()
            guard accountStatus == .available else {
                throw SyncError.iCloudNotAvailable
            }
            
            // Sync all models
            try await syncGunlukForms(modelContext: modelContext)
            try await syncSarnelForms(modelContext: modelContext)
            try await syncKilitForms(modelContext: modelContext)
            try await syncNotes(modelContext: modelContext)
            try await syncModelItems(modelContext: modelContext)
            try await syncCompanyItems(modelContext: modelContext)
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudKitSync")
            
            syncStatus = .success
            syncError = nil
            
            syncLog("🔄 FULL SYNC COMPLETE: SUCCESS ✅", emoji: "🎉")
            
            // Reset success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if syncStatus == .success {
                    syncStatus = .idle
                }
            }
            
        } catch {
            syncError = error.localizedDescription
            syncStatus = .error(error.localizedDescription)
            syncLog("🔄 FULL SYNC FAILED: \(error.localizedDescription)", emoji: "❌")
        }
        
        isSyncing = false
    }
    
    // MARK: - Incremental Sync
    
    /// Perform incremental sync (only changes since last sync)
    func performIncrementalSync(modelContext: ModelContext) async {
        guard !isSyncing, let lastSync = lastSyncDate else {
            // No previous sync, do full sync
            syncLog("🔁 INCREMENTAL SYNC: No lastSync, doing full sync", emoji: "⏩")
            await performFullSync(modelContext: modelContext)
            return
        }
        
        syncLog("🔁 INCREMENTAL SYNC START: Since \(lastSync)", emoji: "🚀")
        
        isSyncing = true
        syncStatus = .syncing
        
        do {
            // Fetch only records modified after last sync
            try await syncGunlukFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncSarnelFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncKilitFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncNotesIncremental(modelContext: modelContext, since: lastSync)
            
            // Model ve Firma her zaman sync (az veri oldugu icin)
            try await syncModelItems(modelContext: modelContext)
            try await syncCompanyItems(modelContext: modelContext)
            
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudKitSync")
            
            syncStatus = .success
            syncError = nil
            
            syncLog("🔁 INCREMENTAL SYNC COMPLETE: SUCCESS ✅", emoji: "🎉")
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if syncStatus == .success {
                    syncStatus = .idle
                }
            }
            
        } catch {
            syncError = error.localizedDescription
            syncStatus = .error(error.localizedDescription)
            syncLog("🔁 INCREMENTAL SYNC FAILED: \(error.localizedDescription)", emoji: "❌")
        }
        
        isSyncing = false
    }
    
    // MARK: - Upload Single Record
    
    /// Upload a single Gunluk form
    func uploadGunlukForm(_ form: YeniGunlukForm) async throws {
        let record = form.toCKRecord()
        try await cloudKitManager.uploadRecord(record)
    }
    
    /// Upload a single Sarnel form
    func uploadSarnelForm(_ form: SarnelForm) async throws {
        let record = form.toCKRecord()
        try await cloudKitManager.uploadRecord(record)
    }
    
    /// Upload a single Kilit form
    func uploadKilitForm(_ form: KilitToplamaForm) async throws {
        let record = form.toCKRecord()
        try await cloudKitManager.uploadRecord(record)
    }
    
    /// Upload a single Note
    func uploadNote(_ note: Note) async throws {
        let record = note.toCKRecord()
        try await cloudKitManager.uploadRecord(record)
    }
    
    // MARK: - Delete Single Record
    
    /// Delete a form from CloudKit
    func deleteRecord(id: UUID, recordType: CloudKitManager.RecordType) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await cloudKitManager.deleteRecord(withID: recordID)
    }
    
    // MARK: - Private Sync Functions
    
    private func syncGunlukForms(modelContext: ModelContext) async throws {
        // 1. Upload local forms to CloudKit
        let localForms = try modelContext.fetch(FetchDescriptor<YeniGunlukForm>())
        #if DEBUG
        print("📤 UPLOAD: \(localForms.count) YeniGunlukForm found locally")
        #endif
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            #if DEBUG
            print("✅ UPLOAD SUCCESS: \(records.count) YeniGunlukForm uploaded to CloudKit")
            #endif
        }
        
        // 2. Download CloudKit forms
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .gunlukForm)
        #if DEBUG
        print("📥 DOWNLOAD: \(cloudRecords.count) YeniGunlukForm fetched from CloudKit")
        #endif
        
        // 3. Merge: Update local or insert new
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // Update existing - ensure weekly days exist
                existingForm.updateFromRecord(record, modelContext: modelContext)
                if existingForm.gunlukVeriler.isEmpty {
                    existingForm.createWeeklyDays()
                }
            } else {
                // Insert new from CloudKit
                if let form = createGunlukForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncSarnelForms(modelContext: ModelContext) async throws {
        let localForms = try modelContext.fetch(FetchDescriptor<SarnelForm>())
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .sarnelForm)
        
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingForm.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let form = createSarnelForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncKilitForms(modelContext: ModelContext) async throws {
        let localForms = try modelContext.fetch(FetchDescriptor<KilitToplamaForm>())
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .kilitForm)
        
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingForm.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let form = createKilitForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncNotes(modelContext: ModelContext) async throws {
        let localNotes = try modelContext.fetch(FetchDescriptor<Note>())
        let records = localNotes.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .note)
        
        for record in cloudRecords {
            if let existingNote = localNotes.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingNote.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let note = createNote(from: record, modelContext: modelContext) {
                    modelContext.insert(note)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncModelItems(modelContext: ModelContext) async throws {
        let localItems = try modelContext.fetch(FetchDescriptor<ModelItem>())
        syncLog("📤 Model UPLOAD: \(localItems.count) items found locally", emoji: "📤")
        
        let records = localItems.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Model UPLOAD: \(records.count) items uploaded", emoji: "✅")
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .modelItem)
        syncLog("📥 Model DOWNLOAD: \(cloudRecords.count) items from CloudKit", emoji: "📥")
        
        for record in cloudRecords {
            if let existingItem = localItems.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingItem.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let item = createModelItem(from: record) {
                    modelContext.insert(item)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncCompanyItems(modelContext: ModelContext) async throws {
        let localItems = try modelContext.fetch(FetchDescriptor<CompanyItem>())
        syncLog("📤 Firma UPLOAD: \(localItems.count) items found locally", emoji: "📤")
        
        let records = localItems.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Firma UPLOAD: \(records.count) items uploaded", emoji: "✅")
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .companyItem)
        syncLog("📥 Firma DOWNLOAD: \(cloudRecords.count) items from CloudKit", emoji: "📥")
        
        for record in cloudRecords {
            if let existingItem = localItems.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingItem.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let item = createCompanyItem(from: record) {
                    modelContext.insert(item)
                }
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Incremental Sync (only changes)
    
    private func syncGunlukFormsIncremental(modelContext: ModelContext, since date: Date) async throws {
        // 1. UPLOAD: Local forms to CloudKit
        let localForms = try modelContext.fetch(FetchDescriptor<YeniGunlukForm>())
        syncLog("📤 Gunluk UPLOAD: \(localForms.count) forms found locally", emoji: "📤")
        
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Gunluk UPLOAD: \(records.count) forms uploaded", emoji: "✅")
        }
        
        // 2. DOWNLOAD: Fetch only records modified after last sync
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .gunlukForm)
        syncLog("📥 Gunluk DOWNLOAD: \(cloudRecords.count) new/modified forms", emoji: "📥")
        
        // 3. MERGE: Update existing or insert new
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // ✅ Update existing form with full nested data from CloudKit
                existingForm.updateFromRecord(record, modelContext: modelContext)
                
                // ✅ CRITICAL: Insert all nested items into ModelContext
                for gunVerisi in existingForm.gunlukVeriler {
                    modelContext.insert(gunVerisi)
                    // Insert all cards within each day
                    if let tezgah = gunVerisi.tezgahKarti1 {
                        modelContext.insert(tezgah)
                        // TezgahSatiri uses girisValue/cikisValue (singular Double, not arrays)
                        for satir in tezgah.satirlar {
                            modelContext.insert(satir)
                        }
                        for fire in tezgah.fireEklemeleri {
                            modelContext.insert(fire)
                        }
                    }
                    if let tezgah = gunVerisi.tezgahKarti2 {
                        modelContext.insert(tezgah)
                        // TezgahSatiri uses girisValue/cikisValue (singular Double, not arrays)
                        for satir in tezgah.satirlar {
                            modelContext.insert(satir)
                        }
                        for fire in tezgah.fireEklemeleri {
                            modelContext.insert(fire)
                        }
                    }
                    if let cila = gunVerisi.cilaKarti {
                        modelContext.insert(cila)
                        for satir in cila.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                    if let ocak = gunVerisi.ocakKarti {
                        modelContext.insert(ocak)
                        for satir in ocak.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                    if let patlatma = gunVerisi.patlatmaKarti {
                        modelContext.insert(patlatma)
                        for satir in patlatma.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                    if let tambur = gunVerisi.tamburKarti {
                        modelContext.insert(tambur)
                        for satir in tambur.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                    if let makineKesme = gunVerisi.makineKesmeKarti1 {
                        modelContext.insert(makineKesme)
                        for satir in makineKesme.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                    if let testereKesme = gunVerisi.testereKesmeKarti1 {
                        modelContext.insert(testereKesme)
                        for satir in testereKesme.satirlar {
                            modelContext.insert(satir)
                            for deger in satir.girisValues {
                                modelContext.insert(deger)
                            }
                            for deger in satir.cikisValues {
                                modelContext.insert(deger)
                            }
                        }
                    }
                }
                
                syncLog("🔄 Gunluk: Updated existing form with CloudKit data", emoji: "🔄")
                
                // Ensure weekly days exist after update
                if existingForm.gunlukVeriler.isEmpty {
                    existingForm.createWeeklyDays()
                }
            } else {
                // Insert new form
                if let form = createGunlukForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                    syncLog("✅ Gunluk: Inserted new form from CloudKit", emoji: "✅")
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncSarnelFormsIncremental(modelContext: ModelContext, since date: Date) async throws {
        // 1. UPLOAD: Local forms to CloudKit
        let localForms = try modelContext.fetch(FetchDescriptor<SarnelForm>())
        syncLog("📤 Sarnel UPLOAD: \(localForms.count) forms found locally", emoji: "📤")
        
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Sarnel UPLOAD: \(records.count) forms uploaded", emoji: "✅")
        }
        
        // 2. DOWNLOAD: Fetch only records modified after last sync
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .sarnelForm)
        syncLog("📥 Sarnel DOWNLOAD: \(cloudRecords.count) new/modified forms", emoji: "📥")
        
        // 3. MERGE: Update existing or insert new
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // ✅ Update existing form with full nested data from CloudKit
                existingForm.updateFromRecord(record, modelContext: modelContext)
                
                // ✅ CRITICAL: Insert all nested items into ModelContext
                for item in existingForm.asitCikislari {
                    modelContext.insert(item)
                }
                for item in existingForm.extraFireItems {
                    modelContext.insert(item)
                }
                
                syncLog("🔄 Sarnel: Updated existing form with CloudKit data", emoji: "🔄")
            } else {
                // Insert new form
                if let form = createSarnelForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                    syncLog("✅ Sarnel: Inserted new form from CloudKit", emoji: "✅")
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncKilitFormsIncremental(modelContext: ModelContext, since date: Date) async throws {
        // 1. UPLOAD: Local forms to CloudKit
        let localForms = try modelContext.fetch(FetchDescriptor<KilitToplamaForm>())
        syncLog("📤 Kilit UPLOAD: \(localForms.count) forms found locally", emoji: "📤")
        
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Kilit UPLOAD: \(records.count) forms uploaded", emoji: "✅")
        }
        
        // 2. DOWNLOAD: Fetch only records modified after last sync
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .kilitForm)
        syncLog("📥 Kilit DOWNLOAD: \(cloudRecords.count) new/modified forms", emoji: "📥")
        
        // 3. MERGE: Update existing or insert new
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // ✅ Update existing form with full nested data from CloudKit
                existingForm.updateFromRecord(record, modelContext: modelContext)
                
                // ✅ CRITICAL: Insert all nested items into ModelContext
                for item in existingForm.kasaItems {
                    modelContext.insert(item)
                }
                for item in existingForm.dilItems {
                    modelContext.insert(item)
                }
                for item in existingForm.yayItems {
                    modelContext.insert(item)
                }
                for item in existingForm.kilitItems {
                    modelContext.insert(item)
                }
                
                syncLog("🔄 Kilit: Updated existing form with CloudKit data", emoji: "🔄")
            } else {
                // Insert new form
                if let form = createKilitForm(from: record, modelContext: modelContext) {
                    modelContext.insert(form)
                    syncLog("✅ Kilit: Inserted new form from CloudKit", emoji: "✅")
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncNotesIncremental(modelContext: ModelContext, since date: Date) async throws {
        // 1. UPLOAD: Local notes to CloudKit
        let localNotes = try modelContext.fetch(FetchDescriptor<Note>())
        syncLog("📤 Notes UPLOAD: \(localNotes.count) notes found locally", emoji: "📤")
        
        let records = localNotes.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
            syncLog("✅ Notes UPLOAD: \(records.count) notes uploaded", emoji: "✅")
        }
        
        // 2. DOWNLOAD: Fetch only records modified after last sync
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .note)
        syncLog("📥 Notes DOWNLOAD: \(cloudRecords.count) new/modified notes", emoji: "📥")
        
        // 3. MERGE: Update local or insert new
        for record in cloudRecords {
            if let existingNote = localNotes.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingNote.updateFromRecord(record, modelContext: modelContext)
            } else {
                if let note = createNote(from: record, modelContext: modelContext) {
                    modelContext.insert(note)
                }
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Create from CKRecord
    
    private func createGunlukForm(from record: CKRecord, modelContext: ModelContext) -> YeniGunlukForm? {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        
        let form = YeniGunlukForm()
        form.id = id
        form.updateFromRecord(record, modelContext: modelContext)
        
        // Create weekly days if they don't exist
        // This is crucial to prevent crashes when displaying forms synced from CloudKit
        if form.gunlukVeriler.isEmpty {
            form.createWeeklyDays()
        }
        
        return form
    }
    
    private func createSarnelForm(from record: CKRecord, modelContext: ModelContext) -> SarnelForm? {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        
        // Get karatAyar from JSON or use default
        var karatAyar = 0
        if let sarnelJSON = record["sarnelDataJSON"] as? String,
           let jsonData = sarnelJSON.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let ayar = dict["karatAyar"] as? Int {
            karatAyar = ayar
        }
        
        let form = SarnelForm(karatAyar: karatAyar)
        form.id = id
        form.updateFromRecord(record, modelContext: modelContext)
        return form
    }
    
    private func createKilitForm(from record: CKRecord, modelContext: ModelContext) -> KilitToplamaForm? {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        
        let form = KilitToplamaForm()
        form.id = id
        form.updateFromRecord(record, modelContext: modelContext)
        return form
    }
    
    private func createNote(from record: CKRecord, modelContext: ModelContext) -> Note? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String,
              let text = record["text"] as? String else { return nil }
        
        let note = Note(title: title, text: text)
        note.id = id
        note.updateFromRecord(record, modelContext: modelContext)
        return note
    }
    
    private func createModelItem(from record: CKRecord) -> ModelItem? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String else { return nil }
        
        let item = ModelItem(name: name)
        item.id = id
        return item
    }
    
    private func createCompanyItem(from record: CKRecord) -> CompanyItem? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String else { return nil }
        
        let item = CompanyItem(name: name)
        item.id = id
        return item
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case networkError
    case conflictError
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud hesabı mevcut değil. Lütfen Ayarlar > Apple ID > iCloud'dan giriş yapın."
        case .networkError:
            return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin."
        case .conflictError:
            return "Senkronizasyon çakışması oluştu."
        }
    }
}

