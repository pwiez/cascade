import SwiftUI

struct AboutChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Simulation Architecture")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Cascade runs a custom deterministic physics engine written in Swift. To maintain a stable framerate on your device while tracking from hundreds to thousands of objects, the engine uses several math optimizations and makes some significant physics concessions.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Engine Specs", systemImage: "cpu.fill")
                            .font(.headline).foregroundStyle(.white)
                        
                        VStack(spacing: 12) {
                            ModelParam(name: "Integrator", value: "Semi-Implicit Euler", detail: "Symplectic integration for stable orbits")
                            Divider().cascadeDivider()
                            ModelParam(name: "Collision Detection", value: "Spatial Hashing", detail: "O(n) lookup via uniform grid partition")
                            Divider().cascadeDivider()
                            ModelParam(name: "Parallelization", value: "Multithreaded", detail: "Physics logic distributed across CPU cores")
                            Divider().cascadeDivider()
                            ModelParam(name: "Rendering", value: "RealityKit", detail: "Instanced mesh particles for debris clouds")
                        }
                    }
                }
            }
            
            Divider().cascadeDivider()
            
            
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Compromises & Constraints")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("A full-fidelity orbital simulation requires supercomputers. To run smoothly on your device, Cascade makes a few major physics compromises:")
                
                VStack(spacing: 20) {
                    SimplificationCard(
                        title: "No Debris-Debris Collisions",
                        icon: "bolt.slash.fill",
                        description: "The simulation calculates Satellite-vs-Satellite and Satellite-vs-Debris impacts. However, debris fragments do not collide with each other. Calculations for interactions between thousands of debris particles would grow exponentially, stalling the engine and freezing Cascade."
                    )
                    
                    SimplificationCard(
                        title: "Representative Density",
                        icon: "square.grid.3x3.middle.filled",
                        description: "It is impossible to render 100+ million fragments in orbit. Instead, Cascade uses 'representative debris': one visible debris in the simulation represents a dense cloud of thousands of fragments."
                    )
                    
                    SimplificationCard(
                        title: "Idealized Gravity",
                        icon: "circle.dashed",
                        description: "The simulation treats Earth as a perfect sphere. It omits gravitational disturbances caused Earth's equatorial bulge. Gravity behaves the exact same in every point of every orbit."
                    )
                    
                    SimplificationCard(
                        title: "Scaling",
                        icon: "square.resize.up",
                        description: "In Cascade, Earth's size is drastically reduced and satellites / debris sizes are drastically increased, to make it possible for you to visualize Kessler Syndrome. In reality, if you were to view Earth from afar, you would see...nothing - just Earth. Space looks incredibly peaceful because debris and satellites are incredibly small in the grand scale of things. Looks are deceiving!"
                    )
                    
                    SimplificationCard(
                        title: "No Atmospheric Drag",
                        icon: "wind",
                        description: "Cascade does not account for atmospheric drag at orbital altitudes - which, as you learned in previous chapters, is essential for deorbiting debris over the years. In the simulation, debris that achieves a stable orbital path remains in orbit forever. However, if debris does come into contact with Earth by any means, it is deleted from the simulation."
                    )
                }
            }
        }
    }
}

struct SimplificationCard: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ThemedIcon(systemName: icon, color: .orange, isCircle: true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.bodyLineSpacing)
            }
        }
        .padding(CascadeTheme.compactPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CascadeTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
        )
    }
}

struct ModelParam: View {
    let name: String
    let value: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CascadeTheme.mutedText)
            }
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.cyan)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LearningObjective: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.green)
                .padding(.top, 1)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(CascadeTheme.bodyText)
                .lineSpacing(3)
        }
        .accessibilityElement(children: .combine)
    }
}
