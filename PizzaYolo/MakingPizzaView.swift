import SwiftUI

struct MakingPizzaView: View {
    @State private var numberOfPizzas = 1
    @State private var doughPerPizza = 250 // grams
    @State private var saucePerPizza = 100 // grams
    @State private var cheesePerPizza = 150 // grams
    @State private var toppingsPerPizza = 75 // grams

    var totalDough: Int { numberOfPizzas * doughPerPizza }
    var totalSauce: Int { numberOfPizzas * saucePerPizza }
    var totalCheese: Int { numberOfPizzas * cheesePerPizza }
    var totalToppings: Int { numberOfPizzas * toppingsPerPizza }

    var body: some View {
        Form {
            Section(header: Text("Pizza Quantity")) {
                Stepper("Number of pizzas: \(numberOfPizzas)", value: $numberOfPizzas, in: 1...100)
            }

            Section(header: Text("Ingredients per Pizza (grams)")) {
                Stepper("Dough: \(doughPerPizza)g", value: $doughPerPizza, in: 100...500, step: 25)
                Stepper("Sauce: \(saucePerPizza)g", value: $saucePerPizza, in: 50...200, step: 10)
                Stepper("Cheese: \(cheesePerPizza)g", value: $cheesePerPizza, in: 50...300, step: 10)
                Stepper("Toppings: \(toppingsPerPizza)g", value: $toppingsPerPizza, in: 0...200, step: 10)
            }

            Section(header: Text("Total Ingredients Needed")) {
                Text("Dough: \(totalDough)g")
                Text("Sauce: \(totalSauce)g")
                Text("Cheese: \(totalCheese)g")
                Text("Toppings: \(totalToppings)g")
            }
        }
        .navigationTitle("Pizza Maker")
    }
}
