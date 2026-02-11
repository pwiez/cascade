import SwiftUI

struct SimMetrics: View {
    @ObservedObject var sim: Simulation
    
    var threatColor: Color {
        sim.debrisCount > 1000 ? .red : .white
    }
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Satellites Remaining")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.cyan)
                    .opacity(0.8)
                
                if #available(iOS 17.0, *) {
                    Text("\(sim.leoRemaining)")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(sim.leoRemaining)))
                        .animation(.snappy, value: sim.leoRemaining)
                } else {
                }
            }
            
            VStack(spacing: 0) {
                Text("Debris Pieces")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(threatColor)
                    .opacity(0.8)
                
                if #available(iOS 17.0, *) {
                    Text("\(sim.debrisCount)")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundStyle(threatColor)
                        .contentTransition(.numericText(value: Double(sim.debrisCount)))
                        .animation(.snappy, value: sim.debrisCount)
                } else {
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(radius: 5)
    }
}
