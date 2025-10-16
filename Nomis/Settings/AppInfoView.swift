import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Icon Section
                VStack(spacing: 16) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 80))
                        .foregroundColor(NomisTheme.primaryGreen)
                    
                    Text("NOMIS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(NomisTheme.primary)
                    
                    Text("Yönetim Sistemi")
                        .font(.headline)
                        .foregroundColor(NomisTheme.secondaryText)
                }
                
                // App Information
                VStack(spacing: 20) {
                    InfoRowView(title: "Uygulama Adı", value: "NOMIS")
                    InfoRowView(title: "Versiyon", value: "1.4.0")
                    InfoRowView(title: "Geliştirici", value: "NOMIS Team")
                    InfoRowView(title: "Son Güncelleme", value: "2025")
                }
                .padding()
                .background(NomisTheme.lightCream)
                .cornerRadius(12)
                
                Spacer()
                
                // Logout Section
                VStack(spacing: 16) {
                    Button("Çıkış Yap") {
                        authManager.logout()
                        dismiss()
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Text("Mevcut kullanıcı: \(authManager.currentUsername)")
                        .font(.caption)
                        .foregroundColor(NomisTheme.secondaryText)
                }
            }
            .padding()
        }
    }
}

struct InfoRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(NomisTheme.darkText)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(NomisTheme.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    AppInfoView()
        .environmentObject(AuthenticationManager())
}
