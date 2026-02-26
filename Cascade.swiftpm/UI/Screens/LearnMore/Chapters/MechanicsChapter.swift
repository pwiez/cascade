import SwiftUI

struct MechanicsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("The Cascade Effect")
                    .font(.title3.bold()).foregroundStyle(.white)
                
                TextParagraph("Kessler Syndrome is not a single event, and it definitely doesn't happen as fast as it does in this simulation. Instead, it is a self-reinforcing process that can take decades to reach \(Text("criticality").bold()). In the next chapter, you'll see more about how the situation has been developing for the past 60 years. It's like a slow burn for the most part. In more recent times, however, things have been ramping up.")
                
                ScientificCard { CausalFlowDiagram() }
                
                KeyConceptBox(
                    title: "Hold on a second. Criticality? What does that mean?",
                    bodyText: "This is the point at which the rate of debris-generating collisions exceeds the rate of natural debris removal (primarily by means of atmospheric drag). Below ~600 km, residual atmosphere clears fragments within years. Above ~800 km, debris can persist for centuries. More on that in the Remediation chapter!",
                    icon: "exclamationmark.arrow.circlepath"
                )
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Orbital Energy")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Why are orbital collisions so catastrophic? Velocity! Objects in Low Earth Orbit travel at approximately 7.5 km/s — over 27,000 km/h, or approximately 16700 mph. At these speeds, kinetic energy scales dramatically, and even very small particles carry enough energy to severely damage whatever is unlucky enough to be in their path.")
                
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("KINETIC ENERGY EQUATION", systemImage: "function")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)
                        
                        HStack(spacing: 4) {
                            Text("E")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.green)
                            Text("=")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("½")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("m")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text("v²")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.orange)
                                .padding(.leading, -2)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Kinetic energy equals one half times mass times velocity squared.")
                        
                        Text("Because energy scales with the **square** of \(Text("velocity").foregroundStyle(.orange)), doubling the speed of impact quadruples the \(Text("energy").foregroundStyle(.green)) released. A small aluminum sphere with not that much \(Text("mass").foregroundStyle(.blue)) at orbital speeds carries the kinetic energy of a hand grenade, or more!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                    }
                }
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Invisible Space Missiles")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks can reliably track objects larger than about 10 cm. However, fragments between 1 mm and 10 cm — too small to track but large enough to destroy — represent the most dangerous population. This is because, as you just saw, what determines the problem an impact will cause is not necessarily the size of the thing that hits, but its velocity.\n\nEvery bit of frozen coolant, bolts, small metal shards, and even paint flecks can become small missiles. This is why the number of untracked debris is estimated to be so high. They are simply too small for us to know where or how many they are!")
            
                HStack (spacing: 14){
                    OperationalStatCard(
                        value: "> 14,500",
                        unit: "satellites",
                        label: "active and operational as of 2026",
                        icon: "",
                        accent: .blue
                    )
                    
                    OperationalStatCard(
                        value: "> 44,000",
                        unit: "tracked",
                        label: "objects in orbit by Space Surveillance Networks",
                        icon: "",
                        accent: .yellow
                    )
                }
                
                HStack (spacing: 14){
                    OperationalStatCard(
                        value: "1.2 million+",
                        unit: "non-tracked",
                        label: "objects estimated to be in orbit from 1 to 10cm",
                        icon: "",
                        accent: .orange
                    )
                    OperationalStatCard(
                        value: "140 million+",
                        unit: "non-tracked",
                        label: "objects estimated to be in orbit from 1mm to 1cm",
                        icon: "",
                        accent: .red
                    )
                }
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
                
                Text("/")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(effect)
                    .font(.caption)
                    .foregroundStyle(CascadeTheme.mutedText)
                
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
                
                Spacer()
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

#Preview(traits: .landscapeLeft) {
    DebrisSizeClassView()
}
