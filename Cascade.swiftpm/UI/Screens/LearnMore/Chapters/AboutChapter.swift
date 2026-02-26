import SwiftUI

struct AboutChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Simulation Architecture")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("Cascade runs a custom deterministic physics engine written in Swift. It uses Apple's RealityKit framework for rendering. Tracking thousands of objects at 60 frames per second requires heavy math optimizations and a few physics compromises.")
                
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
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                
                TextParagraph("A full-fidelity orbital simulation requires a supercomputer. To run smoothly on mobile hardware, Cascade makes several major physics compromises.")
                
                VStack(spacing: 20) {
                    SimplificationCard(
                        title: "Event Timescale",
                        icon: "timer",
                        description: "A Kessler Syndrome event happens blazingly fast in Cascade. In reality, it takes decades. Space is incredibly vast, and satellites are very small."
                    )
                    
                    SimplificationCard(
                        title: "Scaling",
                        icon: "square.resize.up",
                        description: "Cascade shrinks the Earth and enlarges the satellites so you can actually see them. If rendered to scale, space would look completely empty."
                    )
                    
                    SimplificationCard(
                        title: "No Debris-Debris Collisions",
                        icon: "bolt.slash.fill",
                        description: "The engine calculates satellite-on-satellite and satellite-on-debris impacts. Debris fragments do not collide with each other. Calculating those interactions would stall the engine."
                    )
                    
                    SimplificationCard(
                        title: "Representative Density",
                        icon: "square.grid.3x3.middle.filled",
                        description: "Mobile hardware cannot render 140 million fragments. Cascade uses a simplified representation. One visible piece of debris represents a cloud of thousands of real fragments."
                    )
                    
                    SimplificationCard(
                        title: "Idealized Gravity",
                        icon: "circle.dashed",
                        description: "Cascade treats Earth as a perfect sphere. In reality, Earth's equatorial bulge and uneven mass distribution cause gravitational anomalies. Cascade ignores these perturbations."
                    )
                    
                    SimplificationCard(
                        title: "No Atmospheric Drag",
                        icon: "wind",
                        description: "Cascade ignores atmospheric drag. Debris that achieves a stable orbit remains there forever unless it hits the Earth's surface."
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
