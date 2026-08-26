//
//  OrbitPhysicsChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct OrbitPhysicsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {

            VStack(alignment: .leading, spacing: 24) {
                TextParagraph("The most common misconception about space is that there is zero gravity up there. At the altitude of the International Space Station, Earth's gravity is actually still about 90% as strong as it is on the surface. So why do astronauts float?")

                TextParagraph("This may sound strange, but they seem to float because they are falling! An orbit is simply a state of continuously falling, without ever actually hitting the ground. Spacecraft such as shuttles and satellites are launched high enough to escape the thickest parts of the atmosphere. Then, they are accelerated sideways, in a maneuver called circularization, to incredible speeds: an average of 30,000 km/h (18640 mph).")

                KeyConceptBox(
                    title: "Sideways Speed",
                    bodyText: "Because the Earth is a sphere, its surface curves downward. This means that if a satellite travels sideways fast enough, the Earth's surface curves away exactly as fast as the satellite falls toward it. If it loses speed, its falling becomes faster than the Earth's curving, and it returns to Earth - in other words, it is deorbited.",
                    icon: "arrow.turn.down.right"
                )
            }

            VStack(alignment: .leading, spacing: 24) {
                EditorialSectionHeader(title: "Orbital Regimes")

                TextParagraph("Different altitudes are useful for different purposes. Satellite population varies according to altitude ranges, and it is highest in Low Earth Orbit, precisely the one represented in the simulation.")

                ScientificCard {
                    VStack(alignment: .leading, spacing: 18) {
                        ModelParam(name: "Low Earth Orbit (LEO)", value: "160 – 2,000 km", detail: "Used by the ISS, Hubble, and many commercial satellites")
                        Divider().cascadeDivider()
                        ModelParam(name: "Medium Earth Orbit (MEO)", value: "2,000 – 35,786 km", detail: "Used primarily for GPS and navigation constellations")
                        Divider().cascadeDivider()
                        ModelParam(name: "Geosynchronous Orbit (GEO)", value: "35,786 km", detail: "Mostly used for telecommunications and weather monitoring")
                    }
                }

                TryThisBox(
                    instruction: "In the Settings panel, change the Orbit Altitude and tap Restart. Notice how satellites vary their speed to maintain their orbit."
                )
            }
        }
    }
}
