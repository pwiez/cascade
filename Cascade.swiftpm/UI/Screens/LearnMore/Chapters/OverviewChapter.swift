//
//  OverviewChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct OverviewChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            
            DefinitionCallout(
                term: "Kessler Syndrome",
                definition: "A theoretical scenario proposed by NASA scientist Donald J. Kessler in 1978, in which the density of objects in Low Earth Orbit becomes high enough that collisions between objects generate sufficient debris to trigger a self-sustaining cascade of further collisions. Each impact produces hundreds or thousands of new fragments, each capable of destroying another object.",
                source: "Kessler & Cour-Palais, Journal of Geophysical Research, 1978"
            )
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Why is learning about this important?", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("Global navigation, weather forecasting, climate observation, telecommunications, and disaster early-warning systems all depend on unimpeded access to many orbital ranges, including Low Earth Orbit, represented in this simulation. If collision rates cross a critical threshold, entire orbital shells could become unusable for generations — not because of a single collision, but because of a series of slow, compounding accumulation of debris.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(CascadeTheme.bodyLineSpacing)
                }
            }
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("How to Use This Explainer", systemImage: "book.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        GuideRow(number: "1", text: "**The Mechanics** — Understand the physics: why collisions at orbital velocity are so destructive, and how one event triggers the next.")
                        GuideRow(number: "2", text: "**The Situation** — Review the historical timeline and current state of orbital debris, supported by tracking data.")
                        GuideRow(number: "3", text: "**Remediation** — Explore the engineering strategies being developed to slow, halt, or reverse debris growth.")
                    }
                }
            }
        }
    }
}
