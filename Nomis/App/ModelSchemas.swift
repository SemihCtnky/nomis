import Foundation
import SwiftData
import SwiftUI

// MARK: - Settings Models
@Model
class ModelItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

@Model
class CompanyItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

// MARK: - User Model
@Model
class User {
    @Attribute(.unique) var id: UUID
    var username: String
    var role: UserRole
    var passwordHash: String
    var createdAt: Date
    
    init(username: String, role: UserRole, passwordHash: String) {
        self.id = UUID()
        self.username = username
        self.role = role
        self.passwordHash = passwordHash
        self.createdAt = Date()
    }
}

// MARK: - Enums
enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case viewer1 = "viewer1"
    case viewer2 = "viewer2"
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .viewer1: return "Görüntüleyici-1"
        case .viewer2: return "Görüntüleyici-2"
        }
    }
}

enum FormState: String, Codable, CaseIterable {
    case draft = "draft"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .draft: return "Taslak"
        case .completed: return "Tamamlandı"
        }
    }
}

// MARK: - Note Model
@Model
class Note {
    var id: UUID
    var title: String
    var text: String
    var createdAt: Date
    var lastEditedAt: Date
    var createdByUsername: String
    var lastEditedByUsername: String
    
    init(title: String = "Yeni Not", text: String, createdByUsername: String = "mert") {
        self.id = UUID()
        self.title = title
        self.text = text
        self.createdAt = Date()
        self.lastEditedAt = Date()
        self.createdByUsername = createdByUsername
        self.lastEditedByUsername = createdByUsername
    }
}

// MARK: - Sarnel Forms
@Model
class SarnelForm {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    var karatAyar: Int
    var girisAltin: Double?
    var cikisAltin: Double?
    var demirli_1: Double?
    var demirli_2: Double?
    var demirli_3: Double?
    var demirliHurda: Double?
    var demirliToz: Double?
    @Relationship(deleteRule: .cascade) var asitCikislari: [AsitItem]
    @Relationship(deleteRule: .cascade) var extraFireItems: [FireItem] = []
    var state: FormState
    var lastEditedAt: Date
    
    // Computed property for altın oranı
    var altinOrani: Double? {
        guard let giris = girisAltin,
              let cikis = cikisAltin,
              let demirli1 = demirli_1,
              let demirli2 = demirli_2,
              let demirli3 = demirli_3 else { return nil }
        
        let denominator = demirli1 + demirli2 + demirli3
        guard denominator > 0 else { return nil }
        
        return ((giris - cikis) / denominator) * 100
    }
    
    var totalAsitCikisi: Double {
        asitCikislari.reduce(0) { $0 + $1.valueGr }
    }
    
    var fire: Double? {
        guard let giris = girisAltin, let cikis = cikisAltin else { return nil }
        // Bitirme tablosundaki giriş değeri (giris - cikis)
        let girisTablosu = giris - cikis
        // Bitirme tablosundaki çıkış değeri (asit çıkışı + toz × altın oranı / 100)
        let totalAsitCikisi = asitCikislari.reduce(0) { $0 + $1.valueGr }
        let tozCikisi = (demirli_3 ?? 0) * (altinOrani ?? 0) / 100
        let cikisTablosu = totalAsitCikisi + tozCikisi
        // Fire = Bitirme tablosundaki giriş - çıkış
        return girisTablosu - cikisTablosu
    }
    
    var elapsedTime: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = endedAt ?? Date()
        return end.timeIntervalSince(start)
    }
    
    var finalFire: Double? {
        guard let initialFire = fire else { return nil }
        let totalExtraFire = extraFireItems.reduce(0) { $0 + $1.value }
        return initialFire - totalExtraFire
    }
    
    var totalFinalFire: Double? {
        guard let initialFire = fire else { return nil }
        let totalExtraFire = extraFireItems.reduce(0) { $0 + $1.value }
        return initialFire - totalExtraFire
    }
    
    init(karatAyar: Int) {
        self.id = UUID()
        self.createdAt = Date()
        self.karatAyar = karatAyar
        self.asitCikislari = []
        self.state = .draft
        self.lastEditedAt = Date()
    }
}

@Model
class AsitItem {
    @Attribute(.unique) var id: UUID
    var valueGr: Double
    var note: String?
    var createdAt: Date
    
    init(valueGr: Double, note: String? = nil) {
        self.id = UUID()
        self.valueGr = valueGr
        self.note = note
        self.createdAt = Date()
    }
}

@Model
class KilitToplamaForm {
    @Attribute(.unique) var id: UUID
    var model: String?
    var firma: String?
    var startedAt: Date?
    var endedAt: Date?
    var createdAt: Date
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var kasaItems: [KilitItem] = []
    @Relationship(deleteRule: .cascade) var dilItems: [KilitItem] = []
    @Relationship(deleteRule: .cascade) var yayItems: [KilitItem] = []
    @Relationship(deleteRule: .cascade) var kilitItems: [KilitItem] = []
    
    // Computed properties for totals
    var toplamGirisGram: Double {
        let allItems = kasaItems + dilItems + yayItems + kilitItems
        return allItems.reduce(0) { $0 + ($1.girisGram ?? 0) }
    }
    
    var toplamCikisGram: Double {
        let allItems = kasaItems + dilItems + yayItems + kilitItems
        return allItems.reduce(0) { $0 + ($1.cikisGram ?? 0) }
    }
    
    var dilAdetGiris: Double {
        return dilItems.reduce(0) { $0 + ($1.girisAdet ?? 0) }
    }
    
    var dilAdetCikis: Double {
        return dilItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) }
    }
    
    var kasaAdetGiris: Double {
        return kasaItems.reduce(0) { $0 + ($1.girisAdet ?? 0) }
    }
    
    var kasaAdetCikis: Double {
        return kasaItems.reduce(0) { $0 + ($1.cikisAdet ?? 0) }
    }
    
    var fireGram: Double {
        return toplamGirisGram - toplamCikisGram
    }
    
    var fireAdetDil: Double {
        return dilAdetGiris - dilAdetCikis
    }
    
    var fireAdetKasa: Double {
        return kasaAdetGiris - kasaAdetCikis
    }
    
    var elapsedTime: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = endedAt ?? Date()
        return end.timeIntervalSince(start)
    }
    
    init(model: String? = nil, firma: String? = nil, ayar: Int? = nil) {
        self.id = UUID()
        self.model = model
        self.firma = firma
        self.ayar = ayar
        self.createdAt = Date()
    }
}

@Model
class KilitItem {
    @Attribute(.unique) var id: UUID
    var girisAdet: Double?
    var girisGram: Double?
    var cikisGram: Double?
    var cikisAdet: Double?
    var createdAt: Date
    
    init(girisAdet: Double? = nil, girisGram: Double? = nil, cikisGram: Double? = nil, cikisAdet: Double? = nil) {
        self.id = UUID()
        self.girisAdet = girisAdet
        self.girisGram = girisGram
        self.cikisGram = cikisGram
        self.cikisAdet = cikisAdet
        self.createdAt = Date()
    }
}

@Model
class FireItem {
    @Attribute(.unique) var id: UUID
    var value: Double
    var note: String?
    var createdAt: Date
    
    init(value: Double, note: String? = nil) {
        self.id = UUID()
        self.value = value
        self.note = note
        self.createdAt = Date()
    }
}


// MARK: - Günlük Forms
@Model
class GunlukForm {
    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var tezgahCard: TezgahCard?
    @Relationship(deleteRule: .cascade) var ocakCard: OcakCard?
    @Relationship(deleteRule: .cascade) var patlatmaCard: PatlatmaCard?
    @Relationship(deleteRule: .cascade) var cilaCard: CilaCard?
    @Relationship(deleteRule: .cascade) var tamburCard: TamburCard?
    @Relationship(deleteRule: .cascade) var makineKesmeCard: MakineKesmeCard?
    @Relationship(deleteRule: .cascade) var testereKesmeCard: TestereKesmeCard?
    var state: FormState
    var lastEditedAt: Date
    
    init() {
        self.id = UUID()
        self.date = Date()
        self.createdAt = Date()
        self.tezgahCard = nil
        self.ocakCard = nil
        self.patlatmaCard = nil
        self.cilaCard = nil
        self.tamburCard = nil
        self.makineKesmeCard = nil
        self.testereKesmeCard = nil
        self.state = .draft
        self.lastEditedAt = Date()
    }
}

// MARK: - Günlük Card Types
@Model
class TezgahCard {
    @Attribute(.unique) var id: UUID
    var ayar: Int?
    @Relationship(deleteRule: .cascade) var rows: [TezgahRow]
    @Relationship(deleteRule: .cascade) var fires: [FireItem]
    
    
    init() {
        self.id = UUID()
        self.rows = []
        self.fires = []
    }
}

@Model
class TezgahRow {
    @Attribute(.unique) var id: UUID
    var aciklamaSol: String?
    @Relationship(deleteRule: .cascade) var giris: [ParcaDeger]
    @Relationship(deleteRule: .cascade) var cikis: [ParcaDeger]
    var aciklamaSag: String?
    var solAciklamaTimestamp: Date?
    var sagAciklamaTimestamp: Date?
    
    init() {
        self.id = UUID()
        self.giris = []
        self.cikis = []
    }
}

@Model
class ParcaDeger {
    @Attribute(.unique) var id: UUID
    var value: Double
    var createdAt: Date
    
    init(value: Double) {
        self.id = UUID()
        self.value = value
        self.createdAt = Date()
    }
}


// MARK: - Ocak Card (6 columns)
@Model  
class OcakCard {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var rows: [OcakRow]
    
    init() {
        self.id = UUID()
        self.rows = []
    }
}

@Model
class OcakRow {
    @Attribute(.unique) var id: UUID
    var aciklamaSol: String?
    @Relationship(deleteRule: .cascade) var giris: [ParcaDeger]
    @Relationship(deleteRule: .cascade) var cikis: [ParcaDeger]
    var aciklamaSag: String?
    var ayar: Int?
    var solAciklamaTimestamp: Date?
    var sagAciklamaTimestamp: Date?
    
    init() {
        self.id = UUID()
        self.giris = []
        self.cikis = []
    }
}

// MARK: - Other Card Types (similar structure to OcakCard)
@Model
class PatlatmaCard {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var rows: [OcakRow] // Reusing OcakRow as they have same structure
    
    init() {
        self.id = UUID()
        self.rows = []
    }
}

@Model
class CilaCard {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var rows: [OcakRow]
    
    init() {
        self.id = UUID()
        self.rows = []
    }
}

@Model
class TamburCard {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var rows: [OcakRow]
    
    init() {
        self.id = UUID()
        self.rows = []
    }
}

@Model
class MakineKesmeCard {
    @Attribute(.unique) var id: UUID
    
    init() {
        self.id = UUID()
    }
}

@Model
class TestereKesmeCard {
    @Attribute(.unique) var id: UUID
    
    init() {
        self.id = UUID()
    }
}




// MARK: - Backup Service
@MainActor
public class BackupService: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var lastBackupDate: Date?
    
    public init() {}
    
    // MARK: - Helper Export Functions
    
    private func exportTezgahKarti(_ kart: TezgahKarti) -> [String: Any] {
        var kartData: [String: Any] = [:]
        kartData["id"] = kart.id.uuidString
        kartData["ayar"] = kart.ayar as Any
        kartData["createdAt"] = kart.createdAt.ISO8601Format()
        
        kartData["satirlar"] = kart.satirlar.map { satir in
            [
                "id": satir.id.uuidString,
                "aciklamaGiris": satir.aciklamaGiris,
                "girisValue": satir.girisValue as Any,
                "cikisValue": satir.cikisValue as Any,
                "aciklamaCikis": satir.aciklamaCikis,
                "ayar": satir.ayar as Any,
                "aciklamaGirisTarihi": satir.aciklamaGirisTarihi?.ISO8601Format() as Any,
                "aciklamaCikisTarihi": satir.aciklamaCikisTarihi?.ISO8601Format() as Any,
                "orderIndex": satir.orderIndex
            ]
        }
        
        kartData["fireEklemeleri"] = kart.fireEklemeleri.map { fire in
            [
                "id": fire.id.uuidString,
                "value": fire.value as Any,
                "aciklama": fire.aciklama,
                "createdAt": fire.createdAt.ISO8601Format()
            ]
        }
        
        return kartData
    }
    
    private func exportCilaKarti(_ kart: CilaKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportOcakKarti(_ kart: OcakKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportPatlatmaKarti(_ kart: PatlatmaKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportTamburKarti(_ kart: TamburKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportMakineKesmeKarti(_ kart: MakineKesmeKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportTestereKesmeKarti(_ kart: TestereKesmeKarti) -> [String: Any] {
        return exportGenericKarti(id: kart.id, ayar: kart.ayar, createdAt: kart.createdAt, satirlar: kart.satirlar)
    }
    
    private func exportGenericKarti(id: UUID, ayar: Int?, createdAt: Date, satirlar: [IslemSatiri]) -> [String: Any] {
        var kartData: [String: Any] = [:]
        kartData["id"] = id.uuidString
        kartData["ayar"] = ayar as Any
        kartData["createdAt"] = createdAt.ISO8601Format()
        
        kartData["satirlar"] = satirlar.map { satir in
            var satirData: [String: Any] = [:]
            satirData["id"] = satir.id.uuidString
            satirData["aciklamaGiris"] = satir.aciklamaGiris
            satirData["aciklamaCikis"] = satir.aciklamaCikis
            satirData["aciklamaGirisTarihi"] = satir.aciklamaGirisTarihi?.ISO8601Format() as Any
            satirData["aciklamaCikisTarihi"] = satir.aciklamaCikisTarihi?.ISO8601Format() as Any
            satirData["aciklamaFire"] = satir.aciklamaFire
            satirData["aciklamaFireTarihi"] = satir.aciklamaFireTarihi?.ISO8601Format() as Any
            satirData["ayar"] = satir.ayar as Any
            satirData["orderIndex"] = satir.orderIndex
            
            satirData["girisValues"] = satir.girisValues.map { val in
                [
                    "id": val.id.uuidString,
                    "value": val.value as Any,
                    "eklemeTarihi": val.eklemeTarihi.ISO8601Format()
                ]
            }
            
            satirData["cikisValues"] = satir.cikisValues.map { val in
                [
                    "id": val.id.uuidString,
                    "value": val.value as Any,
                    "eklemeTarihi": val.eklemeTarihi.ISO8601Format()
                ]
            }
            
            return satirData
        }
        
        return kartData
    }
    
    func exportData(modelContext: ModelContext) throws -> URL {
        isExporting = true
        defer { isExporting = false }
        
        let timestamp = Date().timeIntervalSince1970
        let fileName = "nomis_backup_\(timestamp)"
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Create temporary directory
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var exportedData: [String: Any] = [:]
        exportedData["exportDate"] = Date().ISO8601Format()
        exportedData["version"] = "1.0"
        
        // Export YeniGunlukForm (Günlük İşlem Formları)
        let gunlukForms = try modelContext.fetch(FetchDescriptor<YeniGunlukForm>())
        exportedData["gunlukForms"] = gunlukForms.map { form in
            var formData: [String: Any] = [:]
            formData["id"] = form.id.uuidString
            formData["baslamaTarihi"] = form.baslamaTarihi.ISO8601Format()
            formData["createdAt"] = form.createdAt.ISO8601Format()
            formData["lastEditedAt"] = form.lastEditedAt?.ISO8601Format()
            formData["isCompleted"] = form.isCompleted
            formData["isWeeklyCompleted"] = form.isWeeklyCompleted
            formData["weeklyCompletedAt"] = form.weeklyCompletedAt?.ISO8601Format()
            
            // Export daily data with full card details
            formData["gunlukVeriler"] = form.gunlukVeriler.map { gunVerisi in
                var gunData: [String: Any] = [:]
                gunData["id"] = gunVerisi.id.uuidString
                gunData["tarih"] = gunVerisi.tarih.ISO8601Format()
                gunData["gunAdi"] = gunVerisi.gunAdi
                
                // Export Tezgah Kartları
                if let tezgah1 = gunVerisi.tezgahKarti1 {
                    gunData["tezgahKarti1"] = exportTezgahKarti(tezgah1)
                }
                if let tezgah2 = gunVerisi.tezgahKarti2 {
                    gunData["tezgahKarti2"] = exportTezgahKarti(tezgah2)
                }
                
                // Export Diğer Kartlar
                if let cila = gunVerisi.cilaKarti {
                    gunData["cilaKarti"] = exportCilaKarti(cila)
                }
                if let ocak = gunVerisi.ocakKarti {
                    gunData["ocakKarti"] = exportOcakKarti(ocak)
                }
                if let patlatma = gunVerisi.patlatmaKarti {
                    gunData["patlatmaKarti"] = exportPatlatmaKarti(patlatma)
                }
                if let tambur = gunVerisi.tamburKarti {
                    gunData["tamburKarti"] = exportTamburKarti(tambur)
                }
                if let makineKesme = gunVerisi.makineKesmeKarti1 {
                    gunData["makineKesmeKarti"] = exportMakineKesmeKarti(makineKesme)
                }
                if let testereKesme = gunVerisi.testereKesmeKarti1 {
                    gunData["testereKesmeKarti"] = exportTestereKesmeKarti(testereKesme)
                }
                
                return gunData
            }
            
            return formData
        }
        
        // Export KilitToplamaForm
        let kilitForms = try modelContext.fetch(FetchDescriptor<KilitToplamaForm>())
        exportedData["kilitForms"] = kilitForms.map { form in
            var formData: [String: Any] = [:]
            formData["id"] = form.id.uuidString
            formData["createdAt"] = form.createdAt.ISO8601Format()
            formData["startedAt"] = form.startedAt?.ISO8601Format()
            formData["endedAt"] = form.endedAt?.ISO8601Format()
            formData["model"] = form.model
            formData["firma"] = form.firma
            formData["ayar"] = form.ayar
            
            // Export all items
            formData["kasaItems"] = form.kasaItems.map { item in
                [
                    "id": item.id.uuidString,
                    "girisAdet": item.girisAdet as Any,
                    "girisGram": item.girisGram as Any,
                    "cikisGram": item.cikisGram as Any,
                    "cikisAdet": item.cikisAdet as Any
                ]
            }
            formData["dilItems"] = form.dilItems.map { item in
                [
                    "id": item.id.uuidString,
                    "girisAdet": item.girisAdet as Any,
                    "girisGram": item.girisGram as Any,
                    "cikisGram": item.cikisGram as Any,
                    "cikisAdet": item.cikisAdet as Any
                ]
            }
            formData["yayItems"] = form.yayItems.map { item in
                [
                    "id": item.id.uuidString,
                    "girisAdet": item.girisAdet as Any,
                    "girisGram": item.girisGram as Any,
                    "cikisGram": item.cikisGram as Any,
                    "cikisAdet": item.cikisAdet as Any
                ]
            }
            formData["kilitItems"] = form.kilitItems.map { item in
                [
                    "id": item.id.uuidString,
                    "girisAdet": item.girisAdet as Any,
                    "girisGram": item.girisGram as Any,
                    "cikisGram": item.cikisGram as Any,
                    "cikisAdet": item.cikisAdet as Any
                ]
            }
            
            return formData
        }
        
        // Export SarnelForm (detaylı)
        let sarnelForms = try modelContext.fetch(FetchDescriptor<SarnelForm>())
        exportedData["sarnelForms"] = sarnelForms.map { form in
            var formData: [String: Any] = [:]
            formData["id"] = form.id.uuidString
            formData["createdAt"] = form.createdAt.ISO8601Format()
            formData["startedAt"] = form.startedAt?.ISO8601Format()
            formData["endedAt"] = form.endedAt?.ISO8601Format()
            formData["karatAyar"] = form.karatAyar
            formData["lastEditedAt"] = form.lastEditedAt.ISO8601Format()
            formData["state"] = form.state.rawValue
            
            // Export all detailed data
            formData["girisAltin"] = form.girisAltin as Any
            formData["cikisAltin"] = form.cikisAltin as Any
            formData["demirli_1"] = form.demirli_1 as Any
            formData["demirli_2"] = form.demirli_2 as Any
            formData["demirli_3"] = form.demirli_3 as Any
            formData["demirliHurda"] = form.demirliHurda as Any
            formData["demirliToz"] = form.demirliToz as Any
            
            // Export asit çıkışları
            formData["asitCikislari"] = form.asitCikislari.map { asit in
                [
                    "id": asit.id.uuidString,
                    "valueGr": asit.valueGr,
                    "note": asit.note as Any,
                    "createdAt": asit.createdAt.ISO8601Format()
                ]
            }
            
            // Export extra fire items
            formData["extraFireItems"] = form.extraFireItems.map { fire in
                [
                    "id": fire.id.uuidString,
                    "value": fire.value,
                    "note": fire.note as Any,
                    "createdAt": fire.createdAt.ISO8601Format()
                ]
            }
            
            return formData
        }
        
        // Export Note
        let notes = try modelContext.fetch(FetchDescriptor<Note>())
        exportedData["notes"] = notes.map { note in
            [
                "id": note.id.uuidString,
                "title": note.title,
                "text": note.text,
                "createdAt": note.createdAt.ISO8601Format(),
                "lastEditedAt": note.lastEditedAt.ISO8601Format(),
                "createdByUsername": note.createdByUsername,
                "lastEditedByUsername": note.lastEditedByUsername
            ]
        }
        
        // Export ModelItem
        let models = try modelContext.fetch(FetchDescriptor<ModelItem>())
        exportedData["models"] = models.map { model in
            [
                "id": model.id.uuidString,
                "name": model.name,
                "createdAt": model.createdAt.ISO8601Format()
            ]
        }
        
        // Export CompanyItem
        let companies = try modelContext.fetch(FetchDescriptor<CompanyItem>())
        exportedData["companies"] = companies.map { company in
            [
                "id": company.id.uuidString,
                "name": company.name,
                "createdAt": company.createdAt.ISO8601Format()
            ]
        }
        
        // Save main JSON
        let jsonData = try JSONSerialization.data(withJSONObject: exportedData, options: .prettyPrinted)
        let jsonURL = tempDir.appendingPathComponent("backup.json")
        try jsonData.write(to: jsonURL)
        
        // Create ZIP file
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).zip")
        try createZipFile(from: tempDir, to: zipURL)
        
        // Clean up temp directory
        try FileManager.default.removeItem(at: tempDir)
        
        lastBackupDate = Date()
        return zipURL
    }
    
    func importData(from url: URL, modelContext: ModelContext) throws {
        isImporting = true
        defer { isImporting = false }
        
        // Extract ZIP file
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("nomis_import_\(Date().timeIntervalSince1970)")
        try extractZipFile(from: url, to: tempDir)
        
        // Read backup JSON
        let jsonURL = tempDir.appendingPathComponent("backup.json")
        let jsonData = try Data(contentsOf: jsonURL)
        
        guard let backupData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "BackupImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid backup file format"])
        }
        
        // Import Günlük Forms
        if let gunlukForms = backupData["gunlukForms"] as? [[String: Any]] {
            for formData in gunlukForms {
                guard let idString = formData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let baslamaTarihiString = formData["baslamaTarihi"] as? String,
                      let baslamaTarihi = ISO8601DateFormatter().date(from: baslamaTarihiString),
                      let createdAtString = formData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else { continue }
                
                // Check if form already exists
                let existingForms = try modelContext.fetch(FetchDescriptor<YeniGunlukForm>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingForms.isEmpty {
                    let newForm = YeniGunlukForm(baslamaTarihi: baslamaTarihi)
                    newForm.id = id
                    newForm.createdAt = createdAt
                    newForm.isCompleted = formData["isCompleted"] as? Bool ?? false
                    newForm.isWeeklyCompleted = formData["isWeeklyCompleted"] as? Bool ?? false
                    
                    if let lastEditedString = formData["lastEditedAt"] as? String {
                        newForm.lastEditedAt = ISO8601DateFormatter().date(from: lastEditedString)
                    }
                    if let weeklyCompletedString = formData["weeklyCompletedAt"] as? String {
                        newForm.weeklyCompletedAt = ISO8601DateFormatter().date(from: weeklyCompletedString)
                    }
                    
                    modelContext.insert(newForm)
                }
            }
        }
        
        // Import Kilit Forms
        if let kilitForms = backupData["kilitForms"] as? [[String: Any]] {
            for formData in kilitForms {
                guard let idString = formData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let createdAtString = formData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else { continue }
                
                // Check if form already exists
                let existingForms = try modelContext.fetch(FetchDescriptor<KilitToplamaForm>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingForms.isEmpty {
                    let newForm = KilitToplamaForm()
                    newForm.id = id
                    newForm.createdAt = createdAt
                    newForm.model = formData["model"] as? String
                    newForm.firma = formData["firma"] as? String
                    newForm.ayar = formData["ayar"] as? Int
                    
                    if let startedAtString = formData["startedAt"] as? String {
                        newForm.startedAt = ISO8601DateFormatter().date(from: startedAtString)
                    }
                    if let endedAtString = formData["endedAt"] as? String {
                        newForm.endedAt = ISO8601DateFormatter().date(from: endedAtString)
                    }
                    
                    modelContext.insert(newForm)
                }
            }
        }
        
        // Import Sarnel Forms
        if let sarnelForms = backupData["sarnelForms"] as? [[String: Any]] {
            for formData in sarnelForms {
                guard let idString = formData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let createdAtString = formData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else { continue }
                
                // Check if form already exists
                let existingForms = try modelContext.fetch(FetchDescriptor<SarnelForm>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingForms.isEmpty {
                    let newForm = SarnelForm(karatAyar: formData["karatAyar"] as? Int ?? 14)
                    newForm.id = id
                    newForm.createdAt = createdAt
                    
                    if let lastEditedString = formData["lastEditedAt"] as? String,
                       let lastEditedAt = ISO8601DateFormatter().date(from: lastEditedString) {
                        newForm.lastEditedAt = lastEditedAt
                    }
                    
                    if let stateRawValue = formData["state"] as? String,
                       let state = FormState(rawValue: stateRawValue) {
                        newForm.state = state
                    }
                    
                    // Import all detailed data
                    newForm.girisAltin = formData["girisAltin"] as? Double
                    newForm.cikisAltin = formData["cikisAltin"] as? Double
                    newForm.demirli_1 = formData["demirli_1"] as? Double
                    newForm.demirli_2 = formData["demirli_2"] as? Double
                    newForm.demirli_3 = formData["demirli_3"] as? Double
                    newForm.demirliHurda = formData["demirliHurda"] as? Double
                    newForm.demirliToz = formData["demirliToz"] as? Double
                    
                    modelContext.insert(newForm)
                }
            }
        }
        
        // Import Notes
        if let notes = backupData["notes"] as? [[String: Any]] {
            for noteData in notes {
                guard let idString = noteData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = noteData["title"] as? String,
                      let text = noteData["text"] as? String,
                      let createdAtString = noteData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString),
                      let lastEditedAtString = noteData["lastEditedAt"] as? String,
                      let lastEditedAt = ISO8601DateFormatter().date(from: lastEditedAtString) else { continue }
                
                // Check if note already exists
                let existingNotes = try modelContext.fetch(FetchDescriptor<Note>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingNotes.isEmpty {
                    let createdByUsername = noteData["createdByUsername"] as? String ?? "mert"
                    let newNote = Note(title: title, text: text, createdByUsername: createdByUsername)
                    newNote.id = id
                    newNote.createdAt = createdAt
                    newNote.lastEditedAt = lastEditedAt
                    newNote.lastEditedByUsername = noteData["lastEditedByUsername"] as? String ?? "mert"
                    
                    modelContext.insert(newNote)
                }
            }
        }
        
        // Import Models
        if let models = backupData["models"] as? [[String: Any]] {
            for modelData in models {
                guard let idString = modelData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = modelData["name"] as? String,
                      let createdAtString = modelData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else { continue }
                
                // Check if model already exists
                let existingModels = try modelContext.fetch(FetchDescriptor<ModelItem>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingModels.isEmpty {
                    let newModel = ModelItem(name: name)
                    newModel.id = id
                    newModel.createdAt = createdAt
                    
                    modelContext.insert(newModel)
                }
            }
        }
        
        // Import Companies
        if let companies = backupData["companies"] as? [[String: Any]] {
            for companyData in companies {
                guard let idString = companyData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = companyData["name"] as? String,
                      let createdAtString = companyData["createdAt"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else { continue }
                
                // Check if company already exists
                let existingCompanies = try modelContext.fetch(FetchDescriptor<CompanyItem>(
                    predicate: #Predicate { $0.id == id }
                ))
                
                if existingCompanies.isEmpty {
                    let newCompany = CompanyItem(name: name)
                    newCompany.id = id
                    newCompany.createdAt = createdAt
                    
                    modelContext.insert(newCompany)
                }
            }
        }
        
        // Save all changes
        try modelContext.save()
        
        // Clean up temp directory
        try FileManager.default.removeItem(at: tempDir)
    }
    
    // MARK: - Archive Utilities
    
    private func createZipFile(from sourceDir: URL, to destinationURL: URL) throws {
        // iOS doesn't allow Process, so we'll just save the JSON directly
        // The BackupView already expects a .zip content type, but we'll handle it there
        let jsonURL = sourceDir.appendingPathComponent("backup.json")
        
        // Copy the JSON file to destination
        try FileManager.default.copyItem(at: jsonURL, to: destinationURL)
    }
    
    private func extractZipFile(from sourceURL: URL, to destinationDir: URL) throws {
        // Create destination directory
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        
        // For now, assume the file is actually the JSON backup file
        let jsonURL = destinationDir.appendingPathComponent("backup.json")
        try FileManager.default.copyItem(at: sourceURL, to: jsonURL)
    }
}

// MARK: - Protocol for IslemKarti types
protocol IslemKartiProtocol {
    var satirlar: [IslemSatiri] { get }
}

// MARK: - New Daily Operations Models
@Model
class YeniGunlukForm {
    @Attribute(.unique) var id: UUID
    var baslamaTarihi: Date
    var createdAt: Date
    var lastEditedAt: Date?
    var isCompleted: Bool = false
    var isWeeklyCompleted: Bool = false
    var weeklyCompletedAt: Date?
    
    var bitisTarihi: Date {
        // O haftanın Cuma gününü hesapla ve döndür
        let calendar = Calendar.current
        
        // Başlama tarihinden başla
        var currentDate = baslamaTarihi
        
        // Başlama günü hafta sonu ise ilk iş gününe geç
        let startWeekday = calendar.component(.weekday, from: baslamaTarihi)
        if startWeekday == 1 || startWeekday == 7 { // Pazar veya Cumartesi
            let daysToMonday = startWeekday == 1 ? 1 : 2 // Pazar→1gün, Cumartesi→2gün
            if let nextMonday = calendar.date(byAdding: .day, value: daysToMonday, to: baslamaTarihi) {
                currentDate = nextMonday
            }
        }
        
        // O haftanın Cuma gününü bul
        let currentWeekday = calendar.component(.weekday, from: currentDate)
        let daysToFriday = 6 - currentWeekday // 6 = Cuma
        
        if let thisFriday = calendar.date(byAdding: .day, value: daysToFriday, to: currentDate) {
            return thisFriday
        }
        
        // Fallback olarak başlama tarihini döndür
        return baslamaTarihi
    }
    
    // Her gün için olan veriler (Pazartesi - Cuma)
    @Relationship(deleteRule: .cascade) var gunlukVeriler: [GunlukGunVerisi] = []
    
    init(baslamaTarihi: Date = Date()) {
        self.id = UUID()
        self.baslamaTarihi = baslamaTarihi
        self.createdAt = Date()
        self.lastEditedAt = Date()
        
        // Haftalık günleri init'te oluşturma - SwiftData crash yapabilir
        // createWeeklyDays() form insert edildikten sonra çağrılmalı
    }
    
    func createWeeklyDays() {
        let calendar = Calendar.current
        
        // Başlama tarihinin hangi haftaya ait olduğunu bul
        var referenceDate = baslamaTarihi
        
        // Eğer hafta sonu ise, bir sonraki haftanın pazartesi'si olacak
        let startWeekday = calendar.component(.weekday, from: baslamaTarihi)
        if startWeekday == 1 || startWeekday == 7 { // Pazar veya Cumartesi
            // Bir sonraki Pazartesi'yi bul
            let daysToMonday = startWeekday == 1 ? 1 : 2 // Pazar→1gün, Cumartesi→2gün
            if let nextMonday = calendar.date(byAdding: .day, value: daysToMonday, to: baslamaTarihi) {
                referenceDate = nextMonday
            }
        }
        
        // Referans tarihin o haftasının Pazartesi'sini bul
        let weekday = calendar.component(.weekday, from: referenceDate)
        let daysFromMonday = weekday - 2 // Pazartesi = 2, yani 0 olması lazım
        
        guard let weekMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: referenceDate) else {
            return
        }
        
        // O haftanın Cuma'sını bul
        guard let weekFriday = calendar.date(byAdding: .day, value: 4, to: weekMonday) else {
            return
        }
        
        // Pazartesi'den Cuma'ya kadar tüm iş günlerini oluştur
        var dayCounter = weekMonday
        while dayCounter <= weekFriday {
                let gunlukVeri = GunlukGunVerisi(tarih: dayCounter)
                gunlukVeriler.append(gunlukVeri)
            
            // Bir sonraki güne geç
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayCounter) else { break }
            dayCounter = nextDay
        }
    }
}

@Model
class GunlukGunVerisi {
    @Attribute(.unique) var id: UUID
    var tarih: Date
    var gunAdi: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: tarih).capitalized
    }
    
    // Kartlar
    // Multiple Tezgah kartları (sadece tezgahtan 2 tane)
    @Relationship(deleteRule: .cascade) var tezgahKarti1: TezgahKarti?
    @Relationship(deleteRule: .cascade) var tezgahKarti2: TezgahKarti?
    
    // Diğer kartlar (birer tane)
    @Relationship(deleteRule: .cascade) var cilaKarti: CilaKarti?
    @Relationship(deleteRule: .cascade) var ocakKarti: OcakKarti?
    @Relationship(deleteRule: .cascade) var patlatmaKarti: PatlatmaKarti?
    @Relationship(deleteRule: .cascade) var tamburKarti: TamburKarti?
    
    // Makine ve Testere Kesme kartları (birer tane)
    @Relationship(deleteRule: .cascade) var makineKesmeKarti1: MakineKesmeKarti?
    @Relationship(deleteRule: .cascade) var testereKesmeKarti1: TestereKesmeKarti?
    
    init(tarih: Date) {
        self.id = UUID()
        self.tarih = tarih
        // Kartları lazy loading için nil bırak
        // Kullanıldığında oluşturulacaklar
        self.tezgahKarti1 = nil
        self.tezgahKarti2 = nil
        self.cilaKarti = nil
        self.ocakKarti = nil
        self.patlatmaKarti = nil
        self.tamburKarti = nil
        self.makineKesmeKarti1 = nil
        self.testereKesmeKarti1 = nil
    }
}

@Model
class TezgahKarti {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [TezgahSatiri] = []
    @Relationship(deleteRule: .cascade) var fireEklemeleri: [FireEklemesi] = []
    
    // Hesaplanan değerler
    var toplamGiris: Double {
        satirlar.reduce(0) { $0 + ($1.girisValue ?? 0) }
    }
    
    var toplamCikis: Double {
        satirlar.reduce(0) { $0 + ($1.cikisValue ?? 0) }
    }
    
    var ilkFire: Double {
        max(0, toplamGiris - toplamCikis) // Fire negatif olamaz
    }
    
    var toplamEklenenFire: Double {
        fireEklemeleri.reduce(0) { $0 + ($1.value ?? 0) }
    }
    
    var sonFire: Double {
        max(0, ilkFire - toplamEklenenFire) // Fire negatif olamaz
    }
    
    var fire: Double {
        ilkFire
    }
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = TezgahSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
            }
        }
    }
}

@Model
class TezgahSatiri {
    @Attribute(.unique) var id: UUID
    var aciklamaGiris: String = ""
    var girisValue: Double?
    var cikisValue: Double?
    var aciklamaCikis: String = ""
    var ayar: Int?
    var aciklamaGirisTarihi: Date?
    var aciklamaCikisTarihi: Date?
    var createdAt: Date = Date()
    var orderIndex: Int = 0 // Satır sıralaması için
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        // Daha unique order index - microsecond precision
        self.orderIndex = Int(Date().timeIntervalSince1970 * 1000000) // Microsecond precision
    }
}

@Model
class FireEklemesi {
    @Attribute(.unique) var id: UUID
    var value: Double?
    var aciklama: String = ""
    var createdAt: Date = Date()
    
    init() {
        self.id = UUID()
    }
}

// Genişletilebilir Hücre Değeri - Bir hücreye sonradan değer eklenebilir
@Model
class GenisletilebilirDeger {
    @Attribute(.unique) var id: UUID
    var value: Double?
    var eklemeTarihi: Date = Date()
    
    init(value: Double? = nil) {
        self.id = UUID()
        self.value = value
    }
}

// Genel İşlem Satırı - Tüm kartlar için ortak yapı
@Model
class IslemSatiri {
    @Attribute(.unique) var id: UUID
    var aciklamaGiris: String = ""
    var aciklamaCikis: String = ""
    var aciklamaGirisTarihi: Date?
    var aciklamaCikisTarihi: Date?
    var aciklamaFire: String = ""  // Yeni: Fire ve Ayar arası açıklama
    var aciklamaFireTarihi: Date?  // Yeni: Fire açıklama tarihi
    var ayar: Int? // Her satır için bağımsız ayar değeri
    var createdAt: Date = Date()
    var orderIndex: Int = 0 // Satır sıralaması için
    
    // Genişletilebilir giriş değerleri
    @Relationship(deleteRule: .cascade) var girisValues: [GenisletilebilirDeger] = []
    // Genişletilebilir çıkış değerleri
    @Relationship(deleteRule: .cascade) var cikisValues: [GenisletilebilirDeger] = []
    
    // Hesaplanan değerler
    var toplamGiris: Double {
        girisValues.compactMap { $0.value }.reduce(0, +)
    }
    
    var toplamCikis: Double {
        cikisValues.compactMap { $0.value }.reduce(0, +)
    }
    
    var fire: Double {
        max(0, toplamGiris - toplamCikis) // Fire negatif olamaz
    }
    
    // Basit erişim için computed property'ler
    var giris: Double {
        get { toplamGiris }
        set { 
            // İlk değeri güncelle, yoksa ekle
            if girisValues.isEmpty {
                girisValues.append(GenisletilebilirDeger(value: newValue))
            } else {
                girisValues[0].value = newValue == 0 ? nil : newValue
            }
        }
    }
    
    var cikis: Double {
        get { toplamCikis }
        set { 
            // İlk değeri güncelle, yoksa ekle
            if cikisValues.isEmpty {
                cikisValues.append(GenisletilebilirDeger(value: newValue))
            } else {
                cikisValues[0].value = newValue == 0 ? nil : newValue
            }
        }
    }
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        // Daha unique order index - microsecond precision
        self.orderIndex = Int(Date().timeIntervalSince1970 * 1000000) // Microsecond precision
        // Değerler lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureValues() {
        // Değerler yoksa oluştur
        if girisValues.isEmpty {
            girisValues.append(GenisletilebilirDeger())
        }
        if cikisValues.isEmpty {
            cikisValues.append(GenisletilebilirDeger())
        }
    }
}

// Cila Kartı
@Model
class CilaKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

// Ocak Kartı
@Model
class OcakKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

// Patlatma Kartı
@Model
class PatlatmaKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

// Tambur Kartı
@Model
class TamburKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

// Makine Kesme Kartı
@Model
class MakineKesmeKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    @Relationship(deleteRule: .cascade) var fireEklemeleri: [FireEklemesi] = []
    
    // Hesaplanan toplamlar
    var toplamGiris: Double {
        satirlar.reduce(0) { $0 + $1.toplamGiris }
    }
    
    var toplamCikis: Double {
        satirlar.reduce(0) { $0 + $1.toplamCikis }
    }
    
    var toplamFire: Double {
        satirlar.reduce(0) { $0 + $1.fire }
    }
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

// Testere Kesme Kartı
@Model
class TestereKesmeKarti: IslemKartiProtocol {
    @Attribute(.unique) var id: UUID
    var createdAt: Date = Date()
    var ayar: Int?
    
    @Relationship(deleteRule: .cascade) var satirlar: [IslemSatiri] = []
    @Relationship(deleteRule: .cascade) var fireEklemeleri: [FireEklemesi] = []
    
    // Hesaplanan toplamlar
    var toplamGiris: Double {
        satirlar.reduce(0) { $0 + $1.toplamGiris }
    }
    
    var toplamCikis: Double {
        satirlar.reduce(0) { $0 + $1.toplamCikis }
    }
    
    var toplamFire: Double {
        satirlar.reduce(0) { $0 + $1.fire }
    }
    
    init() {
        self.id = UUID()
        // Satırlar lazy oluşturulacak - init'te @Relationship'e ekleme SwiftData crash yapar
    }
    
    func ensureRows() {
        // Satırlar yoksa oluştur
        if satirlar.isEmpty {
            let baseTime = Int(Date().timeIntervalSince1970 * 1000000)
            for i in 0..<5 {
                let satir = IslemSatiri()
                satir.orderIndex = baseTime + i
                satirlar.append(satir)
                // Her satır için değerleri oluştur (artık güvenli - satır append edildi)
                satir.ensureValues()
            }
        }
    }
}

