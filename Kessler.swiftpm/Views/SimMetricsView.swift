import SwiftUI

struct SimMetrics: View {
    @ObservedObject var sim: Simulation
    
    var statusColor: Color {
        sim.debrisCount > 1000 ? .red : .white
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            VStack(spacing: 2) {
                Text("ACTIVE SATELLITES")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
                    .opacity(0.9)
                
                if #available(iOS 17.0, *) {
                    Text("\(sim.activeSatellites)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(sim.activeSatellites)))
                        .animation(.snappy, value: sim.activeSatellites)
                } else {
                    Text("\(sim.activeSatellites)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
                .padding(.horizontal, 20)
            
            VStack(spacing: 2) {
                Text("TRACKED DEBRIS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .opacity(0.9)
                
                if #available(iOS 17.0, *) {
                    Text("\(sim.debrisCount)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .contentTransition(.numericText(value: Double(sim.debrisCount)))
                        .animation(.snappy, value: sim.debrisCount)
                } else {
                    Text("\(sim.debrisCount)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(statusColor)
                }
            }
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
