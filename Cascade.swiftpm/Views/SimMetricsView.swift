import SwiftUI

struct SimMetrics: View {
    @ObservedObject var telemetry: Telemetry
    
    init(sim: Simulation) {
        self.telemetry = sim.telemetry
    }
    
    var body: some View {
        HStack(spacing: 24) {
            StatUnit(
                value: telemetry.stats.satellites,
                label: "SATELLITES",
                indicatorColor: .green
            )
            
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 24)
            
            StatUnit(
                value: telemetry.stats.debris,
                label: "DEBRIS",
                indicatorColor: telemetry.stats.debris > 1000 ? .red : .primary
            )
        }
        .padding(.horizontal)
        .padding(.vertical)
        .clipShape(Capsule())
        .glassEffect()
    }
}

private struct StatUnit: View {
    let value: Int
    let label: String
    let indicatorColor: Color
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
                .monospacedDigit()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 6, height: 6)
                
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }
}

#Preview("HUD Stats") {
    let mockSim = Simulation()
    mockSim.telemetry.stats.satellites = 294
    mockSim.telemetry.stats.debris = 36
    
    return SimMetrics(sim: mockSim)
        .padding()
        .background(.black)
}
