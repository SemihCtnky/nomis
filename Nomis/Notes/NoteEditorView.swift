import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    let note: Note?
    @State private var title: String = ""
    @State private var text: String = ""
    @State private var showingSaveAlert = false
    @State private var hasChanges = false
    
    // Auto-save timer
    @State private var autoSaveTimer: Timer?
    
    init(note: Note? = nil) {
        self.note = note
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: NomisTheme.contentSpacing) {
                // Başlık alanı
                TextField("Not Başlığı", text: $title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(NomisTheme.contentSpacing)
                    .background(NomisTheme.cardBackground)
                    .cornerRadius(NomisTheme.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: NomisTheme.cardCornerRadius)
                            .stroke(NomisTheme.border, lineWidth: 1)
                    )
                    .onChange(of: title) { _, newValue in
                        onContentChanged()
                    }
                
                // Metin alanı
                TextEditor(text: $text)
                    .padding(NomisTheme.contentSpacing)
                    .background(NomisTheme.cardBackground)
                    .cornerRadius(NomisTheme.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: NomisTheme.cardCornerRadius)
                            .stroke(NomisTheme.border, lineWidth: 1)
                    )
                    .onChange(of: text) { _, newValue in
                        onContentChanged()
                    }
                
                Spacer()
                
                if authManager.canEdit {
                    Button("Kaydet") {
                        saveNote()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(NomisTheme.contentSpacing)
            .navigationTitle(note == nil ? "Yeni Not" : "Notu Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        if hasChanges {
                            showingSaveAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveNote()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Değişiklikleri Kaydet", isPresented: $showingSaveAlert) {
                Button("Kaydetme", role: .cancel) {
                    dismiss()
                }
                Button("Kaydet") {
                    saveNote()
                }
            } message: {
                Text("Kaydedilmemiş değişiklikleriniz var. Kaydetmek istiyor musunuz?")
            }
            .onAppear {
                if let note = note {
                    title = note.title
                    text = note.text
                }
                setupAutoSave()
            }
            .onDisappear {
                stopAutoSave()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func onContentChanged() {
        hasChanges = true
        
        // Reset auto-save timer
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            autoSave()
        }
    }
    
    private func setupAutoSave() {
        // Start auto-save timer for existing notes
        if note != nil {
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                autoSave()
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func autoSave() {
        guard hasChanges,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let existingNote = note {
            // Update existing note
            existingNote.title = title
            existingNote.text = text
            existingNote.lastEditedAt = Date()
            existingNote.lastEditedByUsername = authManager.currentUsername
            try? modelContext.save()
            hasChanges = false
        } else {
            // Create new note as draft
            let newNote = Note(title: title, text: text, createdByUsername: authManager.currentUsername)
            modelContext.insert(newNote)
            try? modelContext.save()
            hasChanges = false
        }
    }
    
    private func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty && !trimmedText.isEmpty else { return }
        
        if let existingNote = note {
            // Update existing note
            existingNote.title = trimmedTitle
            existingNote.text = trimmedText
            existingNote.lastEditedAt = Date()
            existingNote.lastEditedByUsername = authManager.currentUsername
        } else {
            // Create new note
            let newNote = Note(title: trimmedTitle, text: trimmedText, createdByUsername: authManager.currentUsername)
            modelContext.insert(newNote)
        }
        
        try? modelContext.save()
        hasChanges = false
        dismiss()
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: config)
        
        return NoteEditorView(note: nil)
            .environmentObject(AuthenticationManager())
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
