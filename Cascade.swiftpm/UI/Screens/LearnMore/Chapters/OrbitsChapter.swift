//
//  OrbitsChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 25/02/26.
//

import SwiftUI

struct OrbitsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Falling and Missing")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The most common misconception about space is that there is zero gravity. At the altitude of the International Space Station, Earth's gravity is still about 90% as strong as it is on the surface. So why do astronauts float?")
                
                TextParagraph("This may sound strange, but they float because they are in freefall! An orbit is simply a state of continuously falling, without ever actually hitting the ground. First, a satellite is launched high enough to escape the thickest parts of the atmosphere. Then, it is accelerated sideways to incredible speeds: around 27,000 km/h (16,700 mph).")
                
                KeyConceptBox(
                    title: "Sideways Speed",
                    bodyText: "Because the Earth is a sphere, its surface curves downward. If a satellite travels sideways fast enough, the Earth's surface curves away exactly as fast as the satellite falls toward it. This means that the satellite will keep falling, but it will keep missing the ground. If the satellite loses speed, its falling becomes faster than the Earth's curving, and it returns to Earth - in other words, it is deorbited.",
                    icon: "arrow.turn.down.right"
                )
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Orbital Regimes")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Different altitudes are useful for different purposes. The closer a satellite is to Earth, the faster it must travel to maintain its orbit. In Cascade, Low Earth Orbit is being represented.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("COMMON ORBITAL ALTITUDES", systemImage: "layer.fill.up")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CascadeTheme.dimText)
                        
                        VStack(spacing: 12) {
                            ModelParam(name: "Low Earth Orbit (LEO)", value: "160 – 2,000 km", detail: "Used by the ISS, Hubble, and many commercial satellites. Objects travel very fast here.")
                            Divider().cascadeDivider()
                            ModelParam(name: "Medium Earth Orbit (MEO)", value: "2,000 – 35,786 km", detail: "Used primarily for GPS and navigation constellations.")
                            Divider().cascadeDivider()
                            ModelParam(name: "Geosynchronous Orbit (GEO)", value: "35,786 km", detail: "Satellites at this range match the Earth's rotation speed. They stay fixed relative to the ground, appearing to hover in one spot. They travel much more slowly here than a satellite in LEO, but still very fast!")
                        }
                    }
                }
            }
        }
    }
}
