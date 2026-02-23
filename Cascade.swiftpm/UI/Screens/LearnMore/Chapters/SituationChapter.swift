//
//  SituationChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct SituationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Timeline of Key Events")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The accumulation of orbital debris is not a recent phenomenon — it has been building since the dawn of the space age. Several pivotal events injected massive debris populations into heavily used orbital regions, each one demonstrating the fragility of the orbital commons.")
                
                TimelineVertical()
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Current Orbital Population")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks — primarily the U.S. Space Surveillance Network and ESA's Space Debris Office — continuously track objects larger than 10 cm in Low Earth Orbit. The cataloged population has grown dramatically, with sharp inflections corresponding to fragmentation events.")
                
                ScientificCard { DebrisChart() }
                
                TextParagraph("Note the steep increase after 2007 (Fengyun-1C ASAT test) and 2009 (Iridium-Cosmos collision). These two events alone contributed over 5,000 trackable fragments to the catalog — more than decades of accumulated launch debris.")
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("What This Means in Practice")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The growing debris population has measurable consequences for active missions. Collision avoidance maneuvers are becoming routine, consuming propellant and reducing mission lifetime.")
                
                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "~50",
                        unit: "/ year",
                        label: "ISS Avoidance Maneuvers",
                        icon: "arrow.triangle.turn.up.right.diamond.fill",
                        accent: .cyan
                    )
                    OperationalStatCard(
                        value: "4×",
                        unit: "increase",
                        label: "Conjunction Alerts Since 2010",
                        icon: "bell.badge.fill",
                        accent: .orange
                    )
                }
                
                KeyConceptBox(
                    title: "Conjunction Assessment",
                    bodyText: "Every tracked object's trajectory is projected forward and compared against all others. When the predicted miss distance falls below a threshold (typically a few hundred meters), operators must decide whether to execute an avoidance maneuver — consuming irreplaceable fuel and interrupting mission operations.",
                    icon: "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
        }
    }
}

struct OperationalStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CascadeTheme.mutedText)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(CascadeTheme.mutedText)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CascadeTheme.compactPadding)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(accent.opacity(CascadeTheme.accentBorderOpacity), lineWidth: CascadeTheme.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit): \(label)")
    }
}
