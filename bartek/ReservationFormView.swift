//
//  ReservationFormView.swift
//  bartek
//
//  Created by Jakub Nowosad on 06/06/2025.
//

import SwiftUI
import CoreData

struct ReservationFormView: View {
    let car: Car
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var customerPhone = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isFormValid = false
    
    private var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    private var totalPrice: Double {
        Double(totalDays) * car.pricePerDay
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informacje o samochodzie")) {
                    HStack {
                        Image(systemName: car.imageName ?? "car.fill")
                            .foregroundColor(.blue)
                        Text("\(car.brand ?? "") \(car.model ?? "")")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(car.pricePerDay, specifier: "%.0f") zł/dzień")
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Dane klienta")) {
                    // TextField z walidacją
                    TextField("Imię i nazwisko", text: $customerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: customerName) { _ in validateForm() }
                    
                    TextField("Email", text: $customerEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: customerEmail) { _ in validateForm() }
                    
                    TextField("Telefon", text: $customerPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .onChange(of: customerPhone) { _ in validateForm() }
                }
                
                Section(header: Text("Okres wynajmu")) {
                    // DatePicker kontrolki
                    DatePicker("Data rozpoczęcia", selection: $startDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: startDate) { newValue in
                            if endDate <= newValue {
                                endDate = Calendar.current.date(byAdding: .day, value: 1, to: newValue) ?? newValue
                            }
                            validateForm()
                        }
                    
                    DatePicker("Data zakończenia", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .onChange(of: endDate) { _ in validateForm() }
                }
                
                Section(header: Text("Podsumowanie")) {
                    HStack {
                        Text("Liczba dni:")
                        Spacer()
                        Text("\(totalDays)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Koszt całkowity:")
                        Spacer()
                        Text("\(totalPrice, specifier: "%.0f") zł")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Section {
                    Button(action: saveReservation) {
                        Text("Zarezerwuj")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(isFormValid ? .white : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Nowa rezerwacja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
            .alert("Informacja", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("pomyślnie") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                validateForm()
            }
        }
    }
    
    private func validateForm() {
        let isNameValid = !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEmailValid = isValidEmail(customerEmail)
        let isPhoneValid = !customerPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let areDatesValid = startDate < endDate
        
        isFormValid = isNameValid && isEmailValid && isPhoneValid && areDatesValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
      private func saveReservation() {
        // Podstawowa walidacja
        guard !customerName.isEmpty, customerEmail.isValidEmail, !customerPhone.isEmpty else {
            alertMessage = "Wypełnij wszystkie pola poprawnie."
            showingAlert = true
            return
        }
        
        guard startDate < endDate else {
            alertMessage = "Data końcowa musi być późniejsza niż początkowa."
            showingAlert = true
            return
        }
        
        // Tworzenie rezerwacji
        withAnimation {
            let newReservation = Reservation(context: viewContext)
            newReservation.customerName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
            newReservation.customerEmail = customerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            newReservation.customerPhone = customerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            newReservation.startDate = startDate
            newReservation.endDate = endDate
            newReservation.totalPrice = totalPrice
            newReservation.createdAt = Date()
            newReservation.car = car
            
            do {
                try viewContext.save()
                alertMessage = "Rezerwacja została utworzona pomyślnie!"
                showingAlert = true
            } catch {
                alertMessage = "Wystąpił błąd podczas tworzenia rezerwacji."
                showingAlert = true
            }
        }
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
    
    return ReservationFormView(car: car)
        .environment(\.managedObjectContext, context)
}
