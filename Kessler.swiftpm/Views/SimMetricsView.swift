import SwiftUI

struct SimMetrics: View {
    @ObservedObject var sim: Simulation
    
    var statusColor: Color {
        sim.stats.debris > 1000 ? .red : .white
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("ACTIVE SATELLITES")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
                    .opacity(0.9)
                
                    Text("\(sim.stats.satellites)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(sim.stats.satellites)))
                        .animation(.snappy, )
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
                    Text("\(sim.stats.debris)")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .contentTransition(.numericText(value: Double(sim.stats.debris)))
                } else {
                    Text("\(sim.stats.debris)")
                        .font(.monospaced(.body)())
                        .foregroundStyle(statusColor)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(width: 160)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
