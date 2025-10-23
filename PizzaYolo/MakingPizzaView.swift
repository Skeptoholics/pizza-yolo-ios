import SwiftUI

struct DoughPreset: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let hydration: Double
    let salt: Double
    let yeast: Double
}

let PRESETS: [DoughPreset] = [
    .init(name: "Neapolitan", hydration: 60, salt: 2.8, yeast: 0.05),
    .init(name: "New York",   hydration: 63, salt: 2.5, yeast: 0.30),
    .init(name: "Detroit",    hydration: 70, salt: 2.5, yeast: 0.50)
]

struct MakingPizzaView: View {
    @State private var doughBalls: Int = 4
    @State private var ballWeightGrams: Double = 260
    @State private var hydrationPct: Double = 65
    @State private var saltPct: Double = 2.5
    @State private var yeastPct: Double = 0.2

    @State private var selectedPreset: DoughPreset? = PRESETS.first
    @State private var unit: WeightUnit = .grams

    // Timeline (user adjustable)
    @State private var bulkHours: Double = 2
    @State private var ballHours: Double = 24
    @State private var startTime: Date = Date()

    // Save / load
    @StateObject private var store = RecipeStore()
    @State private var newRecipeName: String = ""

    // Derived weights
    private var totalDoughG: Double { Double(doughBalls) * ballWeightGrams }
    private var flourG: Double {
        let h = hydrationPct / 100, s = saltPct / 100, y = yeastPct / 100
        return totalDoughG / (1 + h + s + y)
    }
    private var waterG: Double { flourG * (hydrationPct / 100) }
    private var saltG:  Double { flourG * (saltPct / 100) }
    private var yeastG: Double { flourG * (yeastPct / 100) }

    // Helpers
    private func fmt(_ grams: Double) -> String { unit.format(grams: grams) }
    private var flourCups: String { WeightUnit.flourCups(fromFlourGrams: flourG) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Presets & Units
                    GroupBox("Quick setup") {
                        HStack {
                            Picker("Preset", selection: Binding(
                                get: { selectedPreset ?? PRESETS.first! },
                                set: { p in
                                    selectedPreset = p
                                    hydrationPct = p.hydration
                                    saltPct = p.salt
                                    yeastPct = p.yeast
                                })) {
                                ForEach(PRESETS) { p in Text(p.name).tag(p) }
                            }
                            .pickerStyle(.menu)

                            Spacer()

                            Picker("Units", selection: $unit) {
                                ForEach(WeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    // Batch
                    GroupBox("Batch") {
                        VStack(alignment: .leading, spacing: 12) {
                            Stepper("Dough balls: \(doughBalls)", value: $doughBalls, in: 1...200)
                            HStack {
                                Text("Ball weight")
                                Spacer()
                                TextField("grams", value: $ballWeightGrams, format: .number)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                Text("g")
                            }
                        }
                    }

                    // Formula
                    GroupBox("Formula") {
                        VStack(spacing: 10) {
                            sliderRow(title: "Hydration %", value: $hydrationPct, range: 50...80, step: 0.5, format: "%.1f")
                            sliderRow(title: "Salt %", value: $saltPct, range: 1.5...3.5, step: 0.1, format: "%.1f")
                            sliderRow(title: "Yeast %", value: $yeastPct, range: 0.05...1.0, step: 0.05, format: "%.2f")
                        }
                    }

                    // Totals
                    GroupBox("Totals") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledValue(label: "Total dough", value: fmt(totalDoughG))
                            LabeledValue(label: "Flour", value: fmt(flourG) + " (\(flourCups))")
                            LabeledValue(label: "Water", value: fmt(waterG))
                            LabeledValue(label: "Salt",  value: fmt(saltG))
                            LabeledValue(label: "Yeast", value: fmt(yeastG))
                        }
                    }

                    // Timeline
                    GroupBox("Dough timeline") {
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker("Start", selection: $startTime, displayedComponents: [.hourAndMinute, .date])
                            HStack {
                                Stepper("Bulk: \(Int(bulkHours)) h", value: $bulkHours, in: 0...12, step: 0.5)
                                Stepper("Ball/Proof: \(Int(ballHours)) h", value: $ballHours, in: 0...72, step: 1)
                            }
                            let bulkEnd = Calendar.current.date(byAdding: .minute, value: Int(bulkHours * 60), to: startTime) ?? startTime
                            let ballEnd = Calendar.current.date(byAdding: .minute, value: Int(ballHours * 60), to: bulkEnd) ?? bulkEnd
                            Text("⏱️ Bulk ends: \(bulkEnd.formatted(date: .omitted, time: .shortened))")
                            Text("⏱️ Ball/Proof ends (bake): \(ballEnd.formatted(date: .omitted, time: .shortened))")
                        }
                    }

                    // Save / Load
                    GroupBox("Save & load recipes") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Recipe name", text: $newRecipeName)
                                Button("Save") {
                                    guard !newRecipeName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    let r = Recipe(name: newRecipeName,
                                                   doughBalls: doughBalls,
                                                   ballWeightGrams: ballWeightGrams,
                                                   hydrationPct: hydrationPct,
                                                   saltPct: saltPct,
                                                   yeastPct: yeastPct)
                                    store.add(r)
                                    newRecipeName = ""
                                }
                            }
                            if store.recipes.isEmpty {
                                Text("No saved recipes yet.").foregroundStyle(.secondary)
                            } else {
                                ForEach(store.recipes) { r in
                                    HStack {
                                        Button(r.name) {
                                            doughBalls = r.doughBalls
                                            ballWeightGrams = r.ballWeightGrams
                                            hydrationPct = r.hydrationPct
                                            saltPct = r.saltPct
                                            yeastPct = r.yeastPct
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            if let i = store.recipes.firstIndex(of: r) {
                                                store.recipes.remove(at: i); store.save()
                                            }
                                        } label: { Image(systemName: "trash") }
                                    }
                                }
                            }
                        }
                    }

                    // Export
                    Button {
                        Task {
                            let v = ShoppingListView(
                                title: "PizzaYolo Shopping List",
                                flour: fmt(flourG),
                                water: fmt(waterG),
                                salt: fmt(saltG),
                                yeast: fmt(yeastG),
                                doughBalls: doughBalls,
                                ballWeight: WeightUnit.grams.format(grams: ballWeightGrams),
                                flourCups: flourCups
                            )
                            if let url = try? await exportShoppingListPDF(view: v, suggestedName: "PizzaYolo-Shopping-List") {
                                #if os(macOS)
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                                #endif
                            }
                        }
                    } label: {
                        Label("Export Shopping List (PDF to Desktop)", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Pizza Calculator")
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Slider(value: value, in: range, step: step)
            Text(String(format: format + "%%", value.wrappedValue))
                .frame(width: 68, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

#Preview { MakingPizzaView() }
