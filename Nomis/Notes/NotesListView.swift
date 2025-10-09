import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var showingAddNote = false
    @State private var selectedNote: Note?
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: Note?
    @State private var showingAdminAuth = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if notes.isEmpty {
                    Text("Henüz not eklenmemiş")
                        .foregroundColor(NomisTheme.secondaryText)
                        .font(.body)
                        .padding()
                } else {
                    List {
                        ForEach(notes) { note in
                            NoteRowView(
                                note: note,
                                onTap: { selectedNote = note },
                                onEdit: authManager.canEdit ? { selectedNote = note } : nil
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if authManager.canDelete {
                                    Button(role: .destructive) {
                                        noteToDelete = note
                                        showingAdminAuth = true
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yeni Not") {
                        showingAddNote = true
                    }
                    .foregroundColor(NomisTheme.primary)
                }
            }
            .sheet(isPresented: $showingAddNote) {
                NoteEditorView()
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorView(note: note)
            }
            .alert("Notu Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) {
                    noteToDelete = nil
                }
                Button("Sil", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                }
            } message: {
                Text("Bu notu silmek istediğinizden emin misiniz?")
            }
            .sheet(isPresented: $showingAdminAuth) {
                AdminAuthSheet(
                    title: "Yönetici Yetkisi Gerekli",
                    message: "Bu notu silmek için admin şifrenizi girin."
                ) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                    noteToDelete = nil
                }
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation {
            modelContext.delete(note)
            try? modelContext.save()
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let onTap: () -> Void
    let onEdit: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
                        Text(note.title)
                            .font(.headline)
                            .foregroundColor(NomisTheme.text)
                            .lineLimit(1)
                        
                        Text(note.text)
                            .font(.body)
                            .foregroundColor(NomisTheme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Oluşturan: \(note.createdByUsername)")
                                    .font(.caption2)
                                    .foregroundColor(NomisTheme.primary)
                                
                                Spacer()
                                
                                Text(Formatters.formatDateTime(note.createdAt))
                                    .font(.caption2)
                                    .foregroundColor(NomisTheme.secondaryText)
                            }
                            
                            if note.lastEditedAt != note.createdAt {
                                HStack {
                                    Text("Son düzenleyen: \(note.lastEditedByUsername)")
                                        .font(.caption2)
                                        .foregroundColor(NomisTheme.primary)
                                    
                                    Spacer()
                                    
                                    Text(Formatters.formatDateTime(note.lastEditedAt))
                                        .font(.caption2)
                                        .foregroundColor(NomisTheme.secondaryText)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(24)
                                .background(NomisTheme.primaryGreen)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, NomisTheme.smallSpacing)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NotesListView()
        .environmentObject(AuthenticationManager())
        .modelContainer(for: Note.self, inMemory: true)
}
