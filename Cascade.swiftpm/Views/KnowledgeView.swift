import SwiftUI
import TipKit

struct KnowledgeView: View {
    let mitigationTip = MitigationTip()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 40) {
                    
                    VStack(spacing: 16) {
                        Text("Kessler Syndrome")
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("A chain reaction where each collision generates debris that causes further collisions, potentially trapping us on Earth.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 600)
                    }
                    .padding(.top, 40)
                    

                    VStack(alignment: .leading, spacing: 48) {
                        
                        InfoSection(
                             title: "The Origin",
                             icon: "person.text.rectangle",
                             image: "orbit_visual",
                             imageCaption: "NASA simulation of orbital debris density."
                         ) {
                             Text("In 1978, NASA scientist **Donald Kessler** proposed a terrifying scenario: the density of objects in Low Earth Orbit (LEO) could become so high that collisions between objects would cause a cascade.")
                             Text("One satellite breaking apart creates thousands of shrapnel pieces. Each piece becomes a bullet, capable of destroying another satellite, which creates *more* bullets. This feedback loop could render orbit unusable for generations.")
                         }
                        
                         InfoSection(
                             title: "The Physics",
                             icon: "atom",
                             image: "impact_visual",
                             imageCaption: "Hypervelocity impact damage on a shuttle window."
                         ) {
                             Text("Objects in orbit travel at **17,500 mph** (7.8 km/s). At this speed, a paint fleck hits with the force of a 550lb anvil dropped from a building.")
                             Text("There is no 'fender bender' in space. Impacts vaporize the target, turning a functional machine into a cloud of high-speed shotgun pellets.")
                         }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Mitigation Strategies", icon: "shield.checkered")
                                .popoverTip(mitigationTip)
                            
                            VStack(spacing: 16) {
                                MitigationRow(
                                    title: "Graveyard Orbits",
                                    description: "Pushing dead satellites 300km further out, away from active lanes."
                                )
                                MitigationRow(
                                    title: "Controlled Re-entry",
                                    description: "Using remaining fuel to de-orbit satellites so they burn up in the atmosphere."
                                )
                                MitigationRow(
                                    title: "Active Removal",
                                    description: "Experimental missions using nets, harpoons, and lasers to capture debris."
                                )
                            }
                        }
                    }
                    .frame(maxWidth: 700)
                    .padding(.horizontal)
                    
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Learn More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    let image: String?
    let imageCaption: String?
    let content: Content
    
    init(title: String, icon: String, image: String? = nil, imageCaption: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.image = image
        self.imageCaption = imageCaption
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: title, icon: icon)
            
            if let imageName = image {
                AccessibleImage(name: imageName, caption: imageCaption)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .font(.body)
            .foregroundStyle(.primary)
            .lineSpacing(6)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .padding(.bottom, 8)
    }
}

struct AccessibleStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let a11yLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
    }
}

struct MitigationRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
                .padding(.top, 2)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct BulletPoint: View {
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessibleImage: View {
    let name: String
    let caption: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(caption ?? "Illustration")
            } else {
                ZStack {
                    Color(uiColor: .secondarySystemBackground)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 8)
    }
}
