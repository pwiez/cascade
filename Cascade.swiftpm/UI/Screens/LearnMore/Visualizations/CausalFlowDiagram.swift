import SwiftUI

struct CausalFlowDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            
            HStack(spacing: 0) {
                flowNode(icon: "cube.fill", title: "Density of objects\nin orbit increases", color: .blue)
                flowConnector
                flowNode(icon: "burst.fill", title: "A collision happens\nbetween them", color: .orange)
                flowConnector
                flowNode(icon: "aqi.medium", title: "Many new objects\nare created", color: .gray)
                flowConnector
                flowNode(icon: "exclamationmark.triangle.fill", title: "Collision risk\nincreases", color: .red)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.turn.up.left")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.6))
                Text("Each of these events feeds every other event!")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.mutedText)
                Image(systemName: "arrow.turn.up.right")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cascade loop diagram: increasing density leads to collisions, which create fragments, which escalate risk, which further increases density. The loop is self-reinforcing.")
    }
    
    var flowConnector: some View {
        VStack {
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.primary.opacity(0.7))
        }
        .frame(width: 24)
    }
    
    func flowNode(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ThemedIcon(systemName: icon, color: color, isCircle: true)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.cardBorder, lineWidth: 1)
        )
    }
}
