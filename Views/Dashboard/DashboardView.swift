import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var appData: AppDataManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingAddQuickTask = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // En-tête de bienvenue
                    WelcomeHeader()
                    
                    // Statistiques rapides
                    QuickStatsGrid(stats: appData.dashboardStats)
                    
                    // Graphiques
                    ChartsSection(stats: appData.dashboardStats)
                    
                    // Tâches urgentes
                    UpcomingTasksSection()
                    
                    // Invités récents
                    RecentGuestsSection()
                    
                    // Actions rapides
                    QuickActionsSection()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Tableau de bord")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                appData.refreshData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddQuickTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddQuickTask) {
            QuickAddTaskView()
        }
    }
}

struct WelcomeHeader: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bonjour,")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.currentUser?.name ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.pink)
            }
            
            Text("Voici un aperçu de votre mariage")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct QuickStatsGrid: View {
    let stats: DashboardStats
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Invités",
                value: "\(stats.confirmedGuests)/\(stats.totalGuests)",
                subtitle: "confirmés",
                color: .blue,
                icon: "person.2.fill"
            )
            
            StatCard(
                title: "Budget",
                value: String(format: "%.0f€", stats.spentAmount),
                subtitle: String(format: "sur %.0f€", stats.totalBudget),
                color: .green,
                icon: "creditcard.fill"
            )
            
            StatCard(
                title: "Tâches",
                value: "\(stats.completedTasks)/\(stats.totalTasks)",
                subtitle: "terminées",
                color: .orange,
                icon: "checklist"
            )
            
            StatCard(
                title: "Cadeaux",
                value: "\(stats.totalGifts)",
                subtitle: String(format: "%.0f€", stats.totalGiftAmount),
                color: .purple,
                icon: "gift.fill"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ChartsSection: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progression")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Graphique budget
                BudgetProgressView(stats: stats)
                
                // Graphique tâches
                TaskProgressView(stats: stats)
            }
        }
    }
}

struct BudgetProgressView: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(stats.budgetPercentage))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
            
            ProgressView(value: stats.budgetPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Dépensé: \(String(format: "%.0f€", stats.spentAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Restant: \(String(format: "%.0f€", stats.remainingBudget))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TaskProgressView: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tâches")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(stats.taskCompletionPercentage))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            ProgressView(value: stats.taskCompletionPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Terminées: \(stats.completedTasks)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Restantes: \(stats.totalTasks - stats.completedTasks)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct UpcomingTasksSection: View {
    @EnvironmentObject private var appData: AppDataManager
    
    var upcomingTasks: [WeddingTask] {
        guard let taskData = appData.taskData else { return [] }
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        
        return taskData.tasks
            .filter { task in
                !task.isCompleted &&
                task.dueDate != nil &&
                task.dueDate! >= now &&
                task.dueDate! <= futureDate
            }
            .sorted { $0.dueDate! < $1.dueDate! }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tâches urgentes")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: TasksView()) {
                    Text("Voir tout")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal)
            
            if upcomingTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Aucune tâche urgente")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Excellent travail !")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(upcomingTasks) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: WeddingTask
    @EnvironmentObject private var appData: AppDataManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                appData.toggleTaskCompletion(task.id)
                Task {
                    await appData.saveTasks()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct RecentGuestsSection: View {
    @EnvironmentObject private var appData: AppDataManager
    
    var recentGuests: [Guest] {
        appData.guests
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Invités récents")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: GuestsListView()) {
                    Text("Voir tout")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal)
            
            if recentGuests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Aucun invité")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Ajoutez vos premiers invités")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentGuests) { guest in
                        GuestRowView(guest: guest)
                    }
                }
            }
        }
    }
}

struct GuestRowView: View {
    let guest: Guest
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(guest.attendance.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(guest.attendance.color).opacity(0.2))
                    .foregroundColor(Color(guest.attendance.color))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Text("\(guest.guestCount)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions rapides")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionButton(
                    title: "Ajouter invité",
                    icon: "person.badge.plus",
                    color: .blue,
                    destination: AnyView(AddGuestView())
                )
                
                QuickActionButton(
                    title: "Nouvelle tâche",
                    icon: "plus.square",
                    color: .orange,
                    destination: AnyView(AddTaskView())
                )
                
                QuickActionButton(
                    title: "Budget",
                    icon: "creditcard",
                    color: .green,
                    destination: AnyView(BudgetView())
                )
                
                QuickActionButton(
                    title: "Cadeaux",
                    icon: "gift",
                    color: .purple,
                    destination: AnyView(GiftsView())
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority = TaskPriority.medium
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Titre de la tâche", text: $title)
                
                DatePicker("Date limite", selection: $dueDate, displayedComponents: .date)
                
                Picker("Priorité", selection: $priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
            }
            .navigationTitle("Nouvelle tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        let task = WeddingTask(
                            title: title,
                            dueDate: dueDate,
                            isCompleted: false,
                            priority: priority,
                            category: .other
                        )
                        appData.addTask(task)
                        Task {
                            await appData.saveTasks()
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}