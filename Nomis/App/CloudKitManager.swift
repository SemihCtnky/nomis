import Foundation
import CloudKit
import SwiftData

/// CloudKit Public Database Manager
/// Manages sync between local SwiftData and CloudKit Public Database
@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // CloudKit Container and Database
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private var isAvailable = false
    
    // Sync state
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // Record types
    enum RecordType: String {
        case gunlukForm = "YeniGunlukForm"
        case sarnelForm = "SarnelForm"
        case kilitForm = "KilitToplamaForm"
        case note = "Note"
        case modelItem = "ModelItem"
        case companyItem = "CompanyItem"
    }
    
    private init() {
        // Use specific container v2 (clean container without schema issues)
        self.container = CKContainer(identifier: "iCloud.com.semihctnky.kilitcim.v2")
        self.publicDatabase = container.publicCloudDatabase
        
        // Detect simulator - CloudKit might not work properly
        #if targetEnvironment(simulator)
        print("⚠️ CloudKit: Running on simulator - iCloud sync may not work")
        #endif
        
        // isAvailable will be checked when first operation is called
    }
    
    // Lazy check availability on first use
    private func checkAndUpdateAvailability() async {
        guard !isAvailable else { return } // Already checked
        
        // Simulator check - be more lenient
        #if targetEnvironment(simulator)
        print("⚠️ CloudKit: Simulator detected - sync may be unavailable")
        #endif
        
        print("🔍 CloudKit: Checking account status...")
        print("🔍 CloudKit: Container ID: \(container.containerIdentifier ?? "nil")")
        
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.isAvailable = (status == .available)
                print("🔍 CloudKit: Account status: \(status.rawValue)")
                if !self.isAvailable {
                    print("❌ CloudKit: Account not available - status: \(status.rawValue)")
                    if status == .noAccount {
                        print("❌ CloudKit: No iCloud account signed in")
                    } else if status == .restricted {
                        print("❌ CloudKit: iCloud access restricted")
                    } else if status == .couldNotDetermine {
                        print("❌ CloudKit: Could not determine account status")
                    }
                } else {
                    print("✅ CloudKit: Account available and ready")
                }
            }
        } catch {
            await MainActor.run {
                self.isAvailable = false
                print("❌ CloudKit: Check failed - \(error)")
                print("❌ CloudKit: Error description: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if CloudKit is available (simulator might not have iCloud)
    private func ensureAvailable() throws {
        guard isAvailable else {
            #if targetEnvironment(simulator)
            throw NSError(domain: "CloudKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "⚠️ Simulator'da iCloud sync kullanılamıyor.\n\nGerçek cihazda test edin."
            ])
            #else
            throw NSError(domain: "CloudKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "❌ iCloud bağlantısı kurulamadı.\n\nÇözüm:\n1. Ayarlar → [İsminiz] → iCloud\n2. iCloud Drive: AÇIK\n3. Wi-Fi/mobil veri kontrol edin"
            ])
            #endif
        }
    }
    
    // MARK: - Account Status
    
    /// Check if user is signed in to iCloud
    func checkAccountStatus() async throws -> CKAccountStatus {
        await checkAndUpdateAvailability()
        return try await container.accountStatus()
    }
    
    // MARK: - Upload (Local → CloudKit)
    
    /// Upload a record to CloudKit
    func uploadRecord(_ record: CKRecord) async throws {
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let _ = try await publicDatabase.save(record)
            lastSyncDate = Date()
            syncError = nil
        } catch {
            syncError = "Upload failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Upload multiple records in batch
    func uploadRecords(_ records: [CKRecord]) async throws {
        guard !records.isEmpty else { return }
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        isSyncing = true
        defer { isSyncing = false }
        
        // CloudKit batch limit is 400 records
        let batches = records.chunked(into: 400)
        
        for batch in batches {
            let operation = CKModifyRecordsOperation(recordsToSave: batch, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                publicDatabase.add(operation)
            }
        }
        
        lastSyncDate = Date()
        syncError = nil
    }
    
    // MARK: - Download (CloudKit → Local)
    
    /// Fetch all records of a specific type
    func fetchRecords(ofType recordType: RecordType) async throws -> [CKRecord] {
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        // Simple query without sort descriptors to avoid queryable field errors
        let query = CKQuery(recordType: recordType.rawValue, predicate: NSPredicate(value: true))
        // Removed sort descriptor to prevent "recordName marked queryable" error
        
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        
        repeat {
            let (records, nextCursor) = try await fetchRecordsWithCursor(query: query, cursor: cursor)
            allRecords.append(contentsOf: records)
            cursor = nextCursor
        } while cursor != nil
        
        // Sort locally by modification date if available
        return allRecords.sorted { (record1, record2) in
            let date1 = record1.modificationDate ?? record1.creationDate ?? Date.distantPast
            let date2 = record2.modificationDate ?? record2.creationDate ?? Date.distantPast
            return date1 > date2
        }
    }
    
    private func fetchRecordsWithCursor(query: CKQuery, cursor: CKQueryOperation.Cursor?) async throws -> ([CKRecord], CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { continuation in
            let operation: CKQueryOperation
            
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            operation.resultsLimit = 100
            var fetchedRecords: [CKRecord] = []
            
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                case .failure:
                    break
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    continuation.resume(returning: (fetchedRecords, cursor))
                case .failure(let error):
                    // Check if this is the "queryable" field error
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("queryable") || errorMessage.contains("recordName") {
                        let customError = NSError(
                            domain: "CloudKit",
                            code: -2,
                            userInfo: [
                                NSLocalizedDescriptionKey: """
                                ⚠️ CloudKit yapılandırma hatası tespit edildi.
                                
                                Çözüm:
                                1. https://icloud.developer.apple.com/dashboard adresine gidin
                                2. Container: iCloud.com.semihctnky.kilitcim seçin
                                3. Schema → Development → Record Types
                                4. TÜM custom record type'ları silin (Note, SarnelForm, vb.)
                                5. Sadece "Users" record type'ı kalacak
                                6. Production'da da aynısını yapın
                                7. Uygulamayı tekrar başlatın
                                
                                İlk sync'te schema otomatik oluşturulacak.
                                """
                            ]
                        )
                        continuation.resume(throwing: customError)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            publicDatabase.add(operation)
        }
    }
    
    // MARK: - Delete
    
    /// Delete a record from CloudKit
    func deleteRecord(withID recordID: CKRecord.ID) async throws {
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let _ = try await publicDatabase.deleteRecord(withID: recordID)
            lastSyncDate = Date()
            syncError = nil
        } catch {
            syncError = "Delete failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Delete multiple records
    func deleteRecords(withIDs recordIDs: [CKRecord.ID]) async throws {
        guard !recordIDs.isEmpty else { return }
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        isSyncing = true
        defer { isSyncing = false }
        
        let batches = recordIDs.chunked(into: 400)
        
        for batch in batches {
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: batch)
            operation.qualityOfService = .userInitiated
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                publicDatabase.add(operation)
            }
        }
        
        lastSyncDate = Date()
        syncError = nil
    }
    
    // MARK: - Sync Changes (Incremental)
    
    /// Fetch only records modified after a certain date
    func fetchRecordsModifiedAfter(_ date: Date, ofType recordType: RecordType) async throws -> [CKRecord] {
        await checkAndUpdateAvailability()
        try ensureAvailable()
        
        let predicate = NSPredicate(format: "modificationDate > %@", date as NSDate)
        let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)
        // Removed sort descriptor to prevent "recordName marked queryable" error
        
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        
        repeat {
            let (records, nextCursor) = try await fetchRecordsWithCursor(query: query, cursor: cursor)
            allRecords.append(contentsOf: records)
            cursor = nextCursor
        } while cursor != nil
        
        // Sort locally by modification date
        return allRecords.sorted { (record1, record2) in
            let date1 = record1.modificationDate ?? Date.distantPast
            let date2 = record2.modificationDate ?? Date.distantPast
            return date1 > date2
        }
    }
}

// MARK: - Helper Extensions

extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

