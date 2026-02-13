import SwiftUI

struct PerformanceSection: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        Section(header: Text("Performance Limit"), footer: Text("Capping the debris count prevents the simulation from lagging on older devices.")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(simulation.maxDebris > 2500 ? .orange : .green)
                    Text("Max Debris Limit")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(simulation.maxDebris))")
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $simulation.maxDebris, in: 500...3000, step: 100)
                    .tint(simulation.maxDebris > 2500 ? .orange : .green)
                
                if simulation.maxDebris >= 3000 {
                    Text("Maximum limit reached.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
