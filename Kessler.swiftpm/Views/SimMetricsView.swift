import SwiftUI

struct SimMetrics: View {
    @ObservedObject var telemetry: Telemetry
    
    init(sim: Simulation) {
        self.telemetry = sim.telemetry
    }
    
    var statusColor: Color {
        telemetry.stats.debris > 1000 ? .red : .white
    }
    
    var body: some View {
        VStack(spacing: 12) {
            MetricRow(
                title: "ACTIVE SATELLITES",
                value: telemetry.stats.satellites,
                color: .white
            )
            
            Divider()
                .background(.white.opacity(0.2))
                .padding(.horizontal, 20)
            
            MetricRow(
                title: "TRACKED DEBRIS",
                value: telemetry.stats.debris,
                color: statusColor
            )
        }
        .padding(.vertical, 16)
        .frame(width: 160)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

private struct MetricRow: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color == .white ? .cyan : color)
                .opacity(0.9)
            
            Text("\(value)")
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
        }
    }
}
