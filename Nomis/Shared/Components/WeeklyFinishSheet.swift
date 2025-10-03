import SwiftUI

struct WeeklyFinishSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var password = ""
    @State private var showingError = false
    
    let onFinish: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(NomisTheme.primaryGreen)
                
                VStack(spacing: 12) {
                    Text("Haftayı Bitir")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.primary)
                    
                    Text("Bu haftalık formu tamamlamak ve kaydetmek için admin şifrenizi girin.")
                        .font(.body)
                        .foregroundColor(NomisTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    SecureField("Admin Şifresi", text: $password)
                        .font(.title3)
                        .padding()
                        .background(NomisTheme.lightCream)
                        .overlay(
                            Rectangle()
                                .stroke(showingError ? Color.red : NomisTheme.primaryGreen, lineWidth: 2)
                        )
                        .onSubmit {
                            handleFinish()
                        }
                    
                    if showingError {
                        Text("Yanlış şifre!")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("İptal") {
                        isPresented = false
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.cardBackground)
                    .foregroundColor(NomisTheme.secondaryText)
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    
                    Button("Haftayı Bitir") {
                        handleFinish()
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NomisTheme.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(NomisTheme.buttonCornerRadius)
                    .disabled(password.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func handleFinish() {
        if authManager.authenticateAdmin(password: password) {
            isPresented = false
            onFinish()
        } else {
            showingError = true
            password = ""
            
            // Hatayı 2 saniye sonra gizle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingError = false
            }
        }
    }
}

#Preview {
    WeeklyFinishSheet(
        isPresented: .constant(true),
        onFinish: {}
    )
    .environmentObject(AuthenticationManager())
}
