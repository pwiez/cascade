import SwiftUI

struct SimulationMetrics: View {
    let telemetry: Telemetry
    let initialSatellites: Int
    let satelliteColor: Color
    let debrisColor: Color

    var body: some View {
        HStack(spacing: 16) {
            MetricItem(title: "SATELLITES", value: telemetry.stats.satellites, color: satelliteColor)

            Divider()
                .cascadeDivider()
                .frame(height: 16)

            MetricItem(title: "DEBRIS", value: telemetry.stats.debris, color: debrisColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .applyGlassPanel()
    }
}
