import SwiftUI

@main
struct WeddingManagerApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var appData = AppDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(appData)
        }
    }
}