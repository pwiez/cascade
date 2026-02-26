import SwiftUI

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            TextParagraph("The picture painted so far is pretty grim, but orbital debris is a challenge that can be dealt with. Fundamentally, it is a systems-level challenge requiring a three-pronged approach: prevent new debris generation through better design and operations, enforce responsible disposal of end-of-life spacecraft, and actively remove the highest-risk legacy and defunct objects before they have a chance to create more debris.")
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Atmospheric Drag")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("This is our main ally. Even at orbital altitudes, did you know Earth's atmosphere does not just end? It tapers off gradually, eventually ending very, very high up in space. Even though they're few and far between, residual gas molecules at high altitudes exert a persistent, albeit faint, drag force on orbiting objects. Over time, this drag lowers an object's altitude until it re-enters the atmosphere and burns up. The time this takes depends directly on the altitude and size of the object.")
                
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
                
                TextParagraph("Below approximately 600 km, atmospheric drag is effective enough to clear most debris within a few decades. This is why the International Space Station orbits at ~400 km — even if disaster struck and it got destroyed, debris generated at that altitude is naturally swept away relatively quickly. The challenge lies in higher orbits, where drag is negligible and debris persists for centuries.")
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Active Removal Technologies")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Based on what you learned from this and the previous chapters, you know that atmospheric drag alone is powerful, but largely insufficient. Therefore, engineered interventions are required for objects in higher orbits. Several approaches are under development, each targeting different aspects of the debris problem. Even though the ideas look like they're coming straight out of science fiction, they're actually very real and are being seriously studied and considered. There have been a lot of advancements in proposed technologies, some tests have already been successful, and more are planned in coming years!")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Drag Augmentation",
                        icon: "wind",
                        description: "Deployable drag sails or inflatable structures dramatically increase a satellite or spacecraft's cross-sectional area, which increases its susceptibility to drag forces. At the end of the operational life of the craft, these devices can be deployed, accelerating orbital decay through atmospheric drag. Drag sails are lightweight and can be integrated into satellite and craft design fairly easily in the design stage. This makes them a very cost-effective solution, because it's a way to tackle the problem without requiring costly manual intervention later on.",
                        mechanism: "By increasing the area-to-mass ratio, atmospheric drag forces multiply, reducing deorbit time considerably even at higher altitudes."
                    )
                    
                    StrategyCard(
                        title: "Harpoons & Nets",
                        icon: "lasso",
                        description: "A specialized chaser spacecraft approaches a large defunct satellite or rocket body, or another type of large debris, and secures it using a tethered harpoon or deployable net. Once it's captured, the spacecraft performs a controlled burn that deorbits the captured object.",
                        mechanism: "The RemoveDEBRIS mission (2018) successfully demonstrated both net capture and harpoon penetration in orbit. It was also supposed to demonstrate the use of drag sails, but they failed to deploy. ESA's ClearSpace-1 mission, planned to launch in 2029, aims to be the first full-scale removal operation. The goal of ClearSpace-1 is to deorbit the ESA's own PROBA-1 satellite, which weighs 95kg and was launched all the way back in 2001."
                    )
                    
                    StrategyCard(
                        title: "Laser Ablation",
                        icon: "dot.radiowaves.left.and.right",
                        description: "Ground-based or orbital lasers target a debris object's surface. The laser's focused energy is so powerful that it vaporizes a small amount of material. The vaporized material has so much energy that it is ejected, creating a small gas jet that acts as a miniature thruster. Thanks to Newton's third law (for every action, there's an equal reaction), a small but very precise impulse is applied to the debris itself.",
                        mechanism: "Repeated laser passes over days or weeks can gradually slow down the object until atmospheric drag can finish the job faster. No craft launches are required, and resource-wise this is a fairly efficient solution."
                    )
                    
                    StrategyCard(
                        title: "Magnetic Stabilization & Braking",
                        icon: "gyroscope",
                        description: "Tumbling debris objects are very dangerous to approach and impossible to dock a spacecraft with. Magnetic tugs in space can generate rotating magnetic fields that induce eddy currents in the target's conductive parts, producing forces and torques at a safe distance.",
                        mechanism: "The created forces can either stabilize the target for subsequent capture, or directly lower the speed of the debris over time through magnetic braking. No mechanical attachment is needed, mitigating risk to equipment. This strategy is still highly experimental and under research."
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
