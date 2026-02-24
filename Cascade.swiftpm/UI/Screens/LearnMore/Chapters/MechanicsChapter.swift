import SwiftUI

struct MechanicsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            
            VStack(alignment: .leading, spacing: 24) {
                
                Text("The Cascade Effect")
                    .font(.title3.bold()).foregroundStyle(.white)
                
                TextParagraph("Kessler Syndrome is not a single event — it is a self-reinforcing process that takes decades to reach criticality. As the number of objects in a given orbital shell increases, the probability of collision rises proportionally. Each collision produces a cloud of fragments, and each fragment becomes a new potential projectile. Over time, the debris population grows exponentially, even without new launches.")
                
                TextParagraph("This positive feedback loop is the core of the Kessler hypothesis: beyond a critical density threshold, the debris environment becomes self-sustaining. Collisions generate debris faster than atmospheric drag can remove it, and the affected orbital band gradually becomes impassable.")
                
                ScientificCard { CausalFlowDiagram() }
                
                KeyConceptBox(
                    title: "Critical Density Threshold",
                    bodyText: "This is the point at which the rate of debris-generating collisions exceeds the rate of natural debris removal (primarily atmospheric drag). Below ~600 km, residual atmosphere clears fragments within years. Above ~800 km, debris can persist for centuries.",
                    icon: "exclamationmark.arrow.circlepath"
                )
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Orbital Energy")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Why are orbital collisions so catastrophic? Velocity!\n\nObjects in Low Earth Orbit travel at approximately 7.5 km/s — over 27,000 km/h, or approximately 16700 mph. At these speeds, kinetic energy scales dramatically, and even very small particles carry enough energy to severely damage whatever they hit.")
                
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("KINETIC ENERGY EQUATION", systemImage: "function")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)
                        
                        HStack(spacing: 4) {
                            Text("E")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.white)
                            Text("=")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("½")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("m")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.cyan)
                            Text("v²")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.orange)
                                .padding(.leading, -2)
                        }
                        .padding(.vertical, 8)
                        .accessibilityLabel("Kinetic energy equals one half times mass times velocity squared.")
                        
                        Text("Because energy scales with the **square** of velocity, doubling the speed of impact quadruples the energy released. A 1 cm aluminum sphere at orbital velocity carries the kinetic energy of a hand grenade.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                    }
                }
                
                ScientificCard { ImpactComparisonView() }
                
                TextParagraph("At relative closing speeds that can reach 15 km/s in head-on scenarios, collisions are extremely violent. The resulting debris cloud expands along the original orbit, creating a persistent hazard zone that acts as a kind of destructive broom.")
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("The Invisible Threat")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks can reliably track objects larger than about 10 cm. However, fragments between 1 mm and 10 cm — too small to track but large enough to destroy — represent the most dangerous population. This is because what determines the kind of problem an impact will cause is not necessarily the size of the thing that hits, but its velocity. Every bit of frozen coolant, every bolt, small metal shards, and even paint flecks can become small missiles. This is why the number of untracked debris is estimated to be so high, at over 130 million currently. They are simply too small for us to know where they are!")
                
                ScientificCard { DebrisSizeClassView() }
            }
        }
    }
}

struct DebrisSizeClassView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("DEBRIS SIZE CLASSES", systemImage: "ruler.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(CascadeTheme.dimText)
            
            VStack(spacing: 14) {
                DebrisSizeRow(
                    size: "> 10 cm",
                    count: "~35,000", 
                    status: "Tracked",
                    statusColor: .green,
                    effect: "Catastrophic breakup",
                    proportion: 1.0
                )
                DebrisSizeRow(
                    size: "1 – 10 cm",
                    count: "~1.2 million", 
                    status: "Untracked", 
                    statusColor: .yellow,
                    effect: "Mission-ending damage",
                    proportion: 0.5
                )
                DebrisSizeRow(
                    size: "1 mm – 1 cm",
                    count: "~140 million", 
                    status: "Untracked",
                    statusColor: .red,
                    effect: "Degradation, destruction of fragile components",
                    proportion: 0.1 
                )
            }
        }
    }
}

struct DebrisSizeRow: View {
    let size: String
    let count: String
    let status: String
    let statusColor: Color
    let effect: String
    let proportion: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(size)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(status)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(CascadeTheme.iconBackgroundOpacity))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                Text(count)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 100, alignment: .leading)
                
                Text(effect)
                    .font(.caption)
                    .foregroundStyle(CascadeTheme.mutedText)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CascadeTheme.trackColor)
                        .frame(height: CascadeTheme.trackHeight)
                    
                    Capsule()
                        .fill(statusColor.opacity(0.6))
                        .frame(width: geo.size.width * proportion, height: CascadeTheme.trackHeight)
                }
            }
            .frame(height: CascadeTheme.trackHeight)
        }
        .padding(CascadeTheme.compactPadding)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(size): estimated \(count) objects, \(status). Effect: \(effect)")
    }
}
