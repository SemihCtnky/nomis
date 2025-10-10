import Foundation
import CloudKit
import SwiftData

// MARK: - CloudKit Record Conversion Protocol

protocol CloudKitConvertible {
    /// Convert SwiftData model to CloudKit record
    func toCKRecord() -> CKRecord
    
    /// Update SwiftData model from CloudKit record
    mutating func updateFrom(record: CKRecord)
    
    /// Record type name
    static var recordType: String { get }
}

// MARK: - YeniGunlukForm CloudKit Extension

extension YeniGunlukForm: CloudKitConvertible {
    static var recordType: String { "YeniGunlukForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        // Basic fields
        record["startDate"] = (startDate ?? Date()) as CKRecordValue
        record["endDate"] = (endDate ?? Date()) as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedAt"] = lastEditedAt as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        record["isCompleted"] = (isCompleted ? 1 : 0) as CKRecordValue
        
        // Complex data as JSON
        if let gunlukData = try? JSONEncoder().encode(gunlukVeriler),
           let gunlukString = String(data: gunlukData, encoding: .utf8) {
            record["gunlukVeriler"] = gunlukString as CKRecordValue
        }
        
        return record
    }
    
    mutating func updateFrom(record: CKRecord) {
        if let startDate = record["startDate"] as? Date {
            self.startDate = startDate
        }
        if let endDate = record["endDate"] as? Date {
            self.endDate = endDate
        }
        if let lastEditedAt = record["lastEditedAt"] as? Date {
            self.lastEditedAt = lastEditedAt
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
        if let isCompletedInt = record["isCompleted"] as? Int {
            self.isCompleted = isCompletedInt == 1
        }
        
        // Decode complex data from JSON
        if let gunlukString = record["gunlukVeriler"] as? String,
           let gunlukData = gunlukString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([GunlukGunVerisi].self, from: gunlukData) {
            self.gunlukVeriler = decoded
        }
    }
}

// MARK: - SarnelForm CloudKit Extension

extension SarnelForm: CloudKitConvertible {
    static var recordType: String { "SarnelForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["karatAyar"] = (karatAyar ?? 0) as CKRecordValue
        record["girisAltin"] = (girisAltin ?? 0.0) as CKRecordValue
        record["cikisAltin"] = (cikisAltin ?? 0.0) as CKRecordValue
        record["demirli_1"] = (demirli_1 ?? 0.0) as CKRecordValue
        record["demirli_2"] = (demirli_2 ?? 0.0) as CKRecordValue
        record["demirli_3"] = (demirli_3 ?? 0.0) as CKRecordValue
        record["demirliHurda"] = (demirliHurda ?? 0.0) as CKRecordValue
        record["demirliToz"] = (demirliToz ?? 0.0) as CKRecordValue
        record["startedAt"] = (startedAt ?? Date()) as CKRecordValue
        record["endedAt"] = (endedAt ?? Date()) as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        // Complex data as JSON
        if let asitData = try? JSONEncoder().encode(asitCikislari),
           let asitString = String(data: asitData, encoding: .utf8) {
            record["asitCikislari"] = asitString as CKRecordValue
        }
        
        if let fireData = try? JSONEncoder().encode(extraFireItems),
           let fireString = String(data: fireData, encoding: .utf8) {
            record["extraFireItems"] = fireString as CKRecordValue
        }
        
        return record
    }
    
    mutating func updateFrom(record: CKRecord) {
        if let karatAyar = record["karatAyar"] as? Int {
            self.karatAyar = karatAyar
        }
        if let girisAltin = record["girisAltin"] as? Double {
            self.girisAltin = girisAltin
        }
        if let cikisAltin = record["cikisAltin"] as? Double {
            self.cikisAltin = cikisAltin
        }
        if let startedAt = record["startedAt"] as? Date {
            self.startedAt = startedAt
        }
        if let endedAt = record["endedAt"] as? Date {
            self.endedAt = endedAt
        }
        
        // Decode complex data
        if let asitString = record["asitCikislari"] as? String,
           let asitData = asitString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([AsitItem].self, from: asitData) {
            self.asitCikislari = decoded
        }
        
        if let fireString = record["extraFireItems"] as? String,
           let fireData = fireString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([FireItem].self, from: fireData) {
            self.extraFireItems = decoded
        }
    }
}

// MARK: - KilitToplamaForm CloudKit Extension

extension KilitToplamaForm: CloudKitConvertible {
    static var recordType: String { "KilitToplamaForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["model"] = model as CKRecordValue
        record["firma"] = firma as CKRecordValue
        record["ayar"] = ayar as CKRecordValue
        record["startDate"] = startDate as CKRecordValue
        record["endDate"] = endDate as CKRecordValue
        record["startedAt"] = (startedAt ?? Date()) as CKRecordValue
        record["endedAt"] = (endedAt ?? Date()) as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        // Complex data as JSON
        if let kasaData = try? JSONEncoder().encode(kasaItems),
           let kasaString = String(data: kasaData, encoding: .utf8) {
            record["kasaItems"] = kasaString as CKRecordValue
        }
        
        if let dilData = try? JSONEncoder().encode(dilItems),
           let dilString = String(data: dilData, encoding: .utf8) {
            record["dilItems"] = dilString as CKRecordValue
        }
        
        if let yayData = try? JSONEncoder().encode(yayItems),
           let yayString = String(data: yayData, encoding: .utf8) {
            record["yayItems"] = yayString as CKRecordValue
        }
        
        if let kilitData = try? JSONEncoder().encode(kilitItems),
           let kilitString = String(data: kilitData, encoding: .utf8) {
            record["kilitItems"] = kilitString as CKRecordValue
        }
        
        return record
    }
    
    mutating func updateFrom(record: CKRecord) {
        if let model = record["model"] as? String {
            self.model = model
        }
        if let firma = record["firma"] as? String {
            self.firma = firma
        }
        if let ayar = record["ayar"] as? String {
            self.ayar = ayar
        }
        if let startDate = record["startDate"] as? Date {
            self.startDate = startDate
        }
        if let endDate = record["endDate"] as? Date {
            self.endDate = endDate
        }
        
        // Decode complex data
        if let kasaString = record["kasaItems"] as? String,
           let kasaData = kasaString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([KilitItem].self, from: kasaData) {
            self.kasaItems = decoded
        }
        
        if let dilString = record["dilItems"] as? String,
           let dilData = dilString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([KilitItem].self, from: dilData) {
            self.dilItems = decoded
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
    
    mutating func updateFrom(record: CKRecord) {
        if let title = record["title"] as? String {
            self.title = title
        }
        if let text = record["text"] as? String {
            self.text = text
        }
        if let createdAt = record["createdAt"] as? Date {
            self.createdAt = createdAt
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
    
    mutating func updateFrom(record: CKRecord) {
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
    
    mutating func updateFrom(record: CKRecord) {
        if let name = record["name"] as? String {
            self.name = name
        }
    }
}

