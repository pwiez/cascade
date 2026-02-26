import SwiftUI

struct SimulationMetrics: View {
    @ObservedObject var telemetry: Telemetry
    let initialSatellites: Int
    let satelliteColor: Color
    let debrisColor: Color
    
    private var stats: SimStats { telemetry.stats }
    
    var body: some View {
        HStack(spacing: 16) {
            metricItem(title: "SATELLITES", value: stats.satellites, color: satelliteColor)
            
            Divider()
                .cascadeDivider()
                .frame(height: 16)
            
            metricItem(title: "DEBRIS", value: stats.debris, color: debrisColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassEffect()
    }
    
    @ViewBuilder
    private func metricItem(title: String, value: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(value.formatted())
                .font(.system(.body).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }
}
