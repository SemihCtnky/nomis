import Foundation
import CloudKit
import SwiftData

// MARK: - CloudKit Record Conversion Protocol

protocol CloudKitConvertible {
    /// Convert SwiftData model to CloudKit record
    func toCKRecord() -> CKRecord
    
    /// Update SwiftData model from CloudKit record (non-mutating for classes)
    func updateFromRecord(_ record: CKRecord)
    
    /// Record type name
    static var recordType: String { get }
}

// MARK: - YeniGunlukForm CloudKit Extension (Simplified - Metadata Only)

extension YeniGunlukForm: CloudKitConvertible {
    static var recordType: String { "YeniGunlukForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        // Basic metadata
        record["baslamaTarihi"] = baslamaTarihi as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedAt"] = lastEditedAt as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        record["isCompleted"] = (isCompleted ? 1 : 0) as CKRecordValue
        
        // Encode count of days/cards as metadata (not full content to avoid complexity)
        record["gunSayisi"] = gunlukVeriler.count as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let lastEditedAt = record["lastEditedAt"] as? Date {
            self.lastEditedAt = lastEditedAt
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
        if let isCompletedInt = record["isCompleted"] as? Int {
            self.isCompleted = isCompletedInt == 1
        }
    }
}

// MARK: - SarnelForm CloudKit Extension

extension SarnelForm: CloudKitConvertible {
    static var recordType: String { "SarnelForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["karatAyar"] = karatAyar as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        if let girisAltin = girisAltin {
            record["girisAltin"] = girisAltin as CKRecordValue
        }
        if let cikisAltin = cikisAltin {
            record["cikisAltin"] = cikisAltin as CKRecordValue
        }
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let karatAyar = record["karatAyar"] as? Int {
            self.karatAyar = karatAyar
        }
        if let girisAltin = record["girisAltin"] as? Double {
            self.girisAltin = girisAltin
        }
        if let cikisAltin = record["cikisAltin"] as? Double {
            self.cikisAltin = cikisAltin
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
    }
}

// MARK: - KilitToplamaForm CloudKit Extension

extension KilitToplamaForm: CloudKitConvertible {
    static var recordType: String { "KilitToplamaForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["model"] = (model ?? "") as CKRecordValue
        record["firma"] = (firma ?? "") as CKRecordValue
        record["ayar"] = (ayar ?? "") as CKRecordValue
        record["startDate"] = startDate as CKRecordValue
        record["endDate"] = endDate as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let model = record["model"] as? String {
            self.model = model
        }
        if let firma = record["firma"] as? String {
            self.firma = firma
        }
        if let ayar = record["ayar"] as? String {
            self.ayar = ayar
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
    }
}

// MARK: - Note CloudKit Extension

extension Note: CloudKitConvertible {
    static var recordType: String { "Note" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["title"] = title as CKRecordValue
        record["text"] = text as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let title = record["title"] as? String {
            self.title = title
        }
        if let text = record["text"] as? String {
            self.text = text
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
    }
}

// MARK: - ModelItem CloudKit Extension

extension ModelItem: CloudKitConvertible {
    static var recordType: String { "ModelItem" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let name = record["name"] as? String {
            self.name = name
        }
    }
}

// MARK: - CompanyItem CloudKit Extension

extension CompanyItem: CloudKitConvertible {
    static var recordType: String { "CompanyItem" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let name = record["name"] as? String {
            self.name = name
        }
    }
}
