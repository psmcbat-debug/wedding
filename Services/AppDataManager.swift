import Foundation
import Combine

class AppDataManager: ObservableObject {
    static let shared = AppDataManager()
    
    // MARK: - Published Properties
    @Published var guests: [Guest] = []
    @Published var budgetData: BudgetData?
    @Published var giftData: GiftData?
    @Published var taskData: TaskData?
    @Published var seatingChart: SeatingChart?
    @Published var hallLayout: HallLayout?
    @Published var messages: [Message] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Statistics
    var dashboardStats: DashboardStats {
        DashboardStats(
            totalGuests: guests.count,
            confirmedGuests: guests.filter { $0.attendance == .oui }.count,
            totalBudget: budgetData?.totalBudget ?? 0,
            spentAmount: budgetData?.totalSpent ?? 0,
            completedTasks: taskData?.completedTasks.count ?? 0,
            totalTasks: taskData?.tasks.count ?? 0,
            totalGifts: giftData?.giftCount ?? 0,
            totalGiftAmount: giftData?.totalMoneyReceived ?? 0,
            unreadMessages: messages.filter { !$0.isRead }.count
        )
    }
    
    init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    @MainActor
    func loadAllData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            async let guestsTask = loadGuests()
            async let budgetTask = loadBudget()
            async let giftsTask = loadGifts()
            async let tasksTask = loadTasks()
            
            await guestsTask
            await budgetTask
            await giftsTask
            await tasksTask
            
            isLoading = false
        }
    }
    
    @MainActor
    func refreshData() {
        loadAllData()
    }
    
    // MARK: - Guests Management
    @MainActor
    private func loadGuests() async {
        do {
            let loadedGuests = try await APIService.shared.loadGuests()
            self.guests = loadedGuests
        } catch {
            self.errorMessage = "Erreur lors du chargement des invités: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func addGuest(_ guest: Guest) async {
        do {
            let newGuest = try await APIService.shared.addGuest(guest)
            self.guests.append(newGuest)
        } catch {
            self.errorMessage = "Erreur lors de l'ajout de l'invité: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func updateGuest(_ guest: Guest) async {
        do {
            let updatedGuest = try await APIService.shared.updateGuest(guest)
            if let index = guests.firstIndex(where: { $0.id == guest.id }) {
                guests[index] = updatedGuest
            }
        } catch {
            self.errorMessage = "Erreur lors de la mise à jour de l'invité: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Budget Management
    @MainActor
    private func loadBudget() async {
        do {
            self.budgetData = try await APIService.shared.loadBudget()
        } catch {
            self.errorMessage = "Erreur lors du chargement du budget: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func saveBudget() async {
        guard let budgetData = budgetData else { return }
        
        do {
            let success = try await APIService.shared.saveBudget(budgetData)
            if !success {
                self.errorMessage = "Erreur lors de la sauvegarde du budget"
            }
        } catch {
            self.errorMessage = "Erreur lors de la sauvegarde du budget: \(error.localizedDescription)"
        }
    }
    
    func addBudgetCategory(_ category: BudgetCategory) {
        if budgetData == nil {
            budgetData = BudgetData(categories: [], totalBudget: 0, updatedAt: Date())
        }
        budgetData?.categories.append(category)
        budgetData?.updatedAt = Date()
    }
    
    func updateBudgetCategory(_ category: BudgetCategory) {
        guard let index = budgetData?.categories.firstIndex(where: { $0.id == category.id }) else { return }
        budgetData?.categories[index] = category
        budgetData?.updatedAt = Date()
    }
    
    // MARK: - Gifts Management
    @MainActor
    private func loadGifts() async {
        do {
            self.giftData = try await APIService.shared.loadGifts()
        } catch {
            self.errorMessage = "Erreur lors du chargement des cadeaux: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func saveGifts() async {
        guard let giftData = giftData else { return }
        
        do {
            let success = try await APIService.shared.saveGifts(giftData)
            if !success {
                self.errorMessage = "Erreur lors de la sauvegarde des cadeaux"
            }
        } catch {
            self.errorMessage = "Erreur lors de la sauvegarde des cadeaux: \(error.localizedDescription)"
        }
    }
    
    func addGift(_ gift: Gift) {
        if giftData == nil {
            giftData = GiftData(gifts: [], updatedAt: Date())
        }
        giftData?.gifts.append(gift)
        giftData?.updatedAt = Date()
    }
    
    // MARK: - Tasks Management
    @MainActor
    private func loadTasks() async {
        do {
            self.taskData = try await APIService.shared.loadTasks()
        } catch {
            self.errorMessage = "Erreur lors du chargement des tâches: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func saveTasks() async {
        guard let taskData = taskData else { return }
        
        do {
            let success = try await APIService.shared.saveTasks(taskData)
            if !success {
                self.errorMessage = "Erreur lors de la sauvegarde des tâches"
            }
        } catch {
            self.errorMessage = "Erreur lors de la sauvegarde des tâches: \(error.localizedDescription)"
        }
    }
    
    func addTask(_ task: WeddingTask) {
        if taskData == nil {
            taskData = TaskData(tasks: [], updatedAt: Date())
        }
        taskData?.tasks.append(task)
        taskData?.updatedAt = Date()
    }
    
    func updateTask(_ task: WeddingTask) {
        guard let index = taskData?.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        taskData?.tasks[index] = task
        taskData?.updatedAt = Date()
    }
    
    func toggleTaskCompletion(_ taskId: UUID) {
        guard let index = taskData?.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        taskData?.tasks[index].isCompleted.toggle()
        
        if taskData?.tasks[index].isCompleted == true {
            taskData?.tasks[index].completedDate = Date()
        } else {
            taskData?.tasks[index].completedDate = nil
        }
        
        taskData?.updatedAt = Date()
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Dashboard Statistics
struct DashboardStats {
    let totalGuests: Int
    let confirmedGuests: Int
    let totalBudget: Double
    let spentAmount: Double
    let completedTasks: Int
    let totalTasks: Int
    let totalGifts: Int
    let totalGiftAmount: Double
    let unreadMessages: Int
    
    var remainingBudget: Double {
        totalBudget - spentAmount
    }
    
    var budgetPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return (spentAmount / totalBudget) * 100
    }
    
    var taskCompletionPercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks) * 100
    }
    
    var guestConfirmationPercentage: Double {
        guard totalGuests > 0 else { return 0 }
        return Double(confirmedGuests) / Double(totalGuests) * 100
    }
}