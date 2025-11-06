import SwiftUI

@main
struct DNA13TruckingApp: App {
    let supabaseService = SupabaseService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseService)
                .preferredColorScheme(.dark) // Default to dark mode for trucking operations
        }
    }
}

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(appState)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            authManager.checkAuthStatus()
        }
    }
}

#Preview {
    ContentView()
}
