import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var appData: AppDataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Accueil")
                }
                .tag(0)
            
            // Invités
            GuestsListView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Invités")
                }
                .tag(1)
            
            // Budget
            BudgetView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Budget")
                }
                .tag(2)
            
            // Tâches
            TasksView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tâches")
                }
                .tag(3)
            
            // Plus
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("Plus")
                }
                .tag(4)
        }
        .accentColor(.pink)
        .onAppear {
            // Charger les données au premier lancement
            if appData.guests.isEmpty {
                appData.loadAllData()
            }
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // Section Données
                Section("Données") {
                    NavigationLink(destination: GiftsView()) {
                        Label("Cadeaux", systemImage: "gift.fill")
                            .foregroundColor(.orange)
                    }
                    
                    NavigationLink(destination: SeatingChartView()) {
                        Label("Plan de table", systemImage: "table.furniture.fill")
                            .foregroundColor(.blue)
                    }
                    
                    NavigationLink(destination: HallDesignerView()) {
                        Label("Plan de salle", systemImage: "building.2.fill")
                            .foregroundColor(.green)
                    }
                    
                    NavigationLink(destination: InboxView()) {
                        Label("Messages", systemImage: "envelope.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                // Section Outils
                Section("Outils") {
                    NavigationLink(destination: ExportsView()) {
                        Label("Exports", systemImage: "square.and.arrow.up.fill")
                            .foregroundColor(.indigo)
                    }
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Label("Paramètres", systemImage: "gear.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // Section Compte
                Section("Compte") {
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        authManager.logout()
                    }) {
                        Label("Se déconnecter", systemImage: "arrow.right.square.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Plus")
            .refreshable {
                AppDataManager.shared.refreshData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var autoSync = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Activer les notifications", isOn: $notificationsEnabled)
                    Toggle("Synchronisation automatique", isOn: $autoSync)
                }
                
                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Nous contacter") {
                        // Action pour contacter le support
                    }
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}