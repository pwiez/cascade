//
//  TimelineVertical.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TimelineVertical: View {
    let events = [
        ("1957", "Sputnik 1", "The first artificial satellite launched by humanity marks the beginning of orbital debris accumulation, setting a precedent for space dumping."),
            ("1978", "The Kessler Hypothesis", "Donald Kessler (NASA) publishes 'Collision Frequency of Artificial Satellites', predicting how a runaway collisional cascade effect could happen in coming decades."),
            ("1996", "Cerise Collision", "First verified collision between an active satellite and debris (from an Ariane rocket body), officially disproving the 'Big Sky' theory."),
            ("2007", "Fengyun-1C Test", "China conducts a kinetic anti-satellite missile test, instantly adding ~3,500 trackable fragments and creating the largest debris cloud in history."),
            ("2009", "Iridium vs Cosmos", "First major hypervelocity collision between two intact satellites (active Iridium 33 and defunct Cosmos 2251), heavily contaminating a busy orbital corridor."),
            ("2021", "Nudol Test", "Russian ASAT test destroys Cosmos 1408, creating a dangerous debris cloud requiring urgent ISS avoidance maneuvers and crew sheltering."),
            ("2026", "Current Status", "Over 32,000 objects >10cm are now actively tracked, alongside an estimated 130 million smaller, untrackable lethal fragments moving at hypervelocity.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                            .background(
                                Circle()
                                    .fill(Color.clear)
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
