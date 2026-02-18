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
            Text("A self-reinforcing chain reaction in orbit — where every collision breeds the seeds of the next.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            DefinitionCallout(
                term: "Kessler Syndrome",
                definition: "A theoretical scenario proposed by NASA scientist Donald J. Kessler in 1978, in which the density of objects in Low Earth Orbit becomes high enough that collisions between objects generate sufficient debris to trigger a self-sustaining cascade of further collisions. Each impact produces hundreds or thousands of new fragments, each capable of destroying another object.",
                source: "Kessler & Cour-Palais, Journal of Geophysical Research, 1978"
            )
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Why This Matters", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("Global navigation, weather forecasting, climate observation, telecommunications, and disaster early-warning systems all depend on unimpeded access to Low Earth Orbit. If collision rates cross a critical threshold, entire orbital shells could become unusable for generations — not because of a single catastrophe, but because of a slow, compounding accumulation of debris.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
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