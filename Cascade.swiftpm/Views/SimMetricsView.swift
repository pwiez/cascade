import SwiftUI

enum OrbitalStatus: String {
    case stable = "Stable"
    case colliding = "Collisions Active"
    case critical = "Critical Density"
    
    var color: Color {
        switch self {
        case .stable:    return .green
        case .colliding: return .yellow
        case .critical:  return .red
        }
    }
    
    var icon: String {
        switch self {
        case .stable:    return "checkmark.circle.fill"
        case .colliding: return "exclamationmark.triangle.fill"
        case .critical:  return "xmark.octagon.fill"
        }
    }
    
    static func evaluate(debris: Int, satellites: Int) -> OrbitalStatus {
        if debris == 0 { return .stable }
        if debris > satellites * 3 { return .critical }
        return .colliding
    }
}

struct SimMetrics: View {
    @ObservedObject var telemetry: Telemetry
    let initialSatellites: Int
    
    private var stats: SimStats { telemetry.stats }
    
    private var status: OrbitalStatus {
        OrbitalStatus.evaluate(
            debris: stats.debris,
            satellites: stats.satellites
        )
    }
    
    private var survivorRatio: Double {
        guard initialSatellites > 0 else { return 1.0 }
        return Double(stats.satellites) / Double(initialSatellites)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.caption2)
                    .contentTransition(.symbolEffect(.replace))
                
                Text(status.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .contentTransition(.numericText())
            }
            .foregroundStyle(status.color)
            .animation(.easeInOut(duration: 0.3), value: status)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Orbital status: \(status.rawValue)")
            
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                MetricRow(
                    icon: "satellite.fill",
                    label: "Satellites",
                    value: stats.satellites,
                    accent: .green
                )
                
                MetricRow(
                    icon: "sparkles",
                    label: "Debris",
                    value: stats.debris,
                    accent: status.color
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Integrity")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(survivorRatio * 100))%")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: survivorRatio))
                            .animation(.snappy, value: survivorRatio)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.08))
                            
                            Capsule()
                                .fill(status.color.gradient)
                                .frame(width: max(0, geo.size.width * survivorRatio))
                                .animation(.snappy(duration: 0.4), value: survivorRatio)
                        }
                    }
                    .frame(height: 4)
                    .clipShape(Capsule())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fleet integrity: \(Int(survivorRatio * 100)) percent")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 180)
        .glassEffect(in: .rect(cornerRadius: 16.0))
        .accessibilityElement(children: .contain)
    }
}

private struct MetricRow: View {
    let icon: String
    let label: String
    let value: Int
    let accent: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(accent)
                .frame(width: 14)
            
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

#Preview("HUD Stats") {
    let mockTelemetry = Telemetry()
    mockTelemetry.stats.satellites = 142
    mockTelemetry.stats.debris = 36
    
    return SimMetrics(telemetry: mockTelemetry, initialSatellites: 150)
        .padding()
        .background(.black)
}
