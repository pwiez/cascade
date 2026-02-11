import SwiftUI

struct KnowledgeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kessler Syndrome")
                            .font(.system(size: 42, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                        
                        Text("It's less scary than this simulation, but still very worrisome!")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.gray.opacity(0.45))
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ImageSlot(imageName: "orbit_visual", caption: "Not-to-scale view of tracked orbital debris. By NASA image - NASA Orbital Debris Program Office.")
                    
                    ContentSection(title: "Where does the concept come from?") {
                        Text("In 1978, NASA scientist **Donald Kessler** proposed a terrifying scenario: a future where the density of objects in Low Earth Orbit (LEO) becomes so high that collisions between objects could cause a cascade.")
                        
                        Text("Each collision generates space debris that increases the likelihood of further collisions. One satellite breaks into thousands of pieces, each capable of destroying another satellite.")
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            StatCard(value: "27,000+", label: "Tracked Objects", icon: "binoculars.fill", color: .cyan)
                            StatCard(value: "17,500", label: "Speed (mph)", icon: "speedometer", color: .orange)
                            StatCard(value: "100M+", label: "Untracked Debris", icon: "circle.grid.3x3.fill", color: .red)
                        }
                        .padding(.horizontal)
                    }
                    
                    ContentSection(title: "Hypervelocity Impacts") {
                        Text("In orbit, objects travel at **17,500 mph** (7.8 km/s). At these speeds, even a paint fleck strikes with the force of a 550lb anvil dropped from 100 feet.")
                        
                        Text("A collision doesn't just damage a satellite; it completely atomizes it, turning a single functional unit into a shotgun blast of shrapnel.")
                    }
                    
                    ImageSlot(imageName: "impact_visual", caption: "Damage caused by a millimeter-sized debris impact on the Space Shuttle window.")
                    
                    ContentSection(title: "Avoiding The Cage") {
                        Text("If the Kessler Syndrome reaches a critical point, specific orbital ranges could become unusable for generations, trapping us on Earth and preventing space exploration.")
                        
                        Text("Current mitigation strategies include:")
                    }
                    
                    VStack(spacing: 12) {
                        FactRow(title: "Graveyard Orbits", desc: "Pushing dying satellites 300km above GEO to get them out of the way.")
                        FactRow(title: "Atmospheric Re-entry", desc: "Using remaining fuel to push LEO satellites down to burn up in the atmosphere.")
                        FactRow(title: "Active Debris Removal", desc: "Experimental missions (nets, harpoons, magnets) to capture large debris.")
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Simulation Constraints", systemImage: "macpro.gen3.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            CompromiseRow(
                                icon: "clock.arrow.2.circlepath",
                                title: "Time Dilation",
                                desc: "Orbits are calculated in real-time physics, but the simulation speed is accelerated (up to 5x) to make centuries of decay visible in seconds."
                            )
                            Divider().background(.gray.opacity(0.2))
                            CompromiseRow(
                                icon: "ruler.fill",
                                title: "Scale Factors",
                                desc: "In reality, space is mostly empty. To make satellites visible on an iPad screen, they are rendered ~1000x larger than reality. Hitboxes are adjusted accordingly."
                            )
                            Divider().background(.gray.opacity(0.2))
                            CompromiseRow(
                                icon: "cube.transparent",
                                title: "Spatial Hashing",
                                desc: "To maintain 60 FPS with 4,000 objects, the engine uses a spatial hash grid to perform collision checks only against nearby neighbors."
                            )
                        }
                        .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    Color.clear.frame(height: 50)
                }
            }
            .background(Color.black)
            .navigationTitle("Encyclopedia")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .font(.system(.body, design: .serif))
            .foregroundStyle(.gray)
            .lineSpacing(4)
        }
        .padding(.horizontal)
    }
}

struct ImageSlot: View {
    let imageName: String
    let caption: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text("Place Image Here")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text("\"\(imageName)\"")
                            .font(.caption2)
                            .monospaced()
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
                .frame(height: 220)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
        }
        .padding(16)
        .frame(width: 140, height: 110)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct FactRow: View {
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(.blue)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CompromiseRow: View {
    let icon: String, title: String, desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 24)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.primary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
    }
}
