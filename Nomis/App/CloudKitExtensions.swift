import Foundation
import CloudKit
import SwiftData

// MARK: - CloudKit Record Conversion Protocol

protocol CloudKitConvertible {
    func toCKRecord() -> CKRecord
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext)
    static var recordType: String { get }
}

// MARK: - YeniGunlukForm FULL SYNC

extension YeniGunlukForm: CloudKitConvertible {
    static var recordType: String { "YeniGunlukForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["baslamaTarihi"] = baslamaTarihi as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        if let lastEditedAt = lastEditedAt {
            record["lastEditedAt"] = lastEditedAt as CKRecordValue
        }
        record["isCompleted"] = (isCompleted ? 1 : 0) as CKRecordValue
        
        // Encode gunlukVeriler as JSON
        var gunVerilerArray: [[String: Any]] = []
        for gunVerisi in gunlukVeriler {
            var gunDict: [String: Any] = [:]
            gunDict["id"] = gunVerisi.id.uuidString
            gunDict["tarih"] = gunVerisi.tarih.timeIntervalSince1970
            
            // Tezgah Karti 1
            if let tezgah1 = gunVerisi.tezgahKarti1 {
                gunDict["tezgahKarti1"] = encodeTezgahKarti(tezgah1)
            }
            
            // Tezgah Karti 2
            if let tezgah2 = gunVerisi.tezgahKarti2 {
                gunDict["tezgahKarti2"] = encodeTezgahKarti(tezgah2)
            }
            
            // Cila Karti
            if let cila = gunVerisi.cilaKarti {
                gunDict["cilaKarti"] = encodeIslemKarti(cila)
            }
            
            // Ocak Karti
            if let ocak = gunVerisi.ocakKarti {
                gunDict["ocakKarti"] = encodeIslemKarti(ocak)
            }
            
            // Patlatma Karti
            if let patlatma = gunVerisi.patlatmaKarti {
                gunDict["patlatmaKarti"] = encodeIslemKarti(patlatma)
            }
            
            // Tambur Karti
            if let tambur = gunVerisi.tamburKarti {
                gunDict["tamburKarti"] = encodeIslemKarti(tambur)
            }
            
            // Makine Kesme Karti
            if let makine = gunVerisi.makineKesmeKarti1 {
                gunDict["makineKesmeKarti"] = encodeIslemKarti(makine)
            }
            
            // Testere Kesme Karti
            if let testere = gunVerisi.testereKesmeKarti1 {
                gunDict["testereKesmeKarti"] = encodeIslemKarti(testere)
            }
            
            gunVerilerArray.append(gunDict)
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: gunVerilerArray),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record["gunlukVerilerJSON"] = jsonString as CKRecordValue
        }
        
        return record
    }
    
    private func encodeTezgahKarti(_ kart: TezgahKarti) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = kart.id.uuidString
        if let ayar = kart.ayar {
            dict["ayar"] = ayar
        }
        
        // Satirlar
        var satirlarArray: [[String: Any]] = []
        for satir in kart.satirlar {
            var satirDict: [String: Any] = [:]
            satirDict["id"] = satir.id.uuidString
            satirDict["aciklamaGiris"] = satir.aciklamaGiris
            satirDict["aciklamaCikis"] = satir.aciklamaCikis
            satirDict["girisValue"] = satir.girisValue ?? 0.0
            satirDict["cikisValue"] = satir.cikisValue ?? 0.0
            satirDict["orderIndex"] = satir.orderIndex
            if let ayar = satir.ayar {
                satirDict["ayar"] = ayar
            }
            satirlarArray.append(satirDict)
        }
        dict["satirlar"] = satirlarArray
        
        // Fire Eklemeleri
        var fireArray: [[String: Any]] = []
        for fire in kart.fireEklemeleri {
            var fireDict: [String: Any] = [:]
            fireDict["id"] = fire.id.uuidString
            fireDict["value"] = fire.value ?? 0.0
            fireDict["aciklama"] = fire.aciklama
            fireArray.append(fireDict)
        }
        dict["fireEklemeleri"] = fireArray
        
        return dict
    }
    
    private func encodeIslemKarti<T>(_ kart: T) -> [String: Any] where T: AnyObject {
        var dict: [String: Any] = [:]
        
        // Use mirror to access properties dynamically
        let mirror = Mirror(reflecting: kart)
        for child in mirror.children {
            if let label = child.label {
                if label == "id", let uuid = child.value as? UUID {
                    dict["id"] = uuid.uuidString
                } else if label == "ayar", let ayar = child.value as? Int? {
                    if let ayarValue = ayar {
                        dict["ayar"] = ayarValue
                    }
                } else if label == "satirlar", let satirlar = child.value as? [IslemSatiri] {
                    var satirlarArray: [[String: Any]] = []
                    for satir in satirlar {
                        var satirDict: [String: Any] = [:]
                        satirDict["id"] = satir.id.uuidString
                        satirDict["aciklamaGiris"] = satir.aciklamaGiris
                        satirDict["aciklamaCikis"] = satir.aciklamaCikis
                        satirDict["girisValues"] = satir.girisValues.map { $0.value ?? 0.0 }
                        satirDict["cikisValues"] = satir.cikisValues.map { $0.value ?? 0.0 }
                        satirDict["orderIndex"] = satir.orderIndex
                        satirlarArray.append(satirDict)
                    }
                    dict["satirlar"] = satirlarArray
                } else if label == "fireEklemeleri", let fireList = child.value as? [FireEklemesi] {
                    var fireArray: [[String: Any]] = []
                    for fire in fireList {
                        var fireDict: [String: Any] = [:]
                        fireDict["id"] = fire.id.uuidString
                        fireDict["value"] = fire.value ?? 0.0
                        fireDict["aciklama"] = fire.aciklama
                        fireArray.append(fireDict)
                    }
                    dict["fireEklemeleri"] = fireArray
                }
            }
        }
        
        return dict
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let lastEditedAt = record["lastEditedAt"] as? Date {
            self.lastEditedAt = lastEditedAt
        }
        if let isCompletedInt = record["isCompleted"] as? Int {
            self.isCompleted = isCompletedInt == 1
        }
        
        // ✅ FULL DESERIALIZATION: Decode nested data from JSON
        guard let jsonString = record["gunlukVerilerJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8),
              let gunVerilerArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return
        }
        
        // Clear existing gunlukVeriler (we'll recreate from CloudKit)
        gunlukVeriler.removeAll()
        
        // Deserialize each GunlukGunVerisi
        for gunDict in gunVerilerArray {
            guard let idString = gunDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let tarihTimestamp = gunDict["tarih"] as? TimeInterval else {
                continue
            }
            
            let tarih = Date(timeIntervalSince1970: tarihTimestamp)
            let gunVerisi = GunlukGunVerisi(tarih: tarih, id: id)
            modelContext.insert(gunVerisi)  // ✅ INSERT IMMEDIATELY
            
            // Deserialize Tezgah Karti 1
            if let tezgah1Dict = gunDict["tezgahKarti1"] as? [String: Any] {
                gunVerisi.tezgahKarti1 = decodeTezgahKarti(from: tezgah1Dict, modelContext: modelContext)
            }
            
            // Deserialize Tezgah Karti 2
            if let tezgah2Dict = gunDict["tezgahKarti2"] as? [String: Any] {
                gunVerisi.tezgahKarti2 = decodeTezgahKarti(from: tezgah2Dict, modelContext: modelContext)
            }
            
            // Deserialize Cila Karti
            if let cilaDict = gunDict["cilaKarti"] as? [String: Any] {
                gunVerisi.cilaKarti = decodeCilaKarti(from: cilaDict, modelContext: modelContext)
            }
            
            // Deserialize Ocak Karti
            if let ocakDict = gunDict["ocakKarti"] as? [String: Any] {
                gunVerisi.ocakKarti = decodeOcakKarti(from: ocakDict, modelContext: modelContext)
            }
            
            // Deserialize Patlatma Karti
            if let patlatmaDict = gunDict["patlatmaKarti"] as? [String: Any] {
                gunVerisi.patlatmaKarti = decodePatlatmaKarti(from: patlatmaDict, modelContext: modelContext)
            }
            
            // Deserialize Tambur Karti
            if let tamburDict = gunDict["tamburKarti"] as? [String: Any] {
                gunVerisi.tamburKarti = decodeTamburKarti(from: tamburDict, modelContext: modelContext)
            }
            
            // Deserialize Makine Kesme Karti
            if let makineDict = gunDict["makineKesmeKarti"] as? [String: Any] {
                gunVerisi.makineKesmeKarti1 = decodeMakineKesmeKarti(from: makineDict, modelContext: modelContext)
            }
            
            // Deserialize Testere Kesme Karti
            if let testereDict = gunDict["testereKesmeKarti"] as? [String: Any] {
                gunVerisi.testereKesmeKarti1 = decodeTestereKesmeKarti(from: testereDict, modelContext: modelContext)
            }
            
            gunlukVeriler.append(gunVerisi)
        }
    }
    
    // MARK: - Decode Helper Functions
    
    private func decodeTezgahKarti(from dict: [String: Any], modelContext: ModelContext) -> TezgahKarti {
        let kart = TezgahKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = TezgahSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                if let girisValue = rowDict["girisValue"] as? Double {
                    satir.girisValue = girisValue
                }
                if let cikisValue = rowDict["cikisValue"] as? Double {
                    satir.cikisValue = cikisValue
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        // Decode fire eklemeleri
        if let fireArray = dict["fireEklemeleri"] as? [[String: Any]] {
            for fireDict in fireArray {
                guard let idString = fireDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                let fire = FireEklemesi()
                fire.id = id
                if let value = fireDict["value"] as? Double {
                    fire.value = value
                }
                if let aciklama = fireDict["aciklama"] as? String {
                    fire.aciklama = aciklama
                }
                modelContext.insert(fire)  // ✅ INSERT IMMEDIATELY
                kart.fireEklemeleri.append(fire)
            }
        }
        
        return kart
    }
    
    private func decodeCilaKarti(from dict: [String: Any], modelContext: ModelContext) -> CilaKarti {
        let kart = CilaKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
    
    private func decodeOcakKarti(from dict: [String: Any], modelContext: ModelContext) -> OcakKarti {
        let kart = OcakKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows (same as CilaKarti)
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
    
    private func decodePatlatmaKarti(from dict: [String: Any], modelContext: ModelContext) -> PatlatmaKarti {
        let kart = PatlatmaKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows (same as CilaKarti)
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
    
    private func decodeTamburKarti(from dict: [String: Any], modelContext: ModelContext) -> TamburKarti {
        let kart = TamburKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows (same as CilaKarti)
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
    
    private func decodeMakineKesmeKarti(from dict: [String: Any], modelContext: ModelContext) -> MakineKesmeKarti {
        let kart = MakineKesmeKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows (same as CilaKarti)
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
    
    private func decodeTestereKesmeKarti(from dict: [String: Any], modelContext: ModelContext) -> TestereKesmeKarti {
        let kart = TestereKesmeKarti()
        if let idString = dict["id"] as? String, let id = UUID(uuidString: idString) {
            kart.id = id
        }
        if let ayar = dict["ayar"] as? Int {
            kart.ayar = ayar
        }
        modelContext.insert(kart)  // ✅ INSERT IMMEDIATELY
        
        // Decode rows (same as CilaKarti)
        if let rowsArray = dict["satirlar"] as? [[String: Any]] {
            for rowDict in rowsArray {
                let satir = IslemSatiri()
                if let idString = rowDict["id"] as? String, let id = UUID(uuidString: idString) {
                    satir.id = id
                }
                if let aciklamaGiris = rowDict["aciklamaGiris"] as? String {
                    satir.aciklamaGiris = aciklamaGiris
                }
                if let aciklamaCikis = rowDict["aciklamaCikis"] as? String {
                    satir.aciklamaCikis = aciklamaCikis
                }
                // Decode girisValues: [Double] → [GenisletilebilirDeger]
                if let girisValuesArray = rowDict["girisValues"] as? [Double] {
                    for value in girisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.girisValues.append(deger)
                    }
                }
                // Decode cikisValues: [Double] → [GenisletilebilirDeger]
                if let cikisValuesArray = rowDict["cikisValues"] as? [Double] {
                    for value in cikisValuesArray {
                        let deger = GenisletilebilirDeger(value: value)
                        modelContext.insert(deger)  // ✅ INSERT IMMEDIATELY
                        satir.cikisValues.append(deger)
                    }
                }
                if let ayar = rowDict["ayar"] as? Int {
                    satir.ayar = ayar
                }
                if let orderIndex = rowDict["orderIndex"] as? Int {
                    satir.orderIndex = orderIndex
                }
                modelContext.insert(satir)  // ✅ INSERT IMMEDIATELY
                kart.satirlar.append(satir)
            }
        }
        
        return kart
    }
}

// MARK: - SarnelForm FULL SYNC

extension SarnelForm: CloudKitConvertible {
    static var recordType: String { "SarnelForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["karatAyar"] = karatAyar as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["lastEditedAt"] = lastEditedAt as CKRecordValue
        
        if let girisAltin = girisAltin {
            record["girisAltin"] = girisAltin as CKRecordValue
        }
        if let cikisAltin = cikisAltin {
            record["cikisAltin"] = cikisAltin as CKRecordValue
        }
        if let demirli_1 = demirli_1 {
            record["demirli_1"] = demirli_1 as CKRecordValue
        }
        if let demirli_2 = demirli_2 {
            record["demirli_2"] = demirli_2 as CKRecordValue
        }
        if let demirli_3 = demirli_3 {
            record["demirli_3"] = demirli_3 as CKRecordValue
        }
        if let demirliHurda = demirliHurda {
            record["demirliHurda"] = demirliHurda as CKRecordValue
        }
        if let demirliToz = demirliToz {
            record["demirliToz"] = demirliToz as CKRecordValue
        }
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        // Asit Cikislari
        var asitArray: [[String: Any]] = []
        for asit in asitCikislari {
            var asitDict: [String: Any] = [:]
            asitDict["id"] = asit.id.uuidString
            asitDict["valueGr"] = asit.valueGr
            asitDict["note"] = asit.note ?? ""
            asitArray.append(asitDict)
        }
        
        // Extra Fire Items
        var fireArray: [[String: Any]] = []
        for fire in extraFireItems {
            var fireDict: [String: Any] = [:]
            fireDict["id"] = fire.id.uuidString
            fireDict["value"] = fire.value
            fireDict["note"] = fire.note ?? ""
            fireArray.append(fireDict)
        }
        
        let sarnelData: [String: Any] = [
            "asitCikislari": asitArray,
            "extraFireItems": fireArray
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: sarnelData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record["sarnelDataJSON"] = jsonString as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let karatAyar = record["karatAyar"] as? Int {
            self.karatAyar = karatAyar
        }
        if let girisAltin = record["girisAltin"] as? Double {
            self.girisAltin = girisAltin
        }
        if let cikisAltin = record["cikisAltin"] as? Double {
            self.cikisAltin = cikisAltin
        }
        if let demirli_1 = record["demirli_1"] as? Double {
            self.demirli_1 = demirli_1
        }
        if let demirli_2 = record["demirli_2"] as? Double {
            self.demirli_2 = demirli_2
        }
        if let demirli_3 = record["demirli_3"] as? Double {
            self.demirli_3 = demirli_3
        }
        if let demirliHurda = record["demirliHurda"] as? Double {
            self.demirliHurda = demirliHurda
        }
        if let demirliToz = record["demirliToz"] as? Double {
            self.demirliToz = demirliToz
        }
        if let lastEditedAt = record["lastEditedAt"] as? Date {
            self.lastEditedAt = lastEditedAt
        }
        if let startedAt = record["startedAt"] as? Date {
            self.startedAt = startedAt
        }
        if let endedAt = record["endedAt"] as? Date {
            self.endedAt = endedAt
        }
        
        // ✅ FULL DESERIALIZATION: Decode nested data from JSON
        guard let jsonString = record["sarnelDataJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8),
              let sarnelDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }
        
        // Clear existing arrays
        asitCikislari.removeAll()
        extraFireItems.removeAll()
        
        // Deserialize asitCikislari
        if let asitArray = sarnelDict["asitCikislari"] as? [[String: Any]] {
            for asitDict in asitArray {
                guard let idString = asitDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let valueGr = asitDict["valueGr"] as? Double else {
                    continue
                }
                let note = asitDict["note"] as? String
                let asit = AsitItem(valueGr: valueGr, note: note ?? "", id: id)
                modelContext.insert(asit)  // ✅ INSERT IMMEDIATELY
                asitCikislari.append(asit)
            }
        }
        
        // Deserialize extraFireItems
        if let fireArray = sarnelDict["extraFireItems"] as? [[String: Any]] {
            for fireDict in fireArray {
                guard let idString = fireDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let value = fireDict["value"] as? Double else {
                    continue
                }
                let note = fireDict["note"] as? String
                let fire = FireItem(value: value, note: note ?? "", id: id)
                modelContext.insert(fire)  // ✅ INSERT IMMEDIATELY
                extraFireItems.append(fire)
            }
        }
    }
}

// MARK: - KilitToplamaForm FULL SYNC

extension KilitToplamaForm: CloudKitConvertible {
    static var recordType: String { "KilitToplamaForm" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["model"] = (model ?? "") as CKRecordValue
        record["firma"] = (firma ?? "") as CKRecordValue
        if let ayar = ayar {
            record["ayar"] = ayar as CKRecordValue
        }
        record["createdAt"] = createdAt as CKRecordValue
        
        if let startedAt = startedAt {
            record["startedAt"] = startedAt as CKRecordValue
        }
        if let endedAt = endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        
        // Kasa Items
        var kasaArray: [[String: Any]] = []
        for item in kasaItems {
            var itemDict: [String: Any] = [:]
            itemDict["id"] = item.id.uuidString
            itemDict["girisAdet"] = item.girisAdet ?? 0.0
            itemDict["girisGram"] = item.girisGram ?? 0.0
            itemDict["cikisGram"] = item.cikisGram ?? 0.0
            itemDict["cikisAdet"] = item.cikisAdet ?? 0.0
            kasaArray.append(itemDict)
        }
        
        // Dil Items
        var dilArray: [[String: Any]] = []
        for item in dilItems {
            var itemDict: [String: Any] = [:]
            itemDict["id"] = item.id.uuidString
            itemDict["girisAdet"] = item.girisAdet ?? 0.0
            itemDict["girisGram"] = item.girisGram ?? 0.0
            itemDict["cikisGram"] = item.cikisGram ?? 0.0
            itemDict["cikisAdet"] = item.cikisAdet ?? 0.0
            dilArray.append(itemDict)
        }
        
        // Yay Items
        var yayArray: [[String: Any]] = []
        for item in yayItems {
            var itemDict: [String: Any] = [:]
            itemDict["id"] = item.id.uuidString
            itemDict["girisAdet"] = item.girisAdet ?? 0.0
            itemDict["girisGram"] = item.girisGram ?? 0.0
            itemDict["cikisGram"] = item.cikisGram ?? 0.0
            itemDict["cikisAdet"] = item.cikisAdet ?? 0.0
            yayArray.append(itemDict)
        }
        
        // Kilit Items
        var kilitArray: [[String: Any]] = []
        for item in kilitItems {
            var itemDict: [String: Any] = [:]
            itemDict["id"] = item.id.uuidString
            itemDict["girisAdet"] = item.girisAdet ?? 0.0
            itemDict["girisGram"] = item.girisGram ?? 0.0
            itemDict["cikisGram"] = item.cikisGram ?? 0.0
            itemDict["cikisAdet"] = item.cikisAdet ?? 0.0
            kilitArray.append(itemDict)
        }
        
        let kilitData: [String: Any] = [
            "kasaItems": kasaArray,
            "dilItems": dilArray,
            "yayItems": yayArray,
            "kilitItems": kilitArray
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: kilitData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record["kilitDataJSON"] = jsonString as CKRecordValue
        }
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let model = record["model"] as? String {
            self.model = model
        }
        if let firma = record["firma"] as? String {
            self.firma = firma
        }
        if let ayar = record["ayar"] as? Int {
            self.ayar = ayar
        }
        if let startedAt = record["startedAt"] as? Date {
            self.startedAt = startedAt
        }
        if let endedAt = record["endedAt"] as? Date {
            self.endedAt = endedAt
        }
        
        // ✅ FULL DESERIALIZATION: Decode nested data from JSON
        guard let jsonString = record["kilitDataJSON"] as? String,
              let jsonData = jsonString.data(using: .utf8),
              let kilitDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }
        
        // Clear existing arrays
        kasaItems.removeAll()
        dilItems.removeAll()
        yayItems.removeAll()
        kilitItems.removeAll()
        
        // Deserialize kasaItems
        if let kasaArray = kilitDict["kasaItems"] as? [[String: Any]] {
            for itemDict in kasaArray {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                let girisAdet = itemDict["girisAdet"] as? Double
                let girisGram = itemDict["girisGram"] as? Double
                let cikisGram = itemDict["cikisGram"] as? Double
                let cikisAdet = itemDict["cikisAdet"] as? Double
                let item = KilitItem(girisAdet: girisAdet, girisGram: girisGram, cikisGram: cikisGram, cikisAdet: cikisAdet, id: id)
                modelContext.insert(item)  // ✅ INSERT IMMEDIATELY
                kasaItems.append(item)
            }
        }
        
        // Deserialize dilItems
        if let dilArray = kilitDict["dilItems"] as? [[String: Any]] {
            for itemDict in dilArray {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                let girisAdet = itemDict["girisAdet"] as? Double
                let girisGram = itemDict["girisGram"] as? Double
                let cikisGram = itemDict["cikisGram"] as? Double
                let cikisAdet = itemDict["cikisAdet"] as? Double
                let item = KilitItem(girisAdet: girisAdet, girisGram: girisGram, cikisGram: cikisGram, cikisAdet: cikisAdet, id: id)
                modelContext.insert(item)  // ✅ INSERT IMMEDIATELY
                dilItems.append(item)
            }
        }
        
        // Deserialize yayItems
        if let yayArray = kilitDict["yayItems"] as? [[String: Any]] {
            for itemDict in yayArray {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                let girisAdet = itemDict["girisAdet"] as? Double
                let girisGram = itemDict["girisGram"] as? Double
                let cikisGram = itemDict["cikisGram"] as? Double
                let cikisAdet = itemDict["cikisAdet"] as? Double
                let item = KilitItem(girisAdet: girisAdet, girisGram: girisGram, cikisGram: cikisGram, cikisAdet: cikisAdet, id: id)
                modelContext.insert(item)  // ✅ INSERT IMMEDIATELY
                yayItems.append(item)
            }
        }
        
        // Deserialize kilitItems
        if let kilitArray = kilitDict["kilitItems"] as? [[String: Any]] {
            for itemDict in kilitArray {
                guard let idString = itemDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                let girisAdet = itemDict["girisAdet"] as? Double
                let girisGram = itemDict["girisGram"] as? Double
                let cikisGram = itemDict["cikisGram"] as? Double
                let cikisAdet = itemDict["cikisAdet"] as? Double
                let item = KilitItem(girisAdet: girisAdet, girisGram: girisGram, cikisGram: cikisGram, cikisAdet: cikisAdet, id: id)
                modelContext.insert(item)  // ✅ INSERT IMMEDIATELY
                kilitItems.append(item)
            }
        }
    }
}

// MARK: - Note FULL SYNC

extension Note: CloudKitConvertible {
    static var recordType: String { "Note" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["title"] = title as CKRecordValue
        record["text"] = text as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["lastEditedAt"] = lastEditedAt as CKRecordValue
        record["createdByUsername"] = createdByUsername as CKRecordValue
        record["lastEditedByUsername"] = lastEditedByUsername as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let title = record["title"] as? String {
            self.title = title
        }
        if let text = record["text"] as? String {
            self.text = text
        }
        if let lastEditedAt = record["lastEditedAt"] as? Date {
            self.lastEditedAt = lastEditedAt
        }
        if let lastEditedByUsername = record["lastEditedByUsername"] as? String {
            self.lastEditedByUsername = lastEditedByUsername
        }
    }
}

// MARK: - ModelItem FULL SYNC

extension ModelItem: CloudKitConvertible {
    static var recordType: String { "ModelItem" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let name = record["name"] as? String {
            self.name = name
        }
    }
}

// MARK: - CompanyItem FULL SYNC

extension CompanyItem: CloudKitConvertible {
    static var recordType: String { "CompanyItem" }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        
        return record
    }
    
    func updateFromRecord(_ record: CKRecord, modelContext: ModelContext) {
        if let name = record["name"] as? String {
            self.name = name
        }
    }
}
