import SwiftUI

struct AdminAuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var password: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let title: String
    let message: String
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: NomisTheme.largeSpacing) {
                VStack(spacing: NomisTheme.contentSpacing) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(NomisTheme.goldAccent)
                    
                    Text(title)
                        .font(.system(size: NomisTheme.titleSize, weight: NomisTheme.titleWeight))
                        .foregroundColor(NomisTheme.blackNight)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .foregroundColor(NomisTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, NomisTheme.largeSpacing)
                
                VStack(spacing: NomisTheme.contentSpacing) {
                    SecureField("Admin Şifresi", text: $password)
                        .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                        .padding(.horizontal, NomisTheme.contentSpacing)
                        .padding(.vertical, NomisTheme.contentSpacing)
                        .background(NomisTheme.lightCream)
                        .overlay(
                            Rectangle()
                                .stroke(NomisTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                        )
                        .onSubmit {
                            authenticateAdmin()
                        }
                    
                    if showingError {
                        Text(errorMessage)
                            .font(.system(size: NomisTheme.captionSize, weight: NomisTheme.captionWeight))
                            .foregroundColor(NomisTheme.destructive)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                HStack(spacing: NomisTheme.contentSpacing) {
                    Button("İptal") {
                        dismiss()
                    }
                    .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.bodyWeight))
                    .foregroundColor(NomisTheme.secondaryText)
                    .padding(.horizontal, NomisTheme.largeSpacing)
                    .padding(.vertical, NomisTheme.contentSpacing)
                    .background(NomisTheme.borderGray.opacity(0.3))
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    
                    Spacer()
                    
                    Button("Onayla") {
                        authenticateAdmin()
                    }
                    .font(.system(size: NomisTheme.bodySize, weight: NomisTheme.headlineWeight))
                    .foregroundColor(.white)
                    .padding(.horizontal, NomisTheme.largeSpacing)
                    .padding(.vertical, NomisTheme.contentSpacing)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [NomisTheme.primaryGreen, NomisTheme.primaryGreen.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    .disabled(password.isEmpty)
                    .opacity(password.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, NomisTheme.contentSpacing)
            }
            .padding(NomisTheme.contentSpacing)
            .navigationTitle("Admin Yetkilendirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(NomisTheme.secondaryText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func authenticateAdmin() {
        guard !password.isEmpty else { return }
        
        // Admin authentication using existing AuthenticationManager
        if authManager.authenticateAdmin(password: password) {
            onSuccess()
            dismiss()
        } else {
            errorMessage = "Yanlış admin şifresi. Lütfen tekrar deneyin."
            showingError = true
            password = ""
            
            // Hide error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingError = false
            }
        }
    }
}

#Preview {
    AdminAuthSheet(
        title: "Form Silme Yetkisi",
        message: "Bu formu silmek için admin şifrenizi girin."
    ) {
        // Default empty closure
    }
    .environmentObject(AuthenticationManager())
}