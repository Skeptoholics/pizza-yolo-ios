import Foundation

struct Recipe: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var doughBalls: Int
    var ballWeightGrams: Double
    var hydrationPct: Double
    var saltPct: Double
    var yeastPct: Double
}

@MainActor
final class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []

    private let key = "PizzaYoloRecipes"

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            self.recipes = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ r: Recipe) {
        recipes.append(r)
        save()
    }

    func delete(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        save()
    }
}
