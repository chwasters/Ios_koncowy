//
//  CarDetailView.swift
//  bartek
//
//  Created by Jakub Nowosad on 06/06/2025.
//

import SwiftUI
import CoreData

struct CarDetailView: View {
    let car: Car
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingReservationForm = false
    @State private var isImageEnlarged = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Zdjęcie samochodu z gestem tap-to-zoom
                VStack {
                    Image(systemName: car.imageName ?? "car.fill")
                        .font(.system(size: isImageEnlarged ? 200 : 120))
                        .foregroundColor(.blue)
                        .scaleEffect(isImageEnlarged ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isImageEnlarged)
                        .onTapGesture {
                            // Gest dotknięcia do powiększenia obrazu
                            withAnimation {
                                isImageEnlarged.toggle()
                            }
                        }
                        .onLongPressGesture {
                            // Gest długiego naciśnięcia
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isImageEnlarged = false
                            }
                        }
                    
                    Text("Dotknij aby powiększyć")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Informacje o samochodzie
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(car.brand ?? "") \(car.model ?? "")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        StatusBadge(isAvailable: car.isAvailable)
                        Spacer()
                        Text("\(car.pricePerDay, specifier: "%.0f") zł/dzień")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                    
                    // Szczegóły techniczne
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(icon: "calendar", title: "Rok produkcji", value: "\(car.year)")
                        DetailRow(icon: "fuelpump", title: "Typ paliwa", value: car.fuelType ?? "")
                        DetailRow(icon: "person.2", title: "Liczba miejsc", value: "\(car.seatsCount)")
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Przycisk rezerwacji
                if car.isAvailable {
                    Button(action: {
                        showingReservationForm = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Zarezerwuj samochód")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Samochód niedostępny")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                // Lista rezerwacji dla tego samochodu
                if let reservations = car.reservations?.allObjects as? [Reservation], !reservations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aktualne rezerwacje")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(reservations.sorted(by: { $0.startDate ?? Date() < $1.startDate ?? Date() }), id: \.objectID) { reservation in
                            ReservationRowView(reservation: reservation)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Szczegóły")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReservationForm) {
            ReservationFormView(car: car)
        }
    }
}

struct StatusBadge: View {
    let isAvailable: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isAvailable ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isAvailable ? "Dostępny" : "Niedostępny")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isAvailable ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ReservationRowView: View {
    let reservation: Reservation
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reservation.customerName ?? "")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("\(reservation.startDate ?? Date(), formatter: dateFormatter) - \(reservation.endDate ?? Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(reservation.totalPrice, specifier: "%.0f") zł")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let car = Car(context: context)
    car.brand = "Toyota"
    car.model = "Camry"
    car.year = 2023
    car.pricePerDay = 150.0
    car.fuelType = "Benzyna"
    car.seatsCount = 5
    car.isAvailable = true
    car.imageName = "car.fill"
    
    return NavigationView {
        CarDetailView(car: car)
    }
    .environment(\.managedObjectContext, context)
}
