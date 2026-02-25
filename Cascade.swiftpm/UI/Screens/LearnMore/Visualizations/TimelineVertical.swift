//
//  TimelineVertical.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TimelineVertical: View {
    let events = [
            ("October 1957", "Sputnik 1", "The Soviet Union launches the first artificial satellite, marking the dawn of the Space Age. Alongside the 83 kg satellite, the massive 7.5-ton R-7 Semyorka core rocket stage is left in orbit. It eventually reentered the atmosphere and was destroyed, but remains iconic as one of humanity's very first pieces of space debris."),
            
            ("June 1961", "Ablestar", "An Ablestar upper stage rocket, used to launch the U.S. Transit 4A satellite, suffers an anomalous explosion in orbit. This marks the first known fragmentation event in space history, instantly generating nearly 300 trackable pieces of debris and highlighting the dangers of leftover propellant."),
            
            ("June 1978", "The Kessler Hypothesis", "NASA scientists Donald J. Kessler and Burton G. Cour-Palais publish a landmark paper modeling collision frequencies in Low Earth Orbit. They predict that as satellite density increases, random collisions could trigger a self-sustaining cascade of debris, creating a barrier to future launches and craft survivability. This fundamentally changed views on orbit safety and the pollution of space."),
            
            ("July 1996", "Cerise Collision", "In the first confirmed accidental collision involving two cataloged objects, a briefcase-sized fragment from an Ariane 1 rocket stage (which had exploded in 1986) strikes the French Cerise military satellite at nearly 15 km/s, hitting its 6-meter stabilization boom."),
            
            ("January 2007", "Fengyun-1C", "A Chinese kinetic anti-satellite weapon test intentionally destroys Fengyun-1C, a 750 kg defunct weather satellite, at an altitude of 865 km. The violent hypervelocity impact creates over 3,500 trackable fragments."),
            
            ("February 2009", "Iridium-Kosmos Collision", "In the very first accidental hypervelocity collision between two intact satellites, the operational U.S. communications satellite Iridium 33 and the defunct 900 kg Russian military satellite Kosmos-2251 collide at 11.7 km/s. The disaster severely contaminates the heavily utilized 780 km orbital shell with over 2,000 trackable fragments."),
            
            ("November 2021", "Kosmos 1408", "A Russian anti-satellite weapon test destroys Kosmos 1408, a defunct USSR intelligence satellite launched in 1982 that weighed 2 tons. The trajectory of the debris initially indicated a conjunction risk with the ISS, forcing its crew to standby for evacuation procedures."),
            
            ("August 2024", "Long March 6A Breakup", "A Chinese Long March 6A upper stage rocket breaks apart at an altitude of 800 km shortly after deploying 18 broadband satellites. The fragmentation event creates hundreds of trackable pieces of debris in a highly congested region."),
        ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        
                        Image(systemName: "pyramid.fill")
                            .frame(width: 10, height: 10)
                        
                        if index != events.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 8)
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
