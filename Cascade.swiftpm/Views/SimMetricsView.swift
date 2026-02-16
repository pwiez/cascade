import SwiftUI

struct SimMetrics: View {
    @ObservedObject var telemetry: Telemetry
    
    init(sim: Simulation) {
        self.telemetry = sim.telemetry
    }
    
    var body: some View {
        HStack(spacing: 32) {
            MetricItem(
                label: "ACTIVE SATS",
                value: telemetry.stats.satellites,
                icon: "dot.radiowaves.left.and.right",
                color: .cyan
            )
            
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1)
                .frame(maxHeight: 40)
            
            MetricItem(
                label: "DEBRIS COUNT",
                value: telemetry.stats.debris,
                icon: "circle.grid.hex.fill",
                color: telemetry.stats.debris > 1000 ? .red : .white
            )
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .contain)
    }
}

private struct MetricItem: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.snappy, value: value)
                    .minimumScaleFactor(0.8)
                
                Text(label)
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
