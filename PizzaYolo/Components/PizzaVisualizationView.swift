// Pizza Yolo – Visualization UI
// Drop this file into your Xcode project and set PizzaVisualizationView() as your start view to test.
// SwiftUI-only, no dependencies. iOS 16+.

import SwiftUI

// MARK: - Domain Models
struct DoughPlan: Identifiable, Hashable {
    enum Mode: String, CaseIterable, Identifiable { case make = "I’m making pizza", cater = "I’m catering with pizza"; var id: String { rawValue } }
    enum UnitStyle: String, CaseIterable, Identifiable { case grams, kgAndGrams, ounces, poundsAndOunces; var id: String { rawValue } }
    
    var id = UUID()
    var mode: Mode = .make
    var numberOfPizzas: Int
    var ballWeightGrams: Double
    var hydrationPct: Double      // e.g. 65 → 65%
    var saltPct: Double           // baker’s % of flour
    var yeastPct: Double          // baker’s % of flour
    var oilPct: Double            // baker’s % of flour (0 if none)
    var sugarPct: Double          // baker’s % of flour (0 if none)
    var flourDensityGPerCup: Double = 120 // tweak to your preference (e.g. 120–130g per cup)
    var unitStyle: UnitStyle = .grams
    
    // Derived quantities
    var totalDoughGrams: Double { Double(numberOfPizzas) * ballWeightGrams }
    var flourGrams: Double {
        // total = flour * (1 + h + s + y + o + su)
        let h = hydrationPct / 100
        let s = saltPct / 100
        let y = yeastPct / 100
        let o = oilPct / 100
        let su = sugarPct / 100
        return totalDoughGrams / (1 + h + s + y + o + su)
    }
    var waterGrams: Double { flourGrams * hydrationPct / 100 }
    var saltGrams: Double { flourGrams * saltPct / 100 }
    var yeastGrams: Double { flourGrams * yeastPct / 100 }
    var oilGrams: Double { flourGrams * oilPct / 100 }
    var sugarGrams: Double { flourGrams * sugarPct / 100 }
    
    var flourCups: Double { flourGrams / flourDensityGPerCup }
}

// MARK: - ViewModel
final class PizzaVizViewModel: ObservableObject {
    @Published var plan: DoughPlan
    @Published var showCupsBesideFlour = true
    
    init(plan: DoughPlan) { self.plan = plan }
}

// MARK: - Visualization View
struct PizzaVisualizationView: View {
    @StateObject private var vm = PizzaVizViewModel(plan: .init(
        mode: .make,
        numberOfPizzas: 6,
        ballWeightGrams: 260,
        hydrationPct: 65,
        saltPct: 2.5,
        yeastPct: 0.2,
        oilPct: 1.5,
        sugarPct: 0
    ))
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    modePicker
                    keyStats
                    hydrationGauge
                    ingredientsBars
                    fermentationTimeline
                    unitStylePicker
                }
                .padding(16)
            }
            .navigationTitle("Pizza Yolo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Sections
private extension PizzaVisualizationView {
    var modePicker: some View {
        Picker("Mode", selection: $vm.plan.mode) {
            ForEach(DoughPlan.Mode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var keyStats: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                StatCard(title: "Pizzas", value: "\(vm.plan.numberOfPizzas)", subtitle: "count", systemImage: "number")
                StatCard(title: "Ball", value: formatWeight(vm.plan.ballWeightGrams, style: vm.plan.unitStyle), subtitle: "per ball", systemImage: "circlebadge")
            }
            GridRow {
                StatCard(title: "Total Dough", value: formatWeight(vm.plan.totalDoughGrams, style: vm.plan.unitStyle), subtitle: "all balls", systemImage: "scalemass")
                StatCard(title: "Flour", value: flourDisplay(), subtitle: "baker’s base", systemImage: "leaf")
            }
        }
    }
    
    var hydrationGauge: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Label("Hydration", systemImage: "drop.fill"); Spacer(); Text("\(vm.plan.hydrationPct, specifier: "%.0f")%") }
                .font(.headline)
            Gauge(value: vm.plan.hydrationPct, in: 50...85) {
                Text("Hydration")
            } currentValueLabel: {
                Text("\(vm.plan.hydrationPct, specifier: "%.0f")%")
            } minimumValueLabel: { Text("50%") } maximumValueLabel: { Text("85%") }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(Gradient(colors: [Color.blue.opacity(0.7), .mint]))
            
            // Quick nudges
            HStack(spacing: 8) {
                ForEach([ -5, -2, -1, +1, +2, +5 ], id: \.self) { step in
                    Button(action: { vm.plan.hydrationPct = (vm.plan.hydrationPct + Double(step)).clamped(to: 45...90) }) {
                        Text(step > 0 ? "+\(step)%" : "\(step)%")
                            .font(.subheadline).padding(.horizontal, 10).padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.background.quaternary))
    }
    
    var ingredientsBars: some View {
        let flour = vm.plan.flourGrams
        let items: [(String, Double, String)] = [
            ("Flour", flour, formatWeight(flour, style: vm.plan.unitStyle)),
            ("Water", vm.plan.waterGrams, formatWeight(vm.plan.waterGrams, style: vm.plan.unitStyle)),
            ("Salt", vm.plan.saltGrams, formatWeight(vm.plan.saltGrams, style: vm.plan.unitStyle)),
            ("Yeast", vm.plan.yeastGrams, formatWeight(vm.plan.yeastGrams, style: vm.plan.unitStyle)),
            ("Oil", vm.plan.oilGrams, formatWeight(vm.plan.oilGrams, style: vm.plan.unitStyle)),
            ("Sugar", vm.plan.sugarGrams, formatWeight(vm.plan.sugarGrams, style: vm.plan.unitStyle))
        ].filter { $0.1 > 0.0001 }
        
        let maxVal = max(items.map { $0.1 }.max() ?? 1, 1)
        
        return VStack(alignment: .leading, spacing: 10) {
            Label("Ingredients", systemImage: "chart.bar.fill").font(.headline)
            ForEach(items, id: \.0) { name, value, formatted in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(name).bold(); Spacer(); Text(formatted).monospacedDigit() }
                    GeometryReader { geo in
                        let width = geo.size.width * value / maxVal
                        RoundedRectangle(cornerRadius: 8)
                            .fill(name == "Flour" ? .orange : name == "Water" ? .blue : .secondary)
                            .frame(width: width, height: 14, alignment: .leading)
                            .animation(.easeInOut(duration: 0.35), value: value)
                    }
                    .frame(height: 14)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.background.quaternary))
    }
    
    var fermentationTimeline: some View {
        // Mock timeline: bulk, ball, cold, bench. Progress is illustrative.
        struct Stage: Identifiable { let id = UUID(); let name: String; let durationH: Double; let progress: Double }
        let stages = [
            Stage(name: "Bulk", durationH: 2.0, progress: 0.7),
            Stage(name: "Ball", durationH: 0.5, progress: 0.4),
            Stage(name: "Cold", durationH: 24.0, progress: 0.2),
            Stage(name: "Bench", durationH: 1.0, progress: 0.1)
        ]
        
        return VStack(alignment: .leading, spacing: 10) {
            Label("Fermentation", systemImage: "timer").font(.headline)
            ForEach(stages) { st in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(st.name).bold(); Spacer(); Text("\(st.durationH, specifier: "%.1f") h").monospacedDigit() }
                    ProgressView(value: st.progress)
                        .progressViewStyle(.linear)
                        .tint(.green)
                }
            }
            Text("Edit timings in a later step – this is a visual placeholder").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.background.quaternary))
    }
    
    var unitStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Unit Display", systemImage: "scalemass.fill").font(.headline)
            Picker("Units", selection: $vm.plan.unitStyle) {
                ForEach(DoughPlan.UnitStyle.allCases) { s in Text(s.label).tag(s) }
            }
            .pickerStyle(.segmented)
            Toggle("Show flour cups beside weight", isOn: $vm.showCupsBesideFlour)
                .font(.subheadline)
                .tint(.orange)
            Text("1 cup flour assumed = \(Int(vm.plan.flourDensityGPerCup)) g (change in code)")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.background.quaternary))
    }
}

// MARK: - Components
private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.title2).bold().monospacedDigit()
            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(.thickMaterial))
    }
}

// MARK: - Helpers
private extension DoughPlan.UnitStyle {
    var label: String {
        switch self {
        case .grams: return "Grams"
        case .kgAndGrams: return "kg + g"
        case .ounces: return "Ounces"
        case .poundsAndOunces: return "lb + oz"
        }
    }
}

private func flourDisplay(_ plan: DoughPlan? = nil) -> String {
    // Placeholder allows easy default for previews; not used here.
    return ""
}

private extension PizzaVisualizationView {
    func flourDisplay() -> String {
        let gramsStr = formatWeight(vm.plan.flourGrams, style: vm.plan.unitStyle)
        guard vm.showCupsBesideFlour else { return gramsStr }
        let cups = vm.plan.flourCups
        let cupsStr = cups.formatted(.number.precision(.fractionLength(1)))
        return "\(gramsStr) (\(cupsStr) cups)"
    }
    
    func formatWeight(_ grams: Double, style: DoughPlan.UnitStyle) -> String {
        switch style {
        case .grams:
            return grams.roundedString(0) + " g"
        case .kgAndGrams:
            let kg = Int(grams) / 1000
            let g = Int(grams) % 1000
            if kg == 0 { return "\(g) g" }
            return "\(kg) kg \(g) g"
        case .ounces:
            let oz = grams / 28.349523125
            return oz.roundedString(1) + " oz"
        case .poundsAndOunces:
            let totalOz = grams / 28.349523125
            let lb = Int(totalOz) / 16
            let ozR = totalOz - Double(lb * 16)
            if lb == 0 { return ozR.roundedString(1) + " oz" }
            return "\(lb) lb \(ozR.roundedString(1)) oz"
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double { min(max(self, range.lowerBound), range.upperBound) }
    func roundedString(_ fractionDigits: Int) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = fractionDigits
        f.maximumFractionDigits = fractionDigits
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self.rounded(toPlaces: fractionDigits))) ?? String(format: "%.*f", fractionDigits, self)
    }
    func rounded(toPlaces places:Int) -> Double {
        guard places >= 0 else { return self }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Preview
struct PizzaVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PizzaVisualizationView()
                .environment(\.colorScheme, .light)
            PizzaVisualizationView()
                .environment(\.colorScheme, .dark)
        }
    }
}
