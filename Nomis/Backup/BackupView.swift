import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @StateObject private var backupService = BackupService()
    @State private var showingExportPicker = false
    @State private var showingImportPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    exportSection
                    
                    importSection
                    
                    if let lastBackup = backupService.lastBackupDate {
                        lastBackupSection(date: lastBackup)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Yedekleme")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: exportURL.map { BackupDocument(url: $0) },
            contentType: .json,
            defaultFilename: "Nomis_Backup_\(Date().formatted(.dateTime.year().month().day()))"
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert("Bilgi", isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.icloud")
                .font(.system(size: 60))
                .foregroundColor(NomisTheme.accent)
            
            Text("Veri Yedekleme")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(NomisTheme.primary)
            
            Text("Tüm verilerinizi JSON ve CSV formatlarında yedekleyebilir, başka cihazlara aktarabilirsiniz.")
                .font(.body)
                .foregroundColor(NomisTheme.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .nomisCard()
    }
    
    private var exportSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(NomisTheme.accent)
                Text("Veri Dışa Aktarma")
                    .font(.headline)
                    .foregroundColor(NomisTheme.primary)
                Spacer()
            }
            
            Text("Tüm verilerinizi ZIP dosyası olarak dışa aktarın. İçinde JSON ve CSV dosyaları bulunur.")
                .font(.body)
                .foregroundColor(NomisTheme.secondary)
                .multilineTextAlignment(.leading)
            
            Button(action: exportData) {
                HStack {
                    if backupService.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.doc")
                    }
                    Text(backupService.isExporting ? "Dışa Aktarılıyor..." : "Verileri Dışa Aktar")
                }
            }
            .buttonStyle(NomisButtonStyle(style: .primary))
            .disabled(backupService.isExporting || backupService.isImporting || !authManager.canEdit)
        }
        .nomisCard()
    }
    
    private var importSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(NomisTheme.accent)
                Text("Veri İçe Aktarma")
                    .font(.headline)
                    .foregroundColor(NomisTheme.primary)
                Spacer()
            }
            
            Text("Önceden dışa aktarılmış ZIP dosyasından verileri içe aktarın. Mevcut verilerle çakışmalar güvenli şekilde birleştirilir.")
                .font(.body)
                .foregroundColor(NomisTheme.secondary)
                .multilineTextAlignment(.leading)
            
            Button(action: importData) {
                HStack {
                    if backupService.isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.doc")
                    }
                    Text(backupService.isImporting ? "İçe Aktarılıyor..." : "Verileri İçe Aktar")
                }
            }
            .buttonStyle(NomisButtonStyle(style: .secondary))
            .disabled(backupService.isExporting || backupService.isImporting || !authManager.canEdit)
        }
        .nomisCard()
    }
    
    private func lastBackupSection(date: Date) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(NomisTheme.accent)
                Text("Son Yedekleme")
                    .font(.headline)
                    .foregroundColor(NomisTheme.primary)
                Spacer()
            }
            
            Text(date, formatter: NomisFormatters.dateTimeFormatter)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(NomisTheme.secondary)
        }
        .nomisCard()
    }
    
    private func exportData() {
        guard authManager.canEdit else { return }
        
        Task {
            do {
                let url = try backupService.exportData(modelContext: modelContext)
                await MainActor.run {
                    self.exportURL = url
                    self.showingExportPicker = true
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Dışa aktarma sırasında hata oluştu: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func importData() {
        guard authManager.canEdit else { return }
        showingImportPicker = true
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertMessage = "Veriler başarıyla dışa aktarıldı!"
            showingAlert = true
        case .failure(let error):
            alertMessage = "Dışa aktarma hatası: \(error.localizedDescription)"
            showingAlert = true
        }
        
        // Clean up temporary file
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    try backupService.importData(from: url, modelContext: modelContext)
                    await MainActor.run {
                        self.alertMessage = "Veriler başarıyla içe aktarıldı!"
                        self.showingAlert = true
                    }
                } catch {
                    await MainActor.run {
                        self.alertMessage = "İçe aktarma sırasında hata oluştu: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
            
        case .failure(let error):
            alertMessage = "Dosya seçimi hatası: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Document wrapper for file export
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        fatalError("Reading not supported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

#Preview {
    BackupView()
        .environmentObject(AuthenticationManager())
}
