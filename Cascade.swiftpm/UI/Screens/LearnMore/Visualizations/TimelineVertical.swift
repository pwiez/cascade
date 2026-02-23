//
//  TimelineVertical.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TimelineVertical: View {
    let events = [
        ("1957", "Sputnik 1", "The launch of the first artificial satellite marks the dawn of the Space Age and the first intentional 'dumping' of a rocket stage into orbit."),
        ("1969", "Space Age", "The race for space-related achievements in the 1960s prompts many launches without much care for debris-related safety, which starts the pollution of several important orbits."),
        ("1978", "The Kessler Hypothesis", "NASA's Donald Kessler publishes his landmark paper predicting that a high enough density of debris could trigger a self-sustaining 'collisional cascade.'"),
        ("1996", "Cerise Collision", "The first confirmed 'accidental' collision: the French Cerise satellite's gravity-gradient boom is severed by a fragment from an Ariane rocket body."),
        ("2007", "Fengyun-1C Test", "A Chinese kinetic anti-satellite weapon test destroys a weather satellite at 865km altitude, creating ~3,500 tracked debris, the single most destructive debris event in history."),
        ("2009", "Iridium-Cosmos Collision", "Two intact satellites (Iridium 33 and the defunct USSR Cosmos 2251) collide at 11.7 km/s, contaminating the heavily used 780km orbital shell with ~2,000 pieces of debris."),
        ("2021", "Cosmos 1408 (Nudol)", "A Russian ASAT test creates ~1,500 tracked fragments in a lower orbit. While most have already decayed by 2026, it forced immediate ISS sheltering procedures and highlighted the fragility of Low Earth Orbit once again."),
        ("2026", "The Modern Surge", "Active satellites now exceed 14,500, with over 35,000 objects >10cm tracked daily. Below that, there are estimates of approximately 1 million 'lethal' fragments (1–10cm) remain invisible to radar.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 10, height: 10)
                            .background(
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                            )
                        
                        if index != events.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.0)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.mutedText)
                        Text(event.1)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(event.2)
                            .font(.subheadline)
                            .foregroundStyle(CascadeTheme.bodyText)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}
