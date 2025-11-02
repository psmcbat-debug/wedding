import SwiftUI
import Charts

struct BudgetView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingAddCategory = false
    @State private var showingBudgetSettings = false
    @State private var selectedCategory: BudgetCategory?
    
    var budgetData: BudgetData {
        appData.budgetData ?? BudgetData(categories: [], totalBudget: 0, updatedAt: Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Vue d'ensemble du budget
                    BudgetOverviewCard(budgetData: budgetData)
                    
                    // Graphique de répartition
                    if !budgetData.categories.isEmpty {
                        BudgetChartView(categories: budgetData.categories)
                    }
                    
                    // Catégories
                    BudgetCategoriesSection(
                        categories: budgetData.categories,
                        onCategoryTapped: { category in
                            selectedCategory = category
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingBudgetSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                appData.refreshData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddCategory) {
            AddBudgetCategoryView()
        }
        .sheet(isPresented: $showingBudgetSettings) {
            BudgetSettingsView(budgetData: budgetData)
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
    }
}

struct BudgetOverviewCard: View {
    let budgetData: BudgetData
    
    var body: some View {
        VStack(spacing: 16) {
            // Total et dépensé
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f€", budgetData.totalBudget))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dépensé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f€", budgetData.totalSpent))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Barre de progression
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: budgetData.totalSpent, total: budgetData.totalBudget)
                    .progressViewStyle(LinearProgressViewStyle(tint: budgetData.totalSpent > budgetData.totalBudget ? .red : .green))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text("Restant: \(String(format: "%.0f€", budgetData.remainingBudget))")
                        .font(.caption)
                        .foregroundColor(budgetData.remainingBudget < 0 ? .red : .secondary)
                    
                    Spacer()
                    
                    let percentage = budgetData.totalBudget > 0 ? (budgetData.totalSpent / budgetData.totalBudget) * 100 : 0
                    Text("\(Int(percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct BudgetChartView: View {
    let categories: [BudgetCategory]
    
    var chartData: [BudgetChartData] {
        categories.map { category in
            BudgetChartData(
                name: category.name,
                plannedAmount: category.plannedAmount,
                actualAmount: category.actualAmount
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Répartition par catégorie")
                .font(.headline)
                .fontWeight(.bold)
            
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.name) { data in
                    BarMark(
                        x: .value("Catégorie", data.name),
                        y: .value("Prévu", data.plannedAmount)
                    )
                    .foregroundStyle(.blue.opacity(0.7))
                    
                    BarMark(
                        x: .value("Catégorie", data.name),
                        y: .value("Réel", data.actualAmount)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback pour iOS < 16
                VStack(spacing: 8) {
                    ForEach(chartData, id: \.name) { data in
                        HStack {
                            Text(data.name)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Prévu: \(String(format: "%.0f€", data.plannedAmount))")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Réel: \(String(format: "%.0f€", data.actualAmount))")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            
            // Légende
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.blue.opacity(0.7))
                        .frame(width: 12, height: 12)
                    Text("Prévu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Text("Dépensé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct BudgetCategoriesSection: View {
    let categories: [BudgetCategory]
    let onCategoryTapped: (BudgetCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Catégories")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(categories.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Aucune catégorie")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Ajoutez vos premières catégories de budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(categories) { category in
                        BudgetCategoryRowView(category: category)
                            .onTapGesture {
                                onCategoryTapped(category)
                            }
                    }
                }
            }
        }
    }
}

struct BudgetCategoryRowView: View {
    let category: BudgetCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f€", category.actualAmount))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/ \(String(format: "%.0f€", category.plannedAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: category.actualAmount, total: category.plannedAmount)
                    .progressViewStyle(LinearProgressViewStyle(tint: category.actualAmount > category.plannedAmount ? .red : .green))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                
                HStack {
                    Text("Restant: \(String(format: "%.0f€", category.remainingAmount))")
                        .font(.caption)
                        .foregroundColor(category.remainingAmount < 0 ? .red : .secondary)
                    
                    Spacer()
                    
                    Text("\(Int(category.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Nombre d'articles
            if !category.items.isEmpty {
                Text("\(category.items.count) article(s)")
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

struct AddBudgetCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var categoryName = ""
    @State private var plannedAmount: Double = 0
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && plannedAmount > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations de la catégorie") {
                    TextField("Nom de la catégorie", text: $categoryName)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text("Budget prévu")
                        Spacer()
                        TextField("0", value: $plannedAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("Vous pourrez ajouter des articles à cette catégorie après sa création.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nouvelle catégorie")
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
                        addCategory()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addCategory() {
        isLoading = true
        
        let newCategory = BudgetCategory(
            name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            plannedAmount: plannedAmount,
            actualAmount: 0,
            items: []
        )
        
        appData.addBudgetCategory(newCategory)
        
        Task {
            await appData.saveBudget()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if appData.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

struct BudgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    let budgetData: BudgetData
    @State private var totalBudget: Double
    @State private var isLoading = false
    
    init(budgetData: BudgetData) {
        self.budgetData = budgetData
        self._totalBudget = State(initialValue: budgetData.totalBudget)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget global") {
                    HStack {
                        Text("Budget total")
                        Spacer()
                        TextField("0", value: $totalBudget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Statistiques") {
                    HStack {
                        Text("Nombre de catégories")
                        Spacer()
                        Text("\(budgetData.categories.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total dépensé")
                        Spacer()
                        Text(String(format: "%.0f€", budgetData.totalSpent))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Dernière mise à jour")
                        Spacer()
                        Text(budgetData.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Paramètres budget")
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
                        saveBudgetSettings()
                    }
                    .disabled(isLoading || totalBudget < 0)
                }
            }
        }
    }
    
    private func saveBudgetSettings() {
        isLoading = true
        
        if var budgetData = appData.budgetData {
            budgetData.totalBudget = totalBudget
            budgetData.updatedAt = Date()
            appData.budgetData = budgetData
            
            Task {
                await appData.saveBudget()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if appData.errorMessage == nil {
                        dismiss()
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
}

struct CategoryDetailView: View {
    let category: BudgetCategory
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Vue d'ensemble de la catégorie
                    CategoryOverviewCard(category: category)
                    
                    // Articles
                    CategoryItemsSection(category: category)
                }
                .padding()
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        showingAddItem = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddBudgetItemView(category: category)
        }
    }
}

struct CategoryOverviewCard: View {
    let category: BudgetCategory
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prévu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f€", category.plannedAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Dépensé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f€", category.actualAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: category.actualAmount, total: category.plannedAmount)
                    .progressViewStyle(LinearProgressViewStyle(tint: category.actualAmount > category.plannedAmount ? .red : .green))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text("Restant: \(String(format: "%.0f€", category.remainingAmount))")
                        .font(.caption)
                        .foregroundColor(category.remainingAmount < 0 ? .red : .secondary)
                    
                    Spacer()
                    
                    Text("\(Int(category.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct CategoryItemsSection: View {
    let category: BudgetCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Articles")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(category.items.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            if category.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Aucun article")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Ajoutez vos premiers articles à cette catégorie")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(category.items) { item in
                        BudgetItemRowView(item: item)
                    }
                }
            }
        }
    }
}

struct BudgetItemRowView: View {
    let item: BudgetItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isPaid ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(item.isPaid ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(item.isPaid)
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let date = item.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.0f€", item.amount))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(item.isPaid ? .green : .primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AddBudgetItemView: View {
    let category: BudgetCategory
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var itemName = ""
    @State private var amount: Double = 0
    @State private var notes = ""
    @State private var isPaid = false
    @State private var date = Date()
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations de l'article") {
                    TextField("Nom de l'article", text: $itemName)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text("Montant")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Toggle("Payé", isOn: $isPaid)
                }
                
                Section("Notes (optionnel)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nouvel article")
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
                        addItem()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addItem() {
        isLoading = true
        
        let newItem = BudgetItem(
            name: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            isPaid: isPaid,
            notes: notes.isEmpty ? nil : notes,
            date: date
        )
        
        // Ajouter l'item à la catégorie
        if var budgetData = appData.budgetData,
           let categoryIndex = budgetData.categories.firstIndex(where: { $0.id == category.id }) {
            budgetData.categories[categoryIndex].items.append(newItem)
            budgetData.categories[categoryIndex].actualAmount += amount
            budgetData.updatedAt = Date()
            appData.budgetData = budgetData
            
            Task {
                await appData.saveBudget()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if appData.errorMessage == nil {
                        dismiss()
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
}

// MARK: - Supporting Types
struct BudgetChartData {
    let name: String
    let plannedAmount: Double
    let actualAmount: Double
}

#Preview {
    BudgetView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}