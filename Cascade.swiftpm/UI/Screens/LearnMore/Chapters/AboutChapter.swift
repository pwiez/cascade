import SwiftUI

struct AboutChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("Simulation Architecture")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Cascade runs a custom deterministic physics engine written fully in Swift, and it utilizes Apple's RealityKit framework to render everything: light, the Earth, and the objects. To maintain the flow of calculations running smoothly while tracking hundreds to thousands of objects, the engine uses several math optimizations and makes some significant physics concessions.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Specifications", systemImage: "cpu.fill")
                            .font(.headline).foregroundStyle(.white)
                        
                        VStack(spacing: 12) {
                            ModelParam(name: "Integrator", value: "Semi-Implicit Euler", detail: "Symplectic integration for stable orbits")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Collision Detection", value: "Spatial Hashing", detail: "Uniform grid partitioning strategy to reduce lookup speeds")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Parallelization", value: "Dynamic Load Balancing", detail: "Physics calculations distributed across CPU cores progressively")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Accelerate", value: "vDSP Vectorization", detail: "Leverages hardware-accelerated SIMD instructions for massive parallel array math")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Data Layout", value: "Structure of Arrays (SoA)", detail: "Improves CPU cache utilization for fast, sequential memory access during gravity integration")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Debris Rendering", value: "Single-Mesh Batching", detail: "Combines thousands of fragments into one dynamic mesh to eliminate RealityKit entity overhead")
                            
                            Divider().cascadeDivider()
                            
                            ModelParam(name: "Concurrency", value: "Actor-Isolated Engine", detail: "Runs heavy physics calculations safely on background threads using Swift strict concurrency")
                        }
                    }
                }
            }
            
            Divider().cascadeDivider()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Compromises & Constraints")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("A full-fidelity orbital simulation requires supercomputers. In order to run smoothly, Cascade makes a few major physics compromises:")
                
                VStack(spacing: 20) {
                    SimplificationCard(
                        title: "Event Timescale",
                        icon: "timer",
                        description: "A Kessler Syndrome event happens blazingly fast in Cascade - within seconds, or minutes at most. This is intentional, to make the event more easy to visualize. In real life, this takes years or decades, mostly due to how small spacecraft and satellites are and how insanely big space is."
                    )
                    
                    SimplificationCard(
                        title: "Scaling",
                        icon: "square.resize.up",
                        description: "In Cascade, Earth's size is drastically reduced and object sizes are drastically increased, to make it possible for you to visualize the effect. In reality, if you were to view Earth from afar, you would see just Earth, really. Space looks incredibly peaceful because debris and satellites are incredibly small in the grand scale of things. Looks are deceiving!"
                    )
                    
                    SimplificationCard(
                        title: "No Debris-Debris Collisions",
                        icon: "bolt.slash.fill",
                        description: "The simulation calculates sat-on-sat and sat-on-debris impacts. However, debris fragments do not collide with each other. Calculations for interactions between thousands of debris particles would grow exponentially, stalling the engine and freezing the app. Besides, they are not strictly necessary for visualization."
                    )
                    
                    SimplificationCard(
                        title: "Representative Density",
                        icon: "square.grid.3x3.middle.filled",
                        description: "It is impossible to render 100+ million fragments in orbit. Instead, Cascade uses a simplified representation: one visible piece of debris in the simulation represents a cloud of hundreds or thousands of fragments."
                    )
                    
                    SimplificationCard(
                        title: "Idealized Gravity",
                        icon: "circle.dashed",
                        description: "In this simulation, Earth is a perfect sphere. In reality, it is full of surface imperfections and points which are higher or lower than others. This causes gravitational disturbances according to the point of Earth's surface you're directly above. Cascade omits these disturbances. Gravity behaves the exact same in every point of every orbit."
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
