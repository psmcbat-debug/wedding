import SwiftUI

struct SeatingChartView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingAddTable = false
    @State private var selectedTable: WeddingTable?
    
    var seatingChart: SeatingChart {
        appData.seatingChart ?? SeatingChart(tables: [], updatedAt: Date())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistiques
                SeatingStatsView(seatingChart: seatingChart)
                    .padding()
                
                // Vue du plan de table
                ScrollView([.horizontal, .vertical]) {
                    SeatingPlanView(
                        tables: seatingChart.tables,
                        onTableTapped: { table in
                            selectedTable = table
                        }
                    )
                    .frame(minWidth: 400, minHeight: 400)
                }
                .background(Color(.systemGray6))
            }
            .navigationTitle("Plan de table")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTable = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddTable) {
            AddTableView()
        }
        .sheet(item: $selectedTable) { table in
            TableDetailView(table: table)
        }
    }
}

struct SeatingStatsView: View {
    let seatingChart: SeatingChart
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                title: "Tables",
                value: "\(seatingChart.tables.count)",
                color: .blue,
                subtitle: nil
            )
            
            StatBadge(
                title: "Places",
                value: "\(seatingChart.totalSeats)",
                color: .green,
                subtitle: "total"
            )
            
            StatBadge(
                title: "Occupées",
                value: "\(seatingChart.occupiedSeats)",
                color: .orange,
                subtitle: nil
            )
            
            StatBadge(
                title: "Libres",
                value: "\(seatingChart.availableSeats)",
                color: .purple,
                subtitle: nil
            )
        }
    }
}

struct SeatingPlanView: View {
    let tables: [WeddingTable]
    let onTableTapped: (WeddingTable) -> Void
    
    var body: some View {
        ZStack {
            ForEach(tables) { table in
                TableView(table: table)
                    .position(x: table.position.x, y: table.position.y)
                    .onTapGesture {
                        onTableTapped(table)
                    }
            }
        }
        .frame(width: 600, height: 600)
    }
}

struct TableView: View {
    let table: WeddingTable
    
    var body: some View {
        VStack(spacing: 4) {
            // Forme de la table
            tableShape
                .fill(table.isComplete ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                .stroke(table.isComplete ? Color.green : Color.blue, lineWidth: 2)
                .frame(width: tableWidth, height: tableHeight)
            
            // Numéro de table
            Text("Table \(table.tableNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Occupancy
            Text("\(table.guests.count)/\(table.capacity)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .rotationEffect(.degrees(table.position.rotation))
    }
    
    @ViewBuilder
    private var tableShape: some Shape {
        switch table.shape {
        case .round:
            Circle()
        case .rectangular:
            Rectangle()
        case .square:
            Rectangle()
        case .oval:
            Ellipse()
        }
    }
    
    private var tableWidth: CGFloat {
        switch table.shape {
        case .round: return 60
        case .rectangular: return 80
        case .square: return 60
        case .oval: return 70
        }
    }
    
    private var tableHeight: CGFloat {
        switch table.shape {
        case .round: return 60
        case .rectangular: return 40
        case .square: return 60
        case .oval: return 50
        }
    }
}

struct AddTableView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var tableNumber = 1
    @State private var capacity = 8
    @State private var shape = TableShape.round
    @State private var notes = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        tableNumber > 0 && capacity > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Configuration de la table") {
                    Stepper("Numéro: \(tableNumber)", value: $tableNumber, in: 1...50)
                    
                    Stepper("Capacité: \(capacity) personnes", value: $capacity, in: 2...20)
                    
                    Picker("Forme", selection: $shape) {
                        ForEach(TableShape.allCases, id: \.self) { shape in
                            Text(shape.displayName).tag(shape)
                        }
                    }
                }
                
                Section("Notes (optionnel)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Text("La table sera placée au centre du plan. Vous pourrez la déplacer après création.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nouvelle table")
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
                        addTable()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addTable() {
        isLoading = true
        
        let newTable = WeddingTable(
            tableNumber: tableNumber,
            capacity: capacity,
            shape: shape,
            position: TablePosition(x: 300, y: 300), // Centre par défaut
            guests: [],
            notes: notes.isEmpty ? nil : notes
        )
        
        // TODO: Implémenter l'ajout de table via AppDataManager
        // Pour l'instant, on simule juste
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            dismiss()
        }
    }
}

struct TableDetailView: View {
    let table: WeddingTable
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    var assignedGuests: [Guest] {
        appData.guests.filter { guest in
            table.guests.contains(guest.id)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Informations de la table") {
                    HStack {
                        Text("Numéro")
                        Spacer()
                        Text("\(table.tableNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Forme")
                        Spacer()
                        Text(table.shape.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Capacité")
                        Spacer()
                        Text("\(table.capacity) personnes")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Occupé")
                        Spacer()
                        Text("\(table.guests.count)/\(table.capacity)")
                            .foregroundColor(table.isComplete ? .green : .orange)
                    }
                }
                
                Section("Invités assignés (\(assignedGuests.count))") {
                    if assignedGuests.isEmpty {
                        Text("Aucun invité assigné")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(assignedGuests) { guest in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(guest.fullName)
                                        .font(.headline)
                                    
                                    if guest.guestCount > 1 {
                                        Text("\(guest.guestCount) personnes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                if let notes = table.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Table \(table.tableNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Modifier") {
                        // TODO: Implémenter l'édition de table
                    }
                }
            }
        }
    }
}

struct HallDesignerView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingAddItem = false
    @State private var selectedItem: HallItem?
    
    var hallLayout: HallLayout {
        appData.hallLayout ?? HallLayout(
            items: [],
            hallDimensions: HallDimensions(width: 20, height: 15),
            updatedAt: Date()
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Informations sur la salle
                HallInfoView(hallLayout: hallLayout)
                    .padding()
                
                // Vue du plan de salle
                ScrollView([.horizontal, .vertical]) {
                    HallPlanView(
                        hallLayout: hallLayout,
                        onItemTapped: { item in
                            selectedItem = item
                        }
                    )
                }
                .background(Color(.systemGray6))
            }
            .navigationTitle("Plan de salle")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddItem) {
            AddHallItemView()
        }
        .sheet(item: $selectedItem) { item in
            HallItemDetailView(item: item)
        }
    }
}

struct HallInfoView: View {
    let hallLayout: HallLayout
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                title: "Dimensions",
                value: "\(Int(hallLayout.hallDimensions.width))x\(Int(hallLayout.hallDimensions.height))",
                color: .blue,
                subtitle: "mètres"
            )
            
            StatBadge(
                title: "Éléments",
                value: "\(hallLayout.items.count)",
                color: .green,
                subtitle: nil
            )
            
            let tables = hallLayout.items.filter { $0.type == .table }.count
            StatBadge(
                title: "Tables",
                value: "\(tables)",
                color: .orange,
                subtitle: nil
            )
        }
    }
}

struct HallPlanView: View {
    let hallLayout: HallLayout
    let onItemTapped: (HallItem) -> Void
    
    var body: some View {
        ZStack {
            // Contour de la salle
            Rectangle()
                .stroke(Color.primary, lineWidth: 3)
                .frame(
                    width: hallLayout.hallDimensions.width * 20,
                    height: hallLayout.hallDimensions.height * 20
                )
            
            // Éléments de la salle
            ForEach(hallLayout.items) { item in
                HallItemView(item: item)
                    .position(
                        x: item.position.x * 20,
                        y: item.position.y * 20
                    )
                    .onTapGesture {
                        onItemTapped(item)
                    }
            }
        }
        .frame(
            width: hallLayout.hallDimensions.width * 20 + 40,
            height: hallLayout.hallDimensions.height * 20 + 40
        )
    }
}

struct HallItemView: View {
    let item: HallItem
    
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Color(item.color ?? item.type.defaultColor).opacity(0.7))
                .frame(
                    width: item.size.width * 20,
                    height: item.size.height * 20
                )
                .overlay(
                    Image(systemName: item.type.icon)
                        .foregroundColor(.white)
                        .font(.caption)
                )
            
            if let label = item.label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .rotationEffect(.degrees(item.rotation))
    }
}

extension HallItemType {
    var icon: String {
        switch self {
        case .table: return "table.furniture"
        case .stage: return "theatermasks"
        case .bar: return "wineglass"
        case .danceFloor: return "music.note"
        case .entrance: return "door.left.hand.open"
        case .photoArea: return "camera"
        case .buffet: return "fork.knife"
        case .decoration: return "leaf"
        case .speaker: return "speaker.wave.2"
        case .other: return "questionmark"
        }
    }
}

struct AddHallItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var itemType = HallItemType.table
    @State private var label = ""
    @State private var width: Double = 2
    @State private var height: Double = 1
    @State private var color = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Type d'élément") {
                    Picker("Type", selection: $itemType) {
                        ForEach(HallItemType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Libellé (optionnel)", text: $label)
                }
                
                Section("Dimensions (en mètres)") {
                    HStack {
                        Text("Largeur")
                        Spacer()
                        TextField("2", value: $width, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("m")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Hauteur")
                        Spacer()
                        TextField("1", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("m")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("L'élément sera placé au centre de la salle. Vous pourrez le déplacer après création.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nouvel élément")
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
                        addHallItem()
                    }
                    .disabled(width <= 0 || height <= 0 || isLoading)
                }
            }
        }
    }
    
    private func addHallItem() {
        isLoading = true
        
        // TODO: Implémenter l'ajout d'élément via AppDataManager
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            dismiss()
        }
    }
}

struct HallItemDetailView: View {
    let item: HallItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Informations") {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(item.type.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    if let label = item.label, !label.isEmpty {
                        HStack {
                            Text("Libellé")
                            Spacer()
                            Text(label)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Dimensions")
                        Spacer()
                        Text("\(String(format: "%.1f", item.size.width))m x \(String(format: "%.1f", item.size.height))m")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Position")
                        Spacer()
                        Text("(\(String(format: "%.1f", item.position.x)), \(String(format: "%.1f", item.position.y)))")
                            .foregroundColor(.secondary)
                    }
                    
                    if item.rotation != 0 {
                        HStack {
                            Text("Rotation")
                            Spacer()
                            Text("\(Int(item.rotation))°")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(item.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Modifier") {
                        // TODO: Implémenter l'édition d'élément
                    }
                }
            }
        }
    }
}

struct InboxView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var selectedFilter = MessageFilter.all
    
    var filteredMessages: [Message] {
        appData.messages.filter { message in
            switch selectedFilter {
            case .all: return true
            case .unread: return !message.isRead
            case .rsvp: return message.type == .rsvp
            case .questions: return message.type == .question
            }
        }.sorted { $0.receivedDate > $1.receivedDate }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMessages) { message in
                    MessageRowView(message: message)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filtre", selection: $selectedFilter) {
                            ForEach(MessageFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.from)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(message.receivedDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !message.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            if let subject = message.subject, !subject.isEmpty {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(message.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

enum MessageFilter: CaseIterable {
    case all, unread, rsvp, questions
    
    var displayName: String {
        switch self {
        case .all: return "Tous"
        case .unread: return "Non lus"
        case .rsvp: return "RSVP"
        case .questions: return "Questions"
        }
    }
}

struct ExportsView: View {
    @EnvironmentObject private var appData: AppDataManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Exports disponibles") {
                    ExportRowView(
                        title: "Liste des invités",
                        description: "Export PDF ou CSV de tous les invités",
                        icon: "person.2.fill",
                        color: .blue
                    ) {
                        // TODO: Implémenter l'export des invités
                    }
                    
                    ExportRowView(
                        title: "Budget détaillé",
                        description: "Export Excel du budget complet",
                        icon: "creditcard.fill",
                        color: .green
                    ) {
                        // TODO: Implémenter l'export du budget
                    }
                    
                    ExportRowView(
                        title: "Liste des cadeaux",
                        description: "Export PDF des cadeaux reçus",
                        icon: "gift.fill",
                        color: .purple
                    ) {
                        // TODO: Implémenter l'export des cadeaux
                    }
                    
                    ExportRowView(
                        title: "Plan de table",
                        description: "Export PDF du plan de table",
                        icon: "table.furniture.fill",
                        color: .orange
                    ) {
                        // TODO: Implémenter l'export du plan de table
                    }
                }
                
                Section("Formats") {
                    Text("• PDF - Format idéal pour l'impression")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Excel - Format modifiable pour les calculs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• CSV - Format compatible avec tous les logiciels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Exports")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ExportRowView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GiftsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}