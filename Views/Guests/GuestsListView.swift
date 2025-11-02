import SwiftUI

struct GuestsListView: View {
    @EnvironmentObject private var appData: AppDataManager
    @State private var searchText = ""
    @State private var selectedFilter = GuestFilter.all
    @State private var showingAddGuest = false
    @State private var showingGuestDetail = false
    @State private var selectedGuest: Guest?
    
    var filteredGuests: [Guest] {
        let filtered = appData.guests.filter { guest in
            // Filtre par texte de recherche
            if !searchText.isEmpty {
                let matchesName = guest.fullName.localizedCaseInsensitiveContains(searchText)
                let matchesPhone = guest.phone?.localizedCaseInsensitiveContains(searchText) ?? false
                return matchesName || matchesPhone
            }
            return true
        }.filter { guest in
            // Filtre par statut
            switch selectedFilter {
            case .all:
                return true
            case .confirmed:
                return guest.attendance == .oui
            case .declined:
                return guest.attendance == .non
            case .pending:
                return guest.attendance == .peutEtre
            }
        }
        
        return filtered.sorted { $0.fullName < $1.fullName }
    }
    
    var guestStats: GuestStats {
        let total = appData.guests.count
        let confirmed = appData.guests.filter { $0.attendance == .oui }.count
        let declined = appData.guests.filter { $0.attendance == .non }.count
        let pending = appData.guests.filter { $0.attendance == .peutEtre }.count
        let totalGuestCount = appData.guests.reduce(0) { $0 + $1.guestCount }
        
        return GuestStats(
            total: total,
            confirmed: confirmed,
            declined: declined,
            pending: pending,
            totalGuestCount: totalGuestCount
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistiques en haut
                GuestStatsView(stats: guestStats)
                    .padding()
                
                // Liste des invités
                List {
                    ForEach(filteredGuests) { guest in
                        GuestListRowView(guest: guest)
                            .onTapGesture {
                                selectedGuest = guest
                                showingGuestDetail = true
                            }
                    }
                    .onDelete(perform: deleteGuests)
                }
                .searchable(text: $searchText, prompt: "Rechercher un invité...")
                .refreshable {
                    appData.refreshData()
                }
            }
            .navigationTitle("Invités")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filtre", selection: $selectedFilter) {
                            ForEach(GuestFilter.allCases, id: \.self) { filter in
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
                        showingAddGuest = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddGuest) {
            AddGuestView()
        }
        .sheet(isPresented: $showingGuestDetail) {
            if let selectedGuest = selectedGuest {
                GuestDetailView(guest: selectedGuest)
            }
        }
    }
    
    private func deleteGuests(offsets: IndexSet) {
        // TODO: Implémenter la suppression des invités
        // Pour l'instant, on ne fait rien car il faut implémenter l'API de suppression
    }
}

struct GuestStatsView: View {
    let stats: GuestStats
    
    var body: some View {
        HStack(spacing: 20) {
            StatBadge(
                title: "Total",
                value: "\(stats.total)",
                color: .blue,
                subtitle: "\(stats.totalGuestCount) pers."
            )
            
            StatBadge(
                title: "Confirmés",
                value: "\(stats.confirmed)",
                color: .green,
                subtitle: nil
            )
            
            StatBadge(
                title: "Déclinés",
                value: "\(stats.declined)",
                color: .red,
                subtitle: nil
            )
            
            StatBadge(
                title: "En attente",
                value: "\(stats.pending)",
                color: .orange,
                subtitle: nil
            )
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct GuestListRowView: View {
    let guest: Guest
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(guest.attendance.color).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(guest.attendance.color))
                        .font(.title3)
                )
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    // Statut
                    Text(guest.attendance.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(guest.attendance.color).opacity(0.2))
                        .foregroundColor(Color(guest.attendance.color))
                        .clipShape(Capsule())
                    
                    // Nombre de personnes
                    if guest.guestCount > 1 {
                        Text("\(guest.guestCount) personnes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Téléphone
                if let phone = guest.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddGuestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var fullName = ""
    @State private var phone = ""
    @State private var attendance = AttendanceStatus.peutEtre
    @State private var guestCount = 1
    @State private var message = ""
    @State private var group = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && guestCount >= 1
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations principales") {
                    TextField("Nom complet", text: $fullName)
                        .autocapitalization(.words)
                    
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    Picker("Présence", selection: $attendance) {
                        ForEach(AttendanceStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    Stepper("Nombre de personnes: \(guestCount)", value: $guestCount, in: 1...10)
                }
                
                Section("Informations supplémentaires") {
                    TextField("Groupe (optionnel)", text: $group)
                        .autocapitalization(.words)
                    
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nouvel invité")
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
                        addGuest()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func addGuest() {
        isLoading = true
        
        let newGuest = Guest(
            id: 0, // Sera assigné par le serveur
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone,
            attendance: attendance,
            guestCount: guestCount,
            message: message.isEmpty ? nil : message,
            createdAt: Date(),
            group: group.isEmpty ? nil : group
        )
        
        Task {
            await appData.addGuest(newGuest)
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if appData.errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

struct GuestDetailView: View {
    let guest: Guest
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // En-tête avec avatar
                    HStack {
                        Circle()
                            .fill(Color(guest.attendance.color).opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color(guest.attendance.color))
                                    .font(.largeTitle)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(guest.fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(guest.attendance.displayName)
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(guest.attendance.color).opacity(0.2))
                                .foregroundColor(Color(guest.attendance.color))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Informations détaillées
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(
                            title: "Nombre de personnes",
                            value: "\(guest.guestCount)",
                            icon: "person.2.fill"
                        )
                        
                        if let phone = guest.phone, !phone.isEmpty {
                            DetailRow(
                                title: "Téléphone",
                                value: phone,
                                icon: "phone.fill"
                            )
                        }
                        
                        if let group = guest.group, !group.isEmpty {
                            DetailRow(
                                title: "Groupe",
                                value: group,
                                icon: "person.3.fill"
                            )
                        }
                        
                        DetailRow(
                            title: "Ajouté le",
                            value: guest.createdAt.formatted(date: .abbreviated, time: .shortened),
                            icon: "calendar"
                        )
                        
                        if let message = guest.message, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(.blue)
                                    Text("Message")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text(message)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Détails invité")
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
            EditGuestView(guest: guest)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct EditGuestView: View {
    let guest: Guest
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appData: AppDataManager
    
    @State private var fullName: String
    @State private var phone: String
    @State private var attendance: AttendanceStatus
    @State private var guestCount: Int
    @State private var message: String
    @State private var group: String
    @State private var isLoading = false
    
    init(guest: Guest) {
        self.guest = guest
        self._fullName = State(initialValue: guest.fullName)
        self._phone = State(initialValue: guest.phone ?? "")
        self._attendance = State(initialValue: guest.attendance)
        self._guestCount = State(initialValue: guest.guestCount)
        self._message = State(initialValue: guest.message ?? "")
        self._group = State(initialValue: guest.group ?? "")
    }
    
    var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && guestCount >= 1
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations principales") {
                    TextField("Nom complet", text: $fullName)
                        .autocapitalization(.words)
                    
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    Picker("Présence", selection: $attendance) {
                        ForEach(AttendanceStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    Stepper("Nombre de personnes: \(guestCount)", value: $guestCount, in: 1...10)
                }
                
                Section("Informations supplémentaires") {
                    TextField("Groupe (optionnel)", text: $group)
                        .autocapitalization(.words)
                    
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Modifier invité")
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
                        updateGuest()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func updateGuest() {
        isLoading = true
        
        let updatedGuest = Guest(
            id: guest.id,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone,
            attendance: attendance,
            guestCount: guestCount,
            message: message.isEmpty ? nil : message,
            createdAt: guest.createdAt,
            group: group.isEmpty ? nil : group
        )
        
        Task {
            await appData.updateGuest(updatedGuest)
            
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
enum GuestFilter: CaseIterable {
    case all, confirmed, declined, pending
    
    var displayName: String {
        switch self {
        case .all: return "Tous"
        case .confirmed: return "Confirmés"
        case .declined: return "Déclinés"
        case .pending: return "En attente"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "person.2"
        case .confirmed: return "checkmark.circle"
        case .declined: return "xmark.circle"
        case .pending: return "clock.circle"
        }
    }
}

struct GuestStats {
    let total: Int
    let confirmed: Int
    let declined: Int
    let pending: Int
    let totalGuestCount: Int
}

#Preview {
    GuestsListView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppDataManager())
}