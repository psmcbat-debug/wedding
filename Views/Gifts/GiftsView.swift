import SwiftUI

struct GiftsView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingAddGift = false
    @State private var selectedFilter = GiftFilter.all
    @State private var searchText = ""
    
    var giftData: GiftData {
        appData.giftData ?? GiftData(gifts: [], updatedAt: Date())
    }
    
    var filteredGifts: [Gift] {
        let filtered = giftData.gifts.filter { gift in
            // Filtre par catégorie
            switch selectedFilter {
            case .all:
                return true
            case .money:
                return gift.category == .money
            case .items:
                return gift.category == .物品
            case .services:
                return gift.category == .service
            }
        }.filter { gift in
            // Filtre par recherche
            if searchText.isEmpty { return true }
            return gift.guestName.localizedCaseInsensitiveContains(searchText) ||
                   gift.description?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return filtered.sorted { $0.receivedDate > $1.receivedDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistiques en haut
                GiftStatsView(giftData: giftData)
                    .padding()
                
                // Liste des cadeaux
                List {
                    ForEach(filteredGifts) { gift in
                        GiftRowView(gift: gift)
                    }
                    .onDelete(perform: deleteGifts)
                }
                .searchable(text: $searchText, prompt: "Rechercher un cadeau...")
                .refreshable {
                    appData.refreshData()
                }
            }
            .navigationTitle("Cadeaux")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filtre", selection: $selectedFilter) {
                            ForEach(GiftFilter.allCases, id: \.self) { filter in
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
                        showingAddGift = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddGift) {
            AddGiftView()
        }
    }
    
    private func deleteGifts(offsets: IndexSet) {
        // TODO: Implémenter la suppression des cadeaux
    }
}

struct GiftStatsView: View {
    let giftData: GiftData
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                title: "Total",
                value: "\(giftData.giftCount)",
                color: .purple,
                subtitle: nil
            )
            
            StatBadge(
                title: "Argent",
                value: String(format: "%.0f€", giftData.totalMoneyReceived),
                color: .green,
                subtitle: nil
            )
            
            let moneyGifts = giftData.gifts.filter { $0.category == .money }.count
            StatBadge(
                title: "Espèces",
                value: "\(moneyGifts)",
                color: .blue,
                subtitle: nil
            )
            
            let itemGifts = giftData.gifts.filter { $0.category == .物品 }.count
            StatBadge(
                title: "Objets",
                value: "\(itemGifts)",
                color: .orange,
                subtitle: nil
            )
        }
    }
}

struct GiftRowView: View {
    let gift: Gift
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône de catégorie
            Circle()
                .fill(categoryColor(gift.category).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon(gift.category))
                        .foregroundColor(categoryColor(gift.category))
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gift.guestName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = gift.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Text(gift.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(gift.category).opacity(0.2))
                        .foregroundColor(categoryColor(gift.category))
                        .clipShape(Capsule())
                    
                    Text(gift.receivedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let amount = gift.amount {
                Text(String(format: "%.0f€", amount))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "gift.fill")
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(_ category: GiftCategory) -> Color {
        switch category {
        case .money: return .green
        case .物品: return .blue
        case .service: return .orange
        case .other: return .gray
        }
    }
    
    private func categoryIcon(_ category: GiftCategory) -> String {
        switch category {
        case .money: return "banknote"
        case .物品: return "gift"
        case .service: return "hand.raised"
        case .other: return "questionmark"
        }
    }
}

struct AddGiftView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var guestName = ""
    @State private var amount: Double?
    @State private var description = ""
    @State private var receivedDate = Date()
    @State private var category = GiftCategory.money
    @State private var notes = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations principales") {
                    TextField("Nom de l'invité", text: $guestName)
                        .autocapitalization(.words)
                    
                    Picker("Type de cadeau", selection: $category) {
                        ForEach(GiftCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    if category == .money {
                        HStack {
                            Text("Montant")
                            Spacer()
                            TextField("0", value: Binding(
                                get: { amount ?? 0 },
                                set: { amount = $0 > 0 ? $0 : nil }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            Text("€")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    DatePicker("Date de réception", selection: $receivedDate, displayedComponents: .date)
                }
                
                Section("Description") {
                    TextField("Description du cadeau", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Notes (optionnel)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Nouveau cadeau")
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
                        addGift()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addGift() {
        isLoading = true
        
        let newGift = Gift(
            guestName: guestName.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            description: description.isEmpty ? nil : description,
            receivedDate: receivedDate,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )
        
        appData.addGift(newGift)
        
        Task {
            await appData.saveGifts()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if appData.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

enum GiftFilter: CaseIterable {
    case all, money, items, services
    
    var displayName: String {
        switch self {
        case .all: return "Tous"
        case .money: return "Argent"
        case .items: return "Objets"
        case .services: return "Services"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "gift"
        case .money: return "banknote"
        case .items: return "shippingbox"
        case .services: return "hand.raised"
        }
    }
}

#Preview {
    GiftsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}