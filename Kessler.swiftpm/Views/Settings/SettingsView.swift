import SwiftUI

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        NavigationStack {
            Form {
                TimeSection(simulation: simulation)
                PerformanceSection(simulation: simulation)
                PopulationSection(simulation: simulation)
                PhysicsSection(simulation: simulation)
                VisualsRealitySection(simulation: simulation)
                ActionsSection(simulation: simulation)
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
