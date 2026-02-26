import SwiftUI

struct TimelineVertical: View {
    let events = [
            ("October 1957", "Sputnik 1", "The Soviet Union launches the first artificial satellite. They also leave the massive 7.5-ton R-7 core stage in orbit. It eventually burned up, but it was humanity's first piece of space junk."),
            
            ("June 1961", "Ablestar", "An Ablestar upper stage rocket explodes in orbit. This is the first known fragmentation event in space history. The explosion generates a few hundred trackable pieces of debris."),
            
            ("June 1978", "The Kessler Hypothesis", "NASA scientists Donald J. Kessler and Burton G. Cour-Palais publish their landmark paper on orbital collision frequencies."),
            
            ("July 1996", "Cerise Collision", "The first confirmed accidental collision between two cataloged objects. A briefcase-sized fragment from an old Ariane 1 rocket strikes the French military Cerise satellite at 15 km/s, tearing off its stabilization boom."),
            
            ("January 2007", "Fengyun-1C", "A Chinese anti-satellite weapon test intentionally destroys a defunct weather satellite. The impact creates thousands of trackable fragments in a single day."),
            
            ("February 2009", "Iridium-Kosmos Collision", "The first accidental collision between two intact satellites. An operational U.S. communications satellite and a defunct Russian military satellite collide at 11.7 km/s. The crash contaminates the 800km orbital shell with many trackable fragments."),
            
            ("November 2021", "Kosmos 1408", "A Russian weapon test destroys a defunct 2-ton Soviet-era intelligence satellite. The resulting debris cloud forced the ISS crew to take shelter in their return capsules for a while."),
            
            ("August 2024", "Long March 6A Breakup", "A Chinese upper stage rocket suffers an anomaly and breaks apart at 800 km altitude shortly after deploying 18 satellites. The event scatters hundreds of trackable fragments across a highly congested orbit.")
        ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        
                        Image(systemName: "pyramid.fill")
                            .foregroundStyle(.white)
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(event.0). \(event.1). \(event.2)")
            }
        }
    }
}
