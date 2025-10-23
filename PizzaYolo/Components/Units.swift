import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case grams = "Grams"
    case kgGrams = "Kilograms + grams"
    case ounces = "Ounces"
    case lbOunces = "Pounds + ounces"

    var id: String { rawValue }

    // conversions
    static let gPerOz = 28.349523125
    static let gPerLb = 453.59237
    static let gPerKg = 1000.0
    static let gPerCupFlour = 120.0 // AP flour approx.

    static func flourCups(fromFlourGrams g: Double) -> String {
        let cups = g / gPerCupFlour
        return String(format: "%.1f cups", cups)
    }

    func format(grams g: Double) -> String {
        switch self {
        case .grams:
            return "\(Int(round(g))) g"
        case .kgGrams:
            let kg = Int(g / Self.gPerKg)
            let rem = Int(round(g.truncatingRemainder(dividingBy: Self.gPerKg)))
            return "\(kg) kg \(rem) g"
        case .ounces:
            let oz = g / Self.gPerOz
            return String(format: "%.1f oz", oz)
        case .lbOunces:
            let totalOz = g / Self.gPerOz
            let lb = Int(totalOz / 16.0)
            let ozRem = totalOz - Double(lb) * 16.0
            return "\(lb) lb " + String(format: "%.1f oz", ozRem)
        }
    }
}
