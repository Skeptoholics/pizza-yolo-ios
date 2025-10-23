import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MakingPizzaView()
                .tabItem { Label("Making", systemImage: "fork.knife") }

            CateringPizzaView()
                .tabItem { Label("Catering", systemImage: "tray") }
        }
    }
}

#Preview { ContentView() }
