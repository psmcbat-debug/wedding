import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var selectedFilter = TaskFilter.all
    @State private var showingAddTask = false
    @State private var searchText = ""
    @State private var selectedTask: WeddingTask?
    
    var taskData: TaskData {
        appData.taskData ?? TaskData(tasks: [], updatedAt: Date())
    }
    
    var filteredTasks: [WeddingTask] {
        let tasks = taskData.tasks
        
        // Filtre par statut
        let statusFiltered = tasks.filter { task in
            switch selectedFilter {
            case .all:
                return true
            case .pending:
                return !task.isCompleted
            case .completed:
                return task.isCompleted
            case .overdue:
                let now = Date()
                return !task.isCompleted && task.dueDate != nil && task.dueDate! < now
            case .urgent:
                return task.priority == .urgent || task.priority == .high
            }
        }
        
        // Filtre par recherche
        let searchFiltered = statusFiltered.filter { task in
            if searchText.isEmpty { return true }
            return task.title.localizedCaseInsensitiveContains(searchText) ||
                   task.description?.localizedCaseInsensitiveContains(searchText) == true ||
                   task.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
        
        // Tri par date d'échéance puis par priorité
        return searchFiltered.sorted { lhs, rhs in
            // Les tâches non terminées en premier
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            
            // Puis par date d'échéance
            if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                return lhsDate < rhsDate
            } else if lhs.dueDate != nil {
                return true
            } else if rhs.dueDate != nil {
                return false
            }
            
            // Enfin par priorité
            let lhsPriority = priorityValue(lhs.priority)
            let rhsPriority = priorityValue(rhs.priority)
            return lhsPriority > rhsPriority
        }
    }
    
    private func priorityValue(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistiques en haut
                TaskStatsView(taskData: taskData)
                    .padding()
                
                // Liste des tâches
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                            .onTapGesture {
                                selectedTask = task
                            }
                    }
                    .onDelete(perform: deleteTasks)
                }
                .searchable(text: $searchText, prompt: "Rechercher une tâche...")
                .refreshable {
                    appData.refreshData()
                }
            }
            .navigationTitle("Tâches")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filtre", selection: $selectedFilter) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Label(filter.displayName, systemImage: filter.icon)
                                    .tag(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        // TODO: Implémenter la suppression des tâches
        // Pour l'instant, on ne fait rien car il faut implémenter l'API de suppression
    }
}

struct TaskStatsView: View {
    let taskData: TaskData
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                title: "Total",
                value: "\(taskData.tasks.count)",
                color: .blue,
                subtitle: nil
            )
            
            StatBadge(
                title: "Terminées",
                value: "\(taskData.completedTasks.count)",
                color: .green,
                subtitle: nil
            )
            
            StatBadge(
                title: "En retard",
                value: "\(taskData.overdueTasks.count)",
                color: .red,
                subtitle: nil
            )
            
            StatBadge(
                title: "Progression",
                value: "\(Int(taskData.completionPercentage))%",
                color: .orange,
                subtitle: nil
            )
        }
    }
}

struct TaskRowView: View {
    let task: WeddingTask
    @EnvironmentObject private var appData: AppDataManager
    
    var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Bouton de completion
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
            
            VStack(alignment: .leading, spacing: 6) {
                // Titre
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted)
                
                // Description (si présente)
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Badges et informations
                HStack(spacing: 8) {
                    // Priorité
                    Text(task.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(task.priority.color).opacity(0.2))
                        .foregroundColor(Color(task.priority.color))
                        .clipShape(Capsule())
                    
                    // Catégorie
                    Text(task.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Date d'échéance
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(isOverdue ? .red : .secondary)
                            .fontWeight(isOverdue ? .bold : .regular)
                    }
                }
            }
            
            // Indicateur visuel
            VStack {
                if isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                } else if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(isOverdue && !task.isCompleted ? Color.red.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority = TaskPriority.medium
    @State private var category = TaskCategory.other
    @State private var assignedTo = ""
    @State private var notes = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations principales") {
                    TextField("Titre de la tâche", text: $title)
                        .autocapitalization(.sentences)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Paramètres") {
                    Picker("Priorité", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Toggle("Date d'échéance", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Date limite", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                
                Section("Informations supplémentaires") {
                    TextField("Assigné à (optionnel)", text: $assignedTo)
                        .autocapitalization(.words)
                    
                    TextField("Notes (optionnel)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Nouvelle tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        addTask()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addTask() {
        isLoading = true
        
        let newTask = WeddingTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            dueDate: hasDueDate ? dueDate : nil,
            isCompleted: false,
            priority: priority,
            category: category,
            assignedTo: assignedTo.isEmpty ? nil : assignedTo,
            notes: notes.isEmpty ? nil : notes
        )
        
        appData.addTask(newTask)
        
        Task {
            await appData.saveTasks()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if appData.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

struct TaskDetailView: View {
    let task: WeddingTask
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingEditView = false
    
    var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // En-tête avec statut
                    TaskHeaderView(task: task, isOverdue: isOverdue)
                    
                    // Informations détaillées
                    TaskDetailsSection(task: task)
                    
                    // Actions
                    TaskActionsSection(task: task)
                }
                .padding()
            }
            .navigationTitle("Détails tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Modifier") {
                        showingEditView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditTaskView(task: task)
        }
    }
}

struct TaskHeaderView: View {
    let task: WeddingTask
    let isOverdue: Bool
    @EnvironmentObject private var appData: AppDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: {
                    appData.toggleTaskCompletion(task.id)
                    Task {
                        await appData.saveTasks()
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.largeTitle)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .strikethrough(task.isCompleted)
                    
                    HStack(spacing: 12) {
                        // Priorité
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(task.priority.color))
                                .frame(width: 8, height: 8)
                            Text(task.priority.displayName)
                                .font(.caption)
                                .foregroundColor(Color(task.priority.color))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(task.priority.color).opacity(0.1))
                        .clipShape(Capsule())
                        
                        // Catégorie
                        Text(task.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        if isOverdue {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("En retard")
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TaskDetailsSection: View {
    let task: WeddingTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                if let dueDate = task.dueDate {
                    DetailRow(
                        title: "Date d'échéance",
                        value: dueDate.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )
                }
                
                if let assignedTo = task.assignedTo, !assignedTo.isEmpty {
                    DetailRow(
                        title: "Assigné à",
                        value: assignedTo,
                        icon: "person.fill"
                    )
                }
                
                if task.isCompleted, let completedDate = task.completedDate {
                    DetailRow(
                        title: "Terminé le",
                        value: completedDate.formatted(date: .abbreviated, time: .shortened),
                        icon: "checkmark.circle.fill"
                    )
                }
                
                if let notes = task.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.blue)
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TaskActionsSection: View {
    let task: WeddingTask
    @EnvironmentObject private var appData: AppDataManager
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                appData.toggleTaskCompletion(task.id)
                Task {
                    await appData.saveTasks()
                }
            }) {
                HStack {
                    Image(systemName: task.isCompleted ? "arrow.counterclockwise" : "checkmark")
                    Text(task.isCompleted ? "Marquer comme non terminée" : "Marquer comme terminée")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.isCompleted ? Color.orange : Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // TODO: Ajouter d'autres actions comme supprimer, dupliquer, etc.
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct EditTaskView: View {
    let task: WeddingTask
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: TaskPriority
    @State private var category: TaskCategory
    @State private var assignedTo: String
    @State private var notes: String
    @State private var isLoading = false
    
    init(task: WeddingTask) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description ?? "")
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._priority = State(initialValue: task.priority)
        self._category = State(initialValue: task.category)
        self._assignedTo = State(initialValue: task.assignedTo ?? "")
        self._notes = State(initialValue: task.notes ?? "")
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations principales") {
                    TextField("Titre de la tâche", text: $title)
                        .autocapitalization(.sentences)
                    
                    TextField("Description (optionnel)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Paramètres") {
                    Picker("Priorité", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Toggle("Date d'échéance", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Date limite", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                
                Section("Informations supplémentaires") {
                    TextField("Assigné à (optionnel)", text: $assignedTo)
                        .autocapitalization(.words)
                    
                    TextField("Notes (optionnel)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Modifier tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sauvegarder") {
                        updateTask()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func updateTask() {
        isLoading = true
        
        let updatedTask = WeddingTask(
            id: task.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            dueDate: hasDueDate ? dueDate : nil,
            isCompleted: task.isCompleted,
            priority: priority,
            category: category,
            assignedTo: assignedTo.isEmpty ? nil : assignedTo,
            notes: notes.isEmpty ? nil : notes,
            completedDate: task.completedDate
        )
        
        appData.updateTask(updatedTask)
        
        Task {
            await appData.saveTasks()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if appData.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum TaskFilter: CaseIterable {
    case all, pending, completed, overdue, urgent
    
    var displayName: String {
        switch self {
        case .all: return "Toutes"
        case .pending: return "En cours"
        case .completed: return "Terminées"
        case .overdue: return "En retard"
        case .urgent: return "Urgentes"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        case .urgent: return "flame"
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}