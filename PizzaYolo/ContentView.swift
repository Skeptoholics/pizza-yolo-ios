import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("🍕 Pizza Yolo")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink(destination: MakingPizzaView()) {
                    Text("I'm Making Pizza")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                NavigationLink(destination: CateringPizzaView()) {
                    Text("I'm Catering with Pizza")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Pizza Yolo")
        }
    }
}
