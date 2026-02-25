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
                definition: "A theoretical scenario proposed by NASA scientists Donald J. Kessler and Burton G. Cour-Palais in 1978, in which the density of objects in Low Earth Orbit becomes high enough that collisions between objects generate sufficient debris to trigger a self-sustaining cascade of further collisions. Each impact produces hundreds or thousands of new fragments, each capable of destroying another object.",
                source: "Kessler & Cour-Palais, Journal of Geophysical Research, vol. 83, issue A6, 1978"
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
            
            VStack(alignment: .leading, spacing: 24) {
                Text("What Cascade can teach you")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    LearningObjective(text: "Understand why collision cascades are self-reinforcing above a critical density threshold")
                    LearningObjective(text: "Appreciate the role of orbital velocity in making even small debris lethal to other satellites")
                    LearningObjective(text: "Visualize how debris spreads from a single point of impact into a planetary ring over time")
                    LearningObjective(text: "Recognize that orbital space is a finite resource requiring active stewardship")
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
