import SwiftUI

struct CateringPizzaView: View {
    @State private var appetite = "Normal Eaters"
    @State private var size = "Medium (12\")"
    @State private var thickness = "Classic"

    let appetiteOptions = ["Small Eaters", "Normal Eaters", "Big Eaters"]
    let sizeOptions = ["Small (9\")", "Medium (12\")", "Large (16\")"]
    let thicknessOptions = ["Thin", "Classic", "Deep"]

    var appetiteSlicesPerPerson: Double {
        switch appetite {
        case "Small Eaters": return 1.5
        case "Big Eaters": return 3.5
        default: return 2.5
        }
    }

    var estimatedSlicesPerPizza: Int {
        switch (size, thickness) {
        case ("Small (9\")", "Thin"): return 6
        case ("Small (9\")", _): return 5
        case ("Medium (12\")", "Thin"): return 8
        case ("Medium (12\")", _): return 7
        case ("Large (16\")", "Thin"): return 10
        case ("Large (16\")", _): return 8
        default: return 8
        }
    }

    @State private var people: Double = 10
    var totalSlices: Double { Double(people) * appetiteSlicesPerPerson }
    var pizzasNeeded: Int { Int(ceil(totalSlices / Double(estimatedSlicesPerPizza))) }
    var totalEstimatedCost: Double { Double(pizzasNeeded) * 12.99 }

    var body: some View {
        Form {
            Section(header: Text("Guests")) {
                Stepper(value: $people, in: 1...500, step: 1) {
                    Text("Number of people: \(Int(people))")
                }

                Picker("Appetite", selection: $appetite) {
                    ForEach(appetiteOptions, id: \.self) { Text($0) }
                }
            }

            Picker("Pizza Size", selection: $size) {
                ForEach(sizeOptions, id: \.self) { Text($0) }
            }

            Picker("Crust Thickness", selection: $thickness) {
                ForEach(thicknessOptions, id: \.self) { Text($0) }
            }

            Section(header: Text("Summary")) {
                Text("Each person eats about \(appetiteSlicesPerPerson, specifier: "%.1f") slices")
                Text("Total slices needed: \(totalSlices, specifier: "%.1f")")
                Text("Slices per pizza: \(estimatedSlicesPerPizza)")
            }

            Section(header: Text("Result")) {
                Text("You need to order \(pizzasNeeded) pizzas")
                Text("Estimated cost: $\(totalEstimatedCost, specifier: "%.2f")")
            }
        }
        .navigationTitle("Catering Calculator")
    }
}
