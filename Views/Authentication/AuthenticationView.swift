import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isShowingLogin = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arrière-plan dégradé
                LinearGradient(
                    colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo et titre
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.pink)
                        
                        Text("Wedding Manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Organisez votre mariage parfait")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Formulaires d'authentification
                    if isShowingLogin {
                        LoginView()
                            .transition(.move(edge: .leading))
                    } else {
                        RegisterView()
                            .transition(.move(edge: .trailing))
                    }
                    
                    // Bouton pour basculer entre login et register
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowingLogin.toggle()
                            authManager.clearError()
                        }
                    }) {
                        HStack {
                            Text(isShowingLogin ? "Pas encore de compte ?" : "Déjà un compte ?")
                                .foregroundColor(.secondary)
                            
                            Text(isShowingLogin ? "S'inscrire" : "Se connecter")
                                .foregroundColor(.pink)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Champs de saisie
            VStack(spacing: 16) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("votre@email.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Mot de passe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mot de passe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if showPassword {
                            TextField("Mot de passe", text: $password)
                        } else {
                            SecureField("Mot de passe", text: $password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Message d'erreur
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Bouton de connexion
            Button(action: {
                Task {
                    await authManager.login(email: email, password: password)
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text("Se connecter")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            .opacity((email.isEmpty || password.isEmpty || authManager.isLoading) ? 0.6 : 1.0)
        }
        .padding(.vertical, 20)
    }
}

struct RegisterView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !name.isEmpty && 
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Champs de saisie
            VStack(spacing: 16) {
                // Nom
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom complet")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Votre nom", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("votre@email.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Mot de passe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mot de passe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if showPassword {
                            TextField("Mot de passe", text: $password)
                        } else {
                            SecureField("Mot de passe", text: $password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Au moins 6 caractères")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Confirmation mot de passe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirmer le mot de passe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirmer", text: $confirmPassword)
                        } else {
                            SecureField("Confirmer", text: $confirmPassword)
                        }
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Les mots de passe ne correspondent pas")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Message d'erreur
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Bouton d'inscription
            Button(action: {
                Task {
                    await authManager.register(email: email, password: password, name: name)
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text("S'inscrire")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isFormValid || authManager.isLoading)
            .opacity((!isFormValid || authManager.isLoading) ? 0.6 : 1.0)
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    AuthenticationView()
}