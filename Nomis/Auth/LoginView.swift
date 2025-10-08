import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                NomisTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Logo/Title Area
                    VStack(spacing: 16) {
                        Text("KİLİTÇİM")
                            .font(.system(size: 48, weight: .bold, design: .default))
                            .foregroundColor(NomisTheme.primary)
                        
                        VStack(spacing: 8) {
                            Text("Hesap her şeyden önemlidir. Acele etme,")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(NomisTheme.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("dikkatli ve titiz çalış...")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(NomisTheme.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("~Yalçın ERLİĞ")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(NomisTheme.primary)
                                .italic()
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kullanıcı Adı")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(NomisTheme.primary)
                                
                                TextField("Kullanıcı adınızı girin", text: $username)
                                    .textContentType(.username)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(NomisTheme.darkText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        NomisTheme.lightCream,
                                                        NomisTheme.lightCream.opacity(0.8)
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        NomisTheme.goldAccent.opacity(0.6),
                                                        NomisTheme.goldAccent.opacity(0.3)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: NomisTheme.goldAccent.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Şifre")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(NomisTheme.primary)
                                
                                SecureField("Şifrenizi girin", text: $password)
                                    .textContentType(.password)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(NomisTheme.darkText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        NomisTheme.lightCream,
                                                        NomisTheme.lightCream.opacity(0.8)
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        NomisTheme.goldAccent.opacity(0.6),
                                                        NomisTheme.goldAccent.opacity(0.3)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: NomisTheme.goldAccent.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            
                            // Error Message
                            if showError {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(errorMessage)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            
                            // Login Button
                            Button {
                                if username.isEmpty || password.isEmpty {
                                    showError(message: "Lütfen kullanıcı adı ve şifre giriniz")
                                } else {
                                    performLogin()
                                }
                            } label: {
                                Text("Giriş")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                username.isEmpty || password.isEmpty ? 
                                                NomisTheme.primary.opacity(0.3) : NomisTheme.primary,
                                                username.isEmpty || password.isEmpty ? 
                                                NomisTheme.primary.opacity(0.2) : NomisTheme.primary.opacity(0.8)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                NomisTheme.goldAccent.opacity(0.7),
                                                NomisTheme.goldAccent.opacity(0.4)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: NomisTheme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                            .scaleEffect(username.isEmpty || password.isEmpty ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: username.isEmpty || password.isEmpty)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        NomisTheme.goldAccent.opacity(0.4),
                                        NomisTheme.goldAccent.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: NomisTheme.goldAccent.opacity(0.2), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(NomisTheme.goldAccent.opacity(0.3))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                        
                        Text("Founded by Kadir ERLİĞ ~ Developed by Semih ÇETİNKAYA")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(NomisTheme.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func performLogin() {
        hideError()
        
        // Use AuthenticationManager's login method
        if authManager.login(username: username, password: password) {
            clearForm()
        } else {
            showError(message: "Kullanıcı adı veya şifre hatalı")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        // Hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            hideError()
        }
    }
    
    private func hideError() {
        showError = false
        errorMessage = ""
    }
    
    private func clearForm() {
        username = ""
        password = ""
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
