//
//  RemediationChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            TextParagraph("Addressing orbital debris is a systems-level challenge requiring a three-pronged approach: prevent new debris generation through better design and operations, enforce responsible disposal of end-of-life spacecraft, and actively remove the highest-risk legacy objects before they fragment.")
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Natural Deorbit")
                
                Text("Our Greatest Ally: Atmospheric Drag")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Even at orbital altitudes, Earth's atmosphere does not end abruptly — it tapers off gradually. Residual gas molecules exert a faint but persistent drag force on orbiting objects. Over time, this drag lowers an object's altitude until it re-enters the atmosphere and burns up.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
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
                            .lineSpacing(CascadeTheme.compactLineSpacing)
                            .padding(.top, 4)
                    }
                }
                
                TextParagraph("Below approximately 600 km, atmospheric drag is effective enough to clear most debris within decades. This is why the International Space Station orbits at ~400 km — any debris generated at that altitude is naturally swept away relatively quickly. The challenge lies in higher orbits, where drag is negligible and debris persists for centuries.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Engineered Solutions")
                
                Text("Active Removal Technologies")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Where atmospheric drag alone is insufficient, engineered interventions are required. Several approaches are under development, each targeting different aspects of the debris problem.")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Drag Augmentation",
                        category: "Passive Deorbit",
                        icon: "wind",
                        accent: .green,
                        description: "Deployable drag sails or inflatable structures dramatically increase a spacecraft's cross-sectional area at end of life, accelerating orbital decay through atmospheric drag. These devices are lightweight and can be integrated into satellite design from the outset.",
                        mechanism: "By increasing the area-to-mass ratio, atmospheric drag forces multiply, reducing deorbit time from centuries to years — even at 700–800 km altitude. Several commercial systems are now flight-proven.",
                        maturity: "Flight-Proven",
                        maturityLevel: 0.8
                    )
                    
                    StrategyCard(
                        title: "Harpoon & Net Capture",
                        category: "Active Debris Removal",
                        icon: "lasso",
                        accent: .orange,
                        description: "A chaser spacecraft approaches a large defunct satellite or rocket body and secures it using a tethered harpoon or deployable net. Once captured, the combined system performs a controlled deorbit burn.",
                        mechanism: "The RemoveDEBRIS mission (2018) successfully demonstrated both net capture and harpoon penetration in orbit. ESA's ClearSpace-1, planned for 2026, aims to be the first full-scale removal mission.",
                        maturity: "Demonstrated",
                        maturityLevel: 0.55
                    )
                    
                    StrategyCard(
                        title: "Laser Ablation",
                        category: "Ground-Based Impulse",
                        icon: "dot.radiowaves.left.and.right",
                        accent: .purple,
                        description: "High-powered ground-based or orbital lasers target a debris object's surface, vaporizing a thin layer of material. The resulting gas jet acts as a miniature thruster, applying a small but precise impulse to the object.",
                        mechanism: "Repeated laser passes over days or weeks gradually lower the object's perigee until atmospheric drag completes the deorbit. No physical contact is required.",
                        maturity: "Experimental",
                        maturityLevel: 0.25
                    )
                    
                    StrategyCard(
                        title: "Magnetic Eddy-Current Tugs",
                        category: "Contactless Interaction",
                        icon: "magnet",
                        accent: .blue,
                        description: "Tumbling debris objects are dangerous to approach and impossible to dock with. Magnetic tugs generate rotating magnetic fields that induce eddy currents in the target's conductive body, producing forces and torques at a safe standoff distance.",
                        mechanism: "Contactless detumbling stabilizes the target for subsequent capture, or sustained magnetic braking can directly lower the orbit over time. No mechanical attachment is needed.",
                        maturity: "Research",
                        maturityLevel: 0.15
                    )
                }
            }
            
            Divider().cascadeDivider()
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("The 25-Year Guideline", systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(.white)
                    
                    Text("The Inter-Agency Space Debris Coordination Committee (IADC) recommends that all LEO spacecraft be deorbited within 25 years of mission end. In 2022, the U.S. Federal Communications Commission adopted a stricter 5-year rule for U.S.-licensed satellites. Compliance remains voluntary for many operators worldwide.")
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
    let category: String
    let icon: String
    let accent: Color
    let description: String
    let mechanism: String
    var maturity: String = ""
    var maturityLevel: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .tracking(0.6)
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                ThemedIcon(systemName: icon, color: accent, shape: .circle)
            }
            
            if !maturity.isEmpty {
                HStack(spacing: 10) {
                    Text("Readiness")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CascadeTheme.mutedText)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(CascadeTheme.trackColor)
                            Capsule()
                                .fill(accent.opacity(0.7))
                                .frame(width: geo.size.width * maturityLevel)
                        }
                    }
                    .frame(height: CascadeTheme.trackHeight)
                    .clipShape(Capsule())
                    
                    Text(maturity)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                }
                .accessibilityLabel("Technology readiness: \(maturity)")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text(description)
                    .font(.body)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption)
                        .foregroundStyle(accent.opacity(0.8))
                        .padding(.top, 4)
                    
                    Text(mechanism)
                        .font(.callout)
                        .foregroundStyle(CascadeTheme.bodyText)
                        .lineSpacing(CascadeTheme.bodyLineSpacing)
                }
                .cascadeInnerCard(accent: accent)
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