import SwiftUI

struct TimelineVertical: View {
    let events = [
        ("October 1957", "Sputnik 1", "The Soviet Union launches humanity's first artificial satellite, marking the dawn of the space age. However, the launch also leaves behind the massive 7.5-ton R-7 Semyorka core stage in orbit. While it eventually burned up in the atmosphere, this rocket body holds the notoriety of being humanity's first significant piece of space debris."),
        
        ("June 1961", "Ablestar", "An Ablestar upper stage rocket suffers a propellant leak and violently explodes in orbit shortly after delivering a satellite. This marks the first known fragmentation event in space history. The explosion generates hundreds of trackable metal fragments, demonstrating for the first time that dead rocket bodies act as orbiting bombs long after their missions end."),
        
        ("June 1978", "The Kessler Hypothesis", "NASA scientists Donald J. Kessler and Burton G. Cour-Palais publish their landmark paper on orbital collision frequencies. This paper fundamentally changes how the world views the matters of space safety and pollution."),
        
        ("July 1996", "Cerise Collision", "The space industry records its first confirmed accidental collision between two cataloged objects. A briefcase-sized fragment from an exploded Ariane 1 rocket strikes the French military Cerise satellite at a blistering speed of 15 km/s. The hypervelocity impact completely tears off the satellite's stabilization boom."),
        
        ("January 2007", "Fengyun-1C", "A Chinese anti-satellite (ASAT) weapon test intentionally destroys a defunct weather satellite at an altitude of 865 kilometers. The high-speed kinetic impact instantly creates thousands of trackable fragments and millions of microscopic pieces."),
        
        ("February 2009", "Iridium-Kosmos Collision", "The first accidental, high-speed collision between two intact satellites occurs. An operational U.S. communications satellite and a heavy, defunct Russian military satellite smash into each other at 11.7 km/s. The crash completely obliterates both spacecraft and contaminates the highly useful 800-kilometer orbital shell with thousands of jagged fragments."),
        
        ("November 2021", "Kosmos 1408", "A Russian ASAT test targets and destroys a defunct, two-ton Soviet-era military intelligence satellite. The resulting massive debris cloud crosses the orbital path of the International Space Station. The threat of conjunction forces the ISS crew to put on their spacesuits and take emergency shelter in their return capsules for several hours."),
        
        ("August 2024", "Long March 6A Breakup", "A Chinese upper stage rocket suffers an anomaly and violently breaks apart shortly after deploying an 18-satellite constellation. The event scatters hundreds of trackable fragments across an 800-kilometer altitude. Because this altitude is already heavily congested with modern mega-constellations, the breakup immediately triggers a wave of collision avoidance maneuvers for active satellites.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        
                        Image(systemName: "pyramid.fill")
                            .foregroundStyle(.primary)
                            .frame(width: 10, height: 10)
                        
                        if index != events.count - 1 {
                            Rectangle()
                                .fill(DesignTokens.dividerColor)
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.0)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.mutedText)
                        Text(event.1)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(event.2)
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.bodyText)
                            .padding(.bottom, 30)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(event.0). \(event.1). \(event.2)")
            }
        }
    }
}
