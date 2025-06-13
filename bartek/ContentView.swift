//
//  ContentView.swift
//  bartek
//
//  Created by Jakub Nowosad on 05/06/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Car.brand, ascending: true)],
        animation: .default)
    private var cars: FetchedResults<Car>
    
    @State private var showingReservations = false
    @State private var selectedFilter = "Wszystkie"
    
    let filterOptions = ["Wszystkie", "Dostępne", "Niedostępne"]
    
    var filteredCars: [Car] {
        switch selectedFilter {
        case "Dostępne":
            return cars.filter { $0.isAvailable }
        case "Niedostępne":
            return cars.filter { !$0.isAvailable }
        default:
            return Array(cars)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Kontrolka Picker do filtrowania
                Picker("Filtruj samochody", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List {
                    ForEach(filteredCars, id: \.objectID) { car in
                        NavigationLink(destination: CarDetailView(car: car)) {
                            CarRowView(car: car)
                        }
                    }
                    .onDelete(perform: deleteCars)
                }
                .refreshable {
                    // Gest pull-to-refresh
                    refreshData()
                }
            }
            .navigationTitle("Wynajem Samochodów")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Rezerwacje") {
                        showingReservations = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addSampleCar) {
                        Label("Dodaj samochód", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingReservations) {
                ReservationListView()
            }
            
            Text("Wybierz samochód aby zobaczyć szczegóły")
                .foregroundColor(.secondary)
        }
    }
    
    private func addSampleCar() {
        withAnimation {
            let newCar = Car(context: viewContext)
            newCar.brand = "Ford"
            newCar.model = "Focus"
            newCar.year = 2023
            newCar.pricePerDay = 120.0
            newCar.fuelType = "Benzyna"
            newCar.seatsCount = 5
            newCar.isAvailable = true
            newCar.imageName = "car.fill"
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteCars(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredCars[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func refreshData() {
        // Odświeżenie danych
        try? viewContext.save()
    }
}

// MARK: - Car Row Component (włączone w ContentView dla prostoty)
struct CarRowView: View {
    let car: Car
    
    var body: some View {
        HStack {
            Image(systemName: car.imageName ?? "car.fill")
                .foregroundColor(car.isAvailable ? CarRentalColors.primary : .gray)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(car.brand ?? "") \(car.model ?? "")")
                    .font(.headline)
                
                HStack {
                    Text("Rok: \(car.year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(car.fuelType ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(CarRentalColors.primary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack {
                    Text(car.pricePerDay.asCurrency() + "/dzień")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(car.isAvailable ? "Dostępny" : "Niedostępny")
                        .font(.caption)
                        .foregroundColor(car.isAvailable ? CarRentalColors.success : CarRentalColors.danger)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
