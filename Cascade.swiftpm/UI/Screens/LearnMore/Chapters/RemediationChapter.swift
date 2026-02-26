import SwiftUI

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            TextParagraph("The situation is grim, but fixable. We need to do three things: stop making new debris, responsibly dispose of dead satellites, and drag the most dangerous junk out of orbit before it gets hit.")
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Atmospheric Drag")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("Earth's atmosphere does not just end. It tapers off gradually. The sparse gas molecules at high altitudes exert a persistent drag force on orbiting objects. Over time, this drag lowers an object's altitude until it burns up in the thicker atmosphere.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How long does it take for an object to deorbit through drag alone?")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)

                        VStack(spacing: 12) {
                            DragLifetimeRow(altitude: "300 km", lifetime: "Weeks to months", intensity: 1.0, color: .green)
                            DragLifetimeRow(altitude: "400 km", lifetime: "~1 year", intensity: 0.75, color: .green)
                            DragLifetimeRow(altitude: "600 km", lifetime: "~25 years", intensity: 0.45, color: .yellow)
                            DragLifetimeRow(altitude: "800 km", lifetime: "~100–200 years", intensity: 0.10, color: .orange)
                            DragLifetimeRow(altitude: "1,000 km", lifetime: "~1,000+ years", intensity: 0.02, color: .red)
                        }
                    }
                }
                .padding(.vertical)
                
                TextParagraph("Below 600 km, drag clears most debris within a few decades. The real challenge lies in higher orbits, where drag is negligible and debris persists for centuries.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Active Removal Technologies")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("Atmospheric drag alone is insufficient. We need engineered interventions to clear higher orbits. Several approaches are currently under development. These sound like science fiction, but they are real hardware being tested today.")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Drag Augmentation",
                        icon: "wind",
                        description: "Deployable sails or inflatable structures dramatically increase a satellite's cross-sectional area. Operators deploy these devices at the end of a mission to accelerate orbital decay.",
                        mechanism: "Increasing the area-to-mass ratio multiplies the effect of atmospheric drag. This reduces deorbit time from centuries to years."
                    )
                    
                    StrategyCard(
                        title: "Harpoons & Nets",
                        icon: "lasso",
                        description: "A chaser spacecraft approaches a defunct satellite or rocket body and secures it using a tethered harpoon or a deployable net. The chaser then fires its engines to drag both craft down.",
                        mechanism: "The RemoveDEBRIS mission demonstrated net capture in 2018. ESA's ClearSpace-1 mission plans to perform the first full-scale removal of a 95kg payload adapter in 2028."
                    )
                    
                    StrategyCard(
                        title: "Laser Ablation",
                        icon: "dot.radiowaves.left.and.right",
                        description: "Ground-based or orbital lasers target a piece of debris. The focused energy vaporizes a tiny amount of surface material. The ejected vapor acts as a miniature thruster, pushing the debris.",
                        mechanism: "Repeated laser passes gradually slow the object down until atmospheric drag takes over. It requires no physical contact."
                    )
                    
                    StrategyCard(
                        title: "Magnetic Stabilization & Braking",
                        icon: "gyroscope",
                        description: "Tumbling debris is dangerous to approach. Magnetic tugs generate rotating magnetic fields that induce eddy currents in the target's metal hull, creating drag forces from a safe distance.",
                        mechanism: "These forces stabilize tumbling targets for capture or directly slow them down. This technology remains highly experimental."
                    )
                }
            }
            
            Divider().cascadeDivider()
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("The 25-Year Guideline", systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(.white)
                    
                    Text("The Inter-Agency Space Debris Coordination Committee (IADC) recommends that all satellites in Low Earth Orbit deorbit within 25 years of mission end. In the 2020s, the U.S. Federal Communications Commission adopted a stricter 5-year rule. However, compliance remains voluntary for many global operators.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(CascadeTheme.bodyLineSpacing)
                }
            }
        }
    }
}

struct DragLifetimeRow: View {
    let altitude: String
    let lifetime: String
    let intensity: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(altitude)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CascadeTheme.trackColor)
                    Capsule()
                        .fill(color.opacity(0.6))
                        .frame(width: max(geo.size.width * intensity, CascadeTheme.trackHeight))
                }
            }
            .frame(height: CascadeTheme.trackHeight + 1)
            .clipShape(Capsule())
            
            Text(lifetime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(CascadeTheme.mutedText)
                .frame(width: 120, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("At \(altitude): debris lifetime approximately \(lifetime)")
    }
}

struct StrategyCard: View {
    let title: String
    let icon: String
    let description: String
    let mechanism: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                ThemedIcon(systemName: icon, color: .blue, isCircle: true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            
            Divider().overlay(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 16) {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.8))
                        .padding(.top, 4)
                    
                    Text(mechanism)
                        .font(.subheadline)
                        .foregroundStyle(CascadeTheme.bodyText)
                        .lineSpacing(CascadeTheme.bodyLineSpacing)
                }
                .padding(CascadeTheme.compactPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .padding(CascadeTheme.cardPadding)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .contain)
    }
}
