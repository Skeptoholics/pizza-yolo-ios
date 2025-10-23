import SwiftUI

struct CateringPizzaView: View {
    @State private var guests: Int = 12
    @State private var slicesPerPerson: Double = 3
    @State private var slicesPerPie: Int = 8

    // link with Making defaults
    @State private var ballWeightGrams: Double = 260
    @State private var hydrationPct: Double = 65
    @State private var saltPct: Double = 2.5
    @State private var yeastPct: Double = 0.2

    @State private var unit: WeightUnit = .grams

    private var requiredSlices: Int { Int(ceil(Double(guests) * slicesPerPerson)) }
    private var piesNeeded: Int { Int(ceil(Double(requiredSlices) / Double(slicesPerPie))) }
    private var doughBalls: Int { piesNeeded }

    private var totalDoughG: Double { Double(doughBalls) * ballWeightGrams }
    private var flourG: Double {
        let h = hydrationPct / 100, s = saltPct / 100, y = yeastPct / 100
        return totalDoughG / (1 + h + s + y)
    }
    private var waterG: Double { flourG * (hydrationPct / 100) }
    private var saltG:  Double { flourG * (saltPct / 100) }
    private var yeastG: Double { flourG * (yeastPct / 100) }

    private func fmt(_ g: Double) -> String { unit.format(grams: g) }
    private var flourCups: String { WeightUnit.flourCups(fromFlourGrams: flourG) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    Stepper("Guests: \(guests)", value: $guests, in: 1...500)
                    HStack {
                        Text("Slices per person")
                        Spacer()
                        Stepper("", value: $slicesPerPerson, in: 1...6, step: 0.5).labelsHidden()
                        Text(String(format: "%.1f", slicesPerPerson))
                            .frame(width: 60, alignment: .trailing)
                            .monospacedDigit()
                    }
                    Stepper("Slices per pie: \(slicesPerPie)", value: $slicesPerPie, in: 4...12)
                }

                Section("Units") {
                    Picker("Units", selection: $unit) {
                        ForEach(WeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                }

                Section("Results") {
                    LabeledValue(label: "Required slices", value: "\(requiredSlices)")
                    LabeledValue(label: "Pizzas needed",   value: "\(piesNeeded)")
                    LabeledValue(label: "Dough balls",     value: "\(doughBalls)")
                }

                Section("Dough") {
                    LabeledValue(label: "Ball weight", value: WeightUnit.grams.format(grams: ballWeightGrams))
                    LabeledValue(label: "Total dough", value: fmt(totalDoughG))
                    LabeledValue(label: "Flour",       value: fmt(flourG) + " (\(flourCups))")
                    LabeledValue(label: "Water",       value: fmt(waterG))
                    LabeledValue(label: "Salt",        value: fmt(saltG))
                    LabeledValue(label: "Yeast",       value: fmt(yeastG))
                }
            }
            .navigationTitle("Catering")
        }
    }
}

#Preview { CateringPizzaView() }
