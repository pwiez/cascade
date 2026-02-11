import SwiftUI

struct KnowledgeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The Kessler Syndrome")
                            .font(.system(.largeTitle, design: .serif))
                            .bold()
                        Text("When space becomes a cage.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                        FactCard(
                            title: "Critical Density",
                            content: "The point where the creation of debris triggers a runaway chain reaction. Even if we stop launching today, collisions will continue to increase."
                        )
                        FactCard(
                            title: "Orbital Decay",
                            content: "Debris in Low Earth Orbit (LEO) is cleared by atmospheric drag. Higher orbits (MEO/GEO) can hold debris for centuries or millennia."
                        )
                    }
                    
                    Text("Simulation Logic")
                        .font(.title2)
                        .bold()
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        CompromiseRow(icon: "clock.arrow.2.circlepath", title: "Time Dilation", desc: "Orbits are real-time, but collisions are accelerated for visibility.")
                        CompromiseRow(icon: "ruler.fill", title: "Scale Factors", desc: "Satellites are 1000x larger than reality to be visible on screen.")
                    }
                }
                .padding()
            }
            .navigationTitle("Encyclopedia")
        }
    }
}
