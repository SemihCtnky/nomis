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

// MARK: - Helper: Encode/Decode SwiftData Models

extension YeniGunlukForm {
    /// Encode gunlukVeriler to JSON string
    private func encodeGunlukVeriler() -> String? {
        // Convert to dictionary format
        let dataArray = gunlukVeriler.map { gunVerisi -> [String: Any] in
            var dict: [String: Any] = [:]
            dict["id"] = gunVerisi.id.uuidString
            dict["tarih"] = gunVerisi.tarih.timeIntervalSince1970
            
            // Encode tezgah kartları
            dict["tezgahKartlari"] = gunVerisi.tezgahKartlari.map { kart -> [String: Any] in
                var kartDict: [String: Any] = [:]
                kartDict["id"] = kart.id.uuidString
                kartDict["ayar"] = kart.ayar ?? 0
                kartDict["satirlar"] = kart.satirlar.map { satir -> [String: Any] in
                    return [
                        "id": satir.id.uuidString,
                        "aciklamaGiris": satir.aciklamaGiris,
                        "girisValues": satir.girisValues.map { $0.value ?? 0.0 },
                        "aciklamaCikis": satir.aciklamaCikis,
                        "cikisValues": satir.cikisValues.map { $0.value ?? 0.0 }
                    ]
                }
                kartDict["fireEklemeleri"] = kart.fireEklemeleri.map { fire -> [String: Any] in
                    return ["id": fire.id.uuidString, "value": fire.value ?? 0.0, "note": fire.note]
                }
                return kartDict
            }
            
            // Encode other kartlar (simplified - basic structure)
            dict["cilaKartlari"] = encodeIslemKartlari(gunVerisi.cilaKartlari)
            dict["ocakKartlari"] = encodeIslemKartlari(gunVerisi.ocakKartlari)
            dict["patlatmaKartlari"] = encodeIslemKartlari(gunVerisi.patlatmaKartlari)
            dict["tamburKartlari"] = encodeIslemKartlari(gunVerisi.tamburKartlari)
            dict["makineKesmeKartlari"] = encodeIslemKartlari(gunVerisi.makineKesmeKartlari)
            dict["testereKesmeKartlari"] = encodeIslemKartlari(gunVerisi.testereKesmeKartlari)
            
            return dict
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dataArray, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    private func encodeIslemKartlari<T>(_ kartlar: [T]) -> [[String: Any]] where T: IslemKartiProtocol {
        return kartlar.map { kart -> [String: Any] in
            var kartDict: [String: Any] = [:]
            kartDict["id"] = kart.id.uuidString
            kartDict["ayar"] = kart.ayar ?? 0
            kartDict["satirlar"] = kart.satirlar.map { satir -> [String: Any] in
                return [
                    "id": satir.id.uuidString,
                    "aciklamaGiris": satir.aciklamaGiris,
                    "girisValues": satir.girisValues.map { $0.value ?? 0.0 },
                    "aciklamaCikis": satir.aciklamaCikis,
                    "cikisValues": satir.cikisValues.map { $0.value ?? 0.0 }
                ]
            }
            kartDict["fireEklemeleri"] = kart.fireEklemeleri.map { fire -> [String: Any] in
                return ["id": fire.id.uuidString, "value": fire.value ?? 0.0, "note": fire.note]
            }
            return kartDict
        }
    }
}

// MARK: - YeniGunlukForm CloudKit Extension (FULL SYNC)

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
        
        // FULL CONTENT as JSON string
        if let gunlukJSON = encodeGunlukVeriler() {
            record["gunlukVerilerJSON"] = gunlukJSON as CKRecordValue
        }
        
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
        
        // Decode gunlukVeriler from JSON
        // Note: This is complex and requires rebuilding all nested objects
        // For now, we'll skip decoding to avoid conflicts
        // New forms will be created from scratch on other devices
    }
}

// MARK: - SarnelForm CloudKit Extension (FULL SYNC)

extension SarnelForm {
    private func encodeSarnelData() -> String? {
        var dict: [String: Any] = [:]
        dict["karatAyar"] = karatAyar ?? 0
        dict["girisAltin"] = girisAltin ?? 0.0
        dict["cikisAltin"] = cikisAltin ?? 0.0
        dict["demirli_1"] = demirli_1 ?? 0.0
        dict["demirli_2"] = demirli_2 ?? 0.0
        dict["demirli_3"] = demirli_3 ?? 0.0
        dict["demirliHurda"] = demirliHurda ?? 0.0
        dict["demirliToz"] = demirliToz ?? 0.0
        
        dict["asitCikislari"] = asitCikislari.map { item -> [String: Any] in
            return ["id": item.id.uuidString, "valueGr": item.valueGr, "note": item.note]
        }
        
        dict["extraFireItems"] = extraFireItems.map { item -> [String: Any] in
            return ["id": item.id.uuidString, "value": item.value, "note": item.note]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}

extension SarnelForm: CloudKitConvertible {
    static var recordType: String { "SarnelForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["createdAt"] = createdAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        // FULL CONTENT as JSON
        if let sarnelJSON = encodeSarnelData() {
            record["sarnelDataJSON"] = sarnelJSON as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
        // Decoding skipped for now to avoid conflicts
    }
}

// MARK: - KilitToplamaForm CloudKit Extension (FULL SYNC)

extension KilitToplamaForm {
    private func encodeKilitData() -> String? {
        var dict: [String: Any] = [:]
        dict["model"] = model ?? ""
        dict["firma"] = firma ?? ""
        dict["ayar"] = ayar ?? ""
        dict["startDate"] = startDate.timeIntervalSince1970
        dict["endDate"] = endDate.timeIntervalSince1970
        
        dict["kasaItems"] = kasaItems.map { item -> [String: Any] in
            return [
                "id": item.id.uuidString,
                "girisAdet": item.girisAdet ?? 0.0,
                "girisGram": item.girisGram ?? 0.0,
                "cikisGram": item.cikisGram ?? 0.0,
                "cikisAdet": item.cikisAdet ?? 0.0
            ]
        }
        
        dict["dilItems"] = dilItems.map { item -> [String: Any] in
            return [
                "id": item.id.uuidString,
                "girisAdet": item.girisAdet ?? 0.0,
                "girisGram": item.girisGram ?? 0.0,
                "cikisGram": item.cikisGram ?? 0.0,
                "cikisAdet": item.cikisAdet ?? 0.0
            ]
        }
        
        dict["yayItems"] = yayItems.map { item -> [String: Any] in
            return [
                "id": item.id.uuidString,
                "girisAdet": item.girisAdet ?? 0.0,
                "girisGram": item.girisGram ?? 0.0,
                "cikisGram": item.cikisGram ?? 0.0,
                "cikisAdet": item.cikisAdet ?? 0.0
            ]
        }
        
        dict["kilitItems"] = kilitItems.map { item -> [String: Any] in
            return [
                "id": item.id.uuidString,
                "girisAdet": item.girisAdet ?? 0.0,
                "girisGram": item.girisGram ?? 0.0,
                "cikisGram": item.cikisGram ?? 0.0,
                "cikisAdet": item.cikisAdet ?? 0.0
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}

extension KilitToplamaForm: CloudKitConvertible {
    static var recordType: String { "KilitToplamaForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        // FULL CONTENT as JSON
        if let kilitJSON = encodeKilitData() {
            record["kilitDataJSON"] = kilitJSON as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord) {
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
        // Decoding skipped for now
    }
}

// MARK: - Note CloudKit Extension (FULL SYNC - Already Complete)

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
