//
//  Persistence.swift
//  bartek
//
//  Created by Jakub Nowosad on 05/06/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Tylko 3 przykładowe samochody dla prezentacji
        let cars = [
            ("Toyota", "Camry", 2023, 150.0, "Benzyna", 5),
            ("BMW", "X5", 2022, 300.0, "Diesel", 7),
            ("Audi", "A4", 2023, 200.0, "Benzyna", 5)
        ]
        
        for (brand, model, year, price, fuel, seats) in cars {
            let newCar = Car(context: viewContext)
            newCar.brand = brand
            newCar.model = model
            newCar.year = Int16(year)
            newCar.pricePerDay = price
            newCar.fuelType = fuel
            newCar.seatsCount = Int16(seats)
            newCar.isAvailable = brand != "Audi" // Audi będzie niedostępne dla demonstracji filtrowania
            newCar.imageName = "car.fill"
        }
        
        // Jedna przykładowa rezerwacja
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        if let cars_result = try? viewContext.fetch(fetchRequest), !cars_result.isEmpty {
            let reservation = Reservation(context: viewContext)
            reservation.customerName = "Jan Kowalski"
            reservation.customerEmail = "jan.kowalski@test.pl"
            reservation.customerPhone = "+48 123 456 789"
            reservation.startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            reservation.endDate = Calendar.current.date(byAdding: .day, value: 4, to: Date())
            reservation.totalPrice = 450.0
            reservation.createdAt = Date()
            reservation.car = cars_result[0]
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "bartek")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
