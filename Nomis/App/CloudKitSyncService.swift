import Foundation
import SwiftData
import CloudKit

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
    
    // MARK: - Full Sync (Initial or Manual)
    
    /// Perform full bidirectional sync
    func performFullSync(modelContext: ModelContext) async {
        guard !isSyncing else { return }
        
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
        }
        
        isSyncing = false
    }
    
    // MARK: - Incremental Sync
    
    /// Perform incremental sync (only changes since last sync)
    func performIncrementalSync(modelContext: ModelContext) async {
        guard !isSyncing, let lastSync = lastSyncDate else {
            // No previous sync, do full sync
            await performFullSync(modelContext: modelContext)
            return
        }
        
        isSyncing = true
        syncStatus = .syncing
        
        do {
            // Fetch only records modified after last sync
            try await syncGunlukFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncSarnelFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncKilitFormsIncremental(modelContext: modelContext, since: lastSync)
            try await syncNotesIncremental(modelContext: modelContext, since: lastSync)
            
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudKitSync")
            
            syncStatus = .success
            syncError = nil
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if syncStatus == .success {
                    syncStatus = .idle
                }
            }
            
        } catch {
            syncError = error.localizedDescription
            syncStatus = .error(error.localizedDescription)
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
        let records = localForms.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        // 2. Download CloudKit forms
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .gunlukForm)
        
        // 3. Merge: Update local or insert new
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // Update existing - ensure weekly days exist
                existingForm.updateFromRecord(record)
                if existingForm.gunlukVeriler.isEmpty {
                    existingForm.createWeeklyDays()
                }
            } else {
                // Insert new from CloudKit
                if let form = createGunlukForm(from: record) {
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
                existingForm.updateFromRecord(record)
            } else {
                if let form = createSarnelForm(from: record) {
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
                existingForm.updateFromRecord(record)
            } else {
                if let form = createKilitForm(from: record) {
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
                existingNote.updateFromRecord(record)
            } else {
                if let note = createNote(from: record) {
                    modelContext.insert(note)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncModelItems(modelContext: ModelContext) async throws {
        let localItems = try modelContext.fetch(FetchDescriptor<ModelItem>())
        let records = localItems.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .modelItem)
        
        for record in cloudRecords {
            if let existingItem = localItems.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingItem.updateFromRecord(record)
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
        let records = localItems.map { $0.toCKRecord() }
        if !records.isEmpty {
            try await cloudKitManager.uploadRecords(records)
        }
        
        let cloudRecords = try await cloudKitManager.fetchRecords(ofType: .companyItem)
        
        for record in cloudRecords {
            if let existingItem = localItems.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingItem.updateFromRecord(record)
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
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .gunlukForm)
        let localForms = try modelContext.fetch(FetchDescriptor<YeniGunlukForm>())
        
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingForm.updateFromRecord(record)
                // Ensure weekly days exist after update
                if existingForm.gunlukVeriler.isEmpty {
                    existingForm.createWeeklyDays()
                }
            } else {
                if let form = createGunlukForm(from: record) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncSarnelFormsIncremental(modelContext: ModelContext, since date: Date) async throws {
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .sarnelForm)
        let localForms = try modelContext.fetch(FetchDescriptor<SarnelForm>())
        
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingForm.updateFromRecord(record)
            } else {
                if let form = createSarnelForm(from: record) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncKilitFormsIncremental(modelContext: ModelContext, since date: Date) async throws {
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .kilitForm)
        let localForms = try modelContext.fetch(FetchDescriptor<KilitToplamaForm>())
        
        for record in cloudRecords {
            if let existingForm = localForms.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingForm.updateFromRecord(record)
            } else {
                if let form = createKilitForm(from: record) {
                    modelContext.insert(form)
                }
            }
        }
        
        try modelContext.save()
    }
    
    private func syncNotesIncremental(modelContext: ModelContext, since date: Date) async throws {
        let cloudRecords = try await cloudKitManager.fetchRecordsModifiedAfter(date, ofType: .note)
        let localNotes = try modelContext.fetch(FetchDescriptor<Note>())
        
        for record in cloudRecords {
            if let existingNote = localNotes.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                existingNote.updateFromRecord(record)
            } else {
                if let note = createNote(from: record) {
                    modelContext.insert(note)
                }
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Create from CKRecord
    
    private func createGunlukForm(from record: CKRecord) -> YeniGunlukForm? {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        
        let form = YeniGunlukForm()
        form.id = id
        form.updateFromRecord(record)
        
        // Create weekly days if they don't exist
        // This is crucial to prevent crashes when displaying forms synced from CloudKit
        if form.gunlukVeriler.isEmpty {
            form.createWeeklyDays()
        }
        
        return form
    }
    
    private func createSarnelForm(from record: CKRecord) -> SarnelForm? {
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
        form.updateFromRecord(record)
        return form
    }
    
    private func createKilitForm(from record: CKRecord) -> KilitToplamaForm? {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        
        let form = KilitToplamaForm()
        form.id = id
        form.updateFromRecord(record)
        return form
    }
    
    private func createNote(from record: CKRecord) -> Note? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String,
              let text = record["text"] as? String else { return nil }
        
        let note = Note(title: title, text: text)
        note.id = id
        note.updateFromRecord(record)
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

