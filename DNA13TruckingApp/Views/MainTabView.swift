import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            // Dashboard Principal
            DashboardView()
                .tabItem {
                    Image(systemName: "gauge.medium")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Escanear Documentos
            DocumentScanView()
                .tabItem {
                    Image(systemName: "doc.text.viewfinder")
                    Text("Escanear")
                }
                .tag(1)
            
            // Chat IA
            AIChatView()
                .tabItem {
                    Image(systemName: "message.circle")
                    Text("IA Chat")
                }
                .tag(2)
            
            // Mapa de Rutas
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Mapa")
                }
                .tag(3)
            
            // Gestión de Cargas
            LoadManagementView()
                .tabItem {
                    Image(systemName: "truck.box")
                    Text("Cargas")
                }
                .tag(4)
            
            // CRM Operacional
            CRMView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("CRM")
                }
                .tag(5)
            
            // Alertas
            AlertsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Alertas")
                    if appState.recentAlerts.filter({ $0.status == "pending" }).count > 0 {
                        Text("\(appState.recentAlerts.filter({ $0.status == "pending" }).count)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .tag(6)
            
            // Perfil
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Perfil")
                }
                .tag(7)
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .tint(.dnaOrange)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(.dnaBackground)
            appearance.selectionIndicatorTintColor = UIColor(.dnaOrange)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var selectedRole: UserRole = .driver
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark, .dnaGreenDarker]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Company Info
                    VStack(spacing: 16) {
                        Image(systemName: "truck.box.badge.clockwise")
                            .font(.system(size: 64))
                            .foregroundColor(.dnaOrange)
                        
                        Text("D.N.A 13 Trucking")
                            .font(Typography.h1)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Text("La app de transporte más tecnológica")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("DOT #4058976")
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.6))
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Form Container
                    VStack(spacing: 20) {
                        // Toggle between Sign In and Sign Up
                        HStack(spacing: 0) {
                            Button(action: { isSignUp = false }) {
                                Text("Iniciar Sesión")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isSignUp ? Color.clear : Color.dnaOrange)
                                    .foregroundColor(isSignUp ? .dnaTextSecondary : .dnaBackground)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { isSignUp = true }) {
                                Text("Registrarse")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(!isSignUp ? Color.clear : Color.dnaOrange)
                                    .foregroundColor(!isSignUp ? .dnaTextSecondary : .dnaBackground)
                                    .cornerRadius(8)
                            }
                        }
                        .background(Color.dnaSurface)
                        .cornerRadius(8)
                        
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo Electrónico")
                                    .font(Typography.body)
                                    .foregroundColor(.dnaTextSecondary)
                                
                                TextField("correo@ejemplo.com", text: $email)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contraseña")
                                    .font(Typography.body)
                                    .foregroundColor(.dnaTextSecondary)
                                
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // Full Name (Sign Up only)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nombre Completo")
                                        .font(Typography.body)
                                        .foregroundColor(.dnaTextSecondary)
                                    
                                    TextField("Juan Pérez", text: $fullName)
                                        .textFieldStyle(ModernTextFieldStyle())
                                }
                                
                                // Role Selection (Sign Up only)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Rol")
                                        .font(Typography.body)
                                        .foregroundColor(.dnaTextSecondary)
                                    
                                    Picker("Seleccionar rol", selection: $selectedRole) {
                                        ForEach(UserRole.allCases, id: \.self) { role in
                                            Text(role.displayName).tag(role)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .background(Color.dnaSurface)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.dnaSurface)
                        .cornerRadius(12)
                        
                        // Sign In/Sign Up Button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    try await authManager.signUp(
                                        email: email,
                                        password: password,
                                        fullName: fullName,
                                        role: selectedRole
                                    )
                                } else {
                                    try await authManager.signIn(
                                        email: email,
                                        password: password
                                    )
                                }
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .dnaBackground))
                                } else {
                                    Text(isSignUp ? "Crear Cuenta" : "Iniciar Sesión")
                                        .font(Typography.button)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.dnaOrange)
                            .foregroundColor(.dnaBackground)
                            .cornerRadius(8)
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && fullName.isEmpty))
                        }
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && fullName.isEmpty))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Error Message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(Typography.body)
                            .foregroundColor(.dnaError)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.dnaSurfaceLight)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.dnaTextSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
