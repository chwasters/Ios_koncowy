//
//  ReservationListView.swift
//  bartek
//
//  Created by Jakub Nowosad on 06/06/2025.
//

import SwiftUI
import CoreData

struct ReservationListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reservation.startDate, ascending: true)],
        animation: .default)
    private var reservations: FetchedResults<Reservation>
    
    @State private var searchText = ""
    @State private var selectedSortOption = "Data rozpoczęcia"
    @State private var showingDeleteAlert = false
    @State private var reservationToDelete: Reservation?
    
    let sortOptions = ["Data rozpoczęcia", "Data utworzenia", "Nazwa klienta", "Cena"]
    
    var filteredReservations: [Reservation] {
        var filtered = Array(reservations)
        
        // Filtrowanie po tekście wyszukiwania
        if !searchText.isEmpty {
            filtered = filtered.filter { reservation in
                (reservation.customerName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (reservation.customerEmail?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (reservation.car?.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (reservation.car?.model?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sortowanie
        switch selectedSortOption {
        case "Data utworzenia":
            filtered.sort { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        case "Nazwa klienta":
            filtered.sort { ($0.customerName ?? "") < ($1.customerName ?? "") }
        case "Cena":
            filtered.sort { $0.totalPrice > $1.totalPrice }
        default: // Data rozpoczęcia
            filtered.sort { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
        }
        
        return filtered
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Kontrolka wyszukiwania
                SearchBar(text: $searchText)
                
                // Kontrolka sortowania
                HStack {
                    Text("Sortuj:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Sortowanie", selection: $selectedSortOption) {
                        ForEach(sortOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                if filteredReservations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "Brak rezerwacji" : "Brak wyników wyszukiwania")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Button("Wyczyść wyszukiwanie") {
                                searchText = ""
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredReservations, id: \.objectID) { reservation in
                            ReservationDetailRow(reservation: reservation)
                                .swipeActions(edge: .trailing) {
                                    Button("Usuń", role: .destructive) {
                                        reservationToDelete = reservation
                                        showingDeleteAlert = true
                                    }
                                }
                                .contextMenu {
                                    // Gest context menu
                                    Button("Usuń rezerwację", role: .destructive) {
                                        reservationToDelete = reservation
                                        showingDeleteAlert = true
                                    }
                                    
                                    Button("Informacje o kliencie") {
                                        // Dodatkowa akcja
                                    }
                                }
                        }
                    }
                    .refreshable {
                        // Gest pull-to-refresh
                        try? viewContext.save()
                    }
                }
            }
            .navigationTitle("Rezerwacje (\(filteredReservations.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                }
            }
            .alert("Usuń rezerwację", isPresented: $showingDeleteAlert) {
                Button("Usuń", role: .destructive) {
                    if let reservation = reservationToDelete {
                        deleteReservation(reservation)
                    }
                }
                Button("Anuluj", role: .cancel) {
                    reservationToDelete = nil
                }
            } message: {
                Text("Czy na pewno chcesz usunąć tę rezerwację? Ta akcja nie może zostać cofnięta.")
            }
        }
    }
    
    private func deleteReservation(_ reservation: Reservation) {
        withAnimation {
            viewContext.delete(reservation)
            
            do {
                try viewContext.save()
            } catch {
                // Handle error
                print("Błąd podczas usuwania rezerwacji: \(error)")
            }
        }
        reservationToDelete = nil
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Szukaj rezerwacji...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ReservationDetailRow: View {
    let reservation: Reservation
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private var isCurrentReservation: Bool {
        let now = Date()
        let start = reservation.startDate ?? Date()
        let end = reservation.endDate ?? Date()
        return start <= now && now <= end
    }
    
    private var isUpcomingReservation: Bool {
        let now = Date()
        let start = reservation.startDate ?? Date()
        return start > now
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.customerName ?? "Nieznany klient")
                        .font(.headline)
                    
                    Text(reservation.customerEmail ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isCurrentReservation {
                        Text("AKTYWNA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    } else if isUpcomingReservation {
                        Text("PRZYSZŁA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    } else {
                        Text("ZAKOŃCZONA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .cornerRadius(4)
                    }
                    
                    Text("\(reservation.totalPrice, specifier: "%.0f") zł")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: reservation.car?.imageName ?? "car.fill")
                    .foregroundColor(.blue)
                
                Text("\(reservation.car?.brand ?? "") \(reservation.car?.model ?? "")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Tel: \(reservation.customerPhone ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                
                Text("\(reservation.startDate ?? Date(), formatter: dateFormatter) - \(reservation.endDate ?? Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let days = Calendar.current.dateComponents([.day], from: reservation.startDate ?? Date(), to: reservation.endDate ?? Date()).day ?? 0
                Text("\(days) dni")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReservationListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
