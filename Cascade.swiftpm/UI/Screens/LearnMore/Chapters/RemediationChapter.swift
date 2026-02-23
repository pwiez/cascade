import SwiftUI

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            TextParagraph("Addressing orbital debris is a systems-level challenge requiring a three-pronged approach: prevent new debris generation through better design and operations, enforce responsible disposal of end-of-life spacecraft, and actively remove the highest-risk legacy objects before they fragment.")
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Atmospheric Drag")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("This is our main ally. Even at orbital altitudes, Earth's atmosphere does not just end. It tapers off gradually, eventually ending very high up. Even though they're few and far between, residual gas molecules at high altitudes exert persistent faint drag force on orbiting objects. Over time, this drag lowers an object's altitude until it re-enters the atmosphere and burns up. The length of time depends directly on the altitude of the object.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 24) {
                        Label("ORBITAL DECAY BY ALTITUDE", systemImage: "arrow.down.to.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)
                            .tracking(0.6)
                        
                        VStack(spacing: 12) {
                            DragLifetimeRow(altitude: "300 km", lifetime: "Weeks to months", intensity: 1.0, color: .green)
                            DragLifetimeRow(altitude: "400 km", lifetime: "~1 year", intensity: 0.7, color: .green)
                            DragLifetimeRow(altitude: "600 km", lifetime: "~25 years", intensity: 0.4, color: .yellow)
                            DragLifetimeRow(altitude: "800 km", lifetime: "~100–200 years", intensity: 0.15, color: .orange)
                            DragLifetimeRow(altitude: "1,000 km", lifetime: "~1,000+ years", intensity: 0.04, color: .red)
                        }
                        
                        Text("Solar activity cycles cause the upper atmosphere to expand and contract, significantly affecting drag rates. During solar maxima, decay accelerates; during minima, it slows.")
                            .font(.caption)
                            .foregroundStyle(CascadeTheme.mutedText)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                            .padding(.top, 4)
                    }
                }
                
                TextParagraph("Below approximately 600 km, atmospheric drag is effective enough to clear most debris within a few decades. This is why the International Space Station orbits at ~400 km — even if disaster struck and it got destroyed, debris generated at that altitude is naturally swept away relatively quickly. The challenge lies in higher orbits, where drag is negligible and debris persists for centuries.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Active Removal Technologies")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Where atmospheric drag alone is insufficient, engineered interventions are required. Several approaches are under development, each targeting different aspects of the debris problem. There have been a lot of advancements in proposed technologies, some tests have already been successful, and more are planned in coming years.")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Drag augmentation with drag sails",
                        icon: "wind",
                        description: "Deployable drag sails or inflatable structures dramatically increase a spacecraft's cross-sectional area, which increases its susceptibility to drag forces. At the end of life of a spacecraft, these devices can be deployed, accelerating orbital decay through atmospheric drag. Drag sails are lightweight and can be integrated into satellite design fairly easily, which makes this is a very cost-effective solution.",
                        mechanism: "By increasing the area-to-mass ratio, atmospheric drag forces multiply, reducing deorbit time from centuries to years, or even months, even at high altitudes."
                    )
                    
                    StrategyCard(
                        title: "Harpoons, nets and chaser spacecraft",
                        icon: "lasso",
                        description: "A specialized chaser spacecraft approaches a large defunct satellite or rocket body, or another type of large debris, and secures it using a tethered harpoon or deployable net. Once it's captured, the spacecraft performs a controlled burn that deorbits the debris.",
                        mechanism: "The RemoveDEBRIS mission (2018) successfully demonstrated both net capture and harpoon penetration in orbit. ESA's ClearSpace-1, planned for 2026, aims to be the first full-scale removal mission."
                    )
                    
                    StrategyCard(
                        title: "Laser ablation",
                        icon: "dot.radiowaves.left.and.right",
                        description: "High-powered ground-based or orbital lasers target a debris object's surface. The laser's focused energy vaporizes a small amount of material. This creates a gas jet that acts as a miniature thruster, applying a small but very precise impulse to the object.",
                        mechanism: "Repeated laser passes over days or weeks can gradually lower the object's orbit until atmospheric drag finishes the job. No physical contact is required, and resource-wise this is fairly efficient."
                    )
                    
                    StrategyCard(
                        title: "Magnetic braking and stabilizing",
                        icon: "gyroscope",
                        description: "Tumbling debris objects are very dangerous to approach and impossible to dock with. Magnetic tugs generate rotating magnetic fields that induce eddy currents in the target's conductive body, producing forces and torques at a safe distance.",
                        mechanism: "This can either stabilize the target for subsequent capture, or directly lower the orbit over time using magnetic braking. No mechanical attachment is needed, mitigating risk to equipment."
                    )
                }
            }
            
            Divider().cascadeDivider()
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("The 25-Year Guideline", systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(.white)
                    
                    Text("Given the worsening debris situation, the Inter-Agency Space Debris Coordination Committee (IADC) recommends since the early 2000s that all spacecraft in Low Earth Orbit be deorbited within 25 years of mission end. This means that, if a satellite's mission ends in 2030, it has until 2055 to deorbit or be moved into a safe graveyard orbit.\n\nIn the 2020s, however, a boom happened in the amount of satellite launches. Considering this, the U.S. Federal Communications Commission adopted a stricter rule: 5 years after end of life for U.S.-licensed satellites. However, while the FCC rule is enforced, compliance with the IADC guidelines remains voluntary for many operators worldwide.")
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
