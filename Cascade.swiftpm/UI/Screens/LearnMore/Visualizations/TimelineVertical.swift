//
//  TimelineVertical.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TimelineVertical: View {
    let events = [
        ("1957", "Sputnik 1", "The first artificial satellite launch marks the beginning of orbital debris accumulation."),
        ("1978", "The Kessler Hypothesis", "Donald Kessler (NASA) publishes 'Collision Frequency of Artificial Satellites', predicting the cascade effect."),
        ("1996", "Cerise Collision", "First verified collision between an active satellite and debris (from an Ariane rocket body)."),
        ("2007", "Fengyun-1C Test", "China conducts an anti-satellite missile test, instantly adding ~3,500 trackable fragments."),
        ("2009", "Iridium vs Cosmos", "First major hypervelocity collision between two intact satellites (active Iridium 33 and defunct Cosmos 2251)."),
        ("2021", "Nudol Test", "Russian ASAT test destroys Cosmos 1408, creating a debris cloud requiring ISS avoidance maneuvers."),
        ("2024", "Current Status", "Over 32,000 objects >10cm are now tracked, with millions of smaller, untrackable lethal fragments.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == 0 ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                            .background(
                                Circle()
                                    .fill(index == 0 ? Color.blue.opacity(0.3) : Color.clear)
                                    .frame(width: 20, height: 20)
                            )
                        
                        if index != events.count - 1 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.0)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(index == 0 ? .blue : CascadeTheme.mutedText)
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