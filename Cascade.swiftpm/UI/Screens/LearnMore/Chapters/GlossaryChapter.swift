//
//  GlossaryChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 25/02/26.
//

import SwiftUI

struct GlossaryChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            
            TextParagraph("A quick reference guide for the technical terminology used throughout the simulation and the chapters.")
            
            VStack(alignment: .leading, spacing: 28) {
                GlossaryItem(
                    term: "Ablation",
                    definition: "The removal of material from the surface of an object by vaporization, chipping, or other erosive processes. In debris remediation, lasers can ablate a debris surface to act as a thruster.",
                )
                
                GlossaryItem(
                    term: "Conjunction",
                    definition: "A close approach between two objects in space. Space agencies track these events to determine if an avoidance maneuver is necessary.",
                )
                
                GlossaryItem(
                    term: "Kinetic Energy",
                    definition: "The energy an object possesses due to its motion. It increases exponentially with velocity, making small orbital debris highly destructive.",
                )
            }
        }
    }
}
