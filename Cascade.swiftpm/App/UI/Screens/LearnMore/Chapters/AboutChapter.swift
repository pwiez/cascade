//
//  AboutChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 14/02/26.
//

import SwiftUI

struct AboutChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {

            VStack(alignment: .leading, spacing: 24) {

                TextParagraph("Cascade runs a custom deterministic physics engine written in Swift 6. It uses Apple's RealityKit framework for rendering. Tracking many objects while keeping a smooth framerate requires some pretty heavy math optimizations and architectural choices:")

                ScientificCard {
                    VStack(alignment: .leading, spacing: 12) {
                            ModelParam(name: "Integrator", value: "Semi-Implicit Euler", detail: "Symplectic integration for stable orbits")
                            Divider().cascadeDivider()
                            ModelParam(name: "Collision Detection", value: "Spatial Hashing", detail: "Uniform grid partitioning strategy to reduce lookup speeds down from O(N^2)")
                            Divider().cascadeDivider()
                            ModelParam(name: "Parallelization", value: "Dynamic Load Balancing", detail: "Physics calculations are distributed across CPU cores progressively")
                            Divider().cascadeDivider()
                            ModelParam(name: "Accelerate Framework", value: "vDSP Vectorization", detail: "Leverages hardware-accelerated SIMD instructions for massive parallel array math")
                            Divider().cascadeDivider()
                            ModelParam(name: "Data Layout", value: "Structure of Arrays", detail: "Improves CPU cache utilization for fast, sequential memory access during gravity integration")
                            Divider().cascadeDivider()
                            ModelParam(name: "Debris Rendering", value: "Single-Mesh Batching", detail: "Thousands of fragments are merged into one dynamic mesh to eliminate RealityKit entity rendering overhead")
                            Divider().cascadeDivider()
                            ModelParam(name: "Concurrency", value: "Actor-Isolated Engine", detail: "Cascade runs the heavy physics calculations safely on background threads using Swift strict concurrency")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 24) {
                EditorialSectionHeader(title: "Compromises & Constraints")

                TextParagraph("A full-fidelity orbital simulation with all variables and proper scales requires an extremely expensive supercomputer, in particular to simulate such a complex event. So, in order to run smoothly and as accurately as possible, Cascade makes a few major physics compromises:")

                VStack(spacing: 20) {
                    IconCard(
                        title: "Event Timescale",
                        icon: "timer",
                        description: "A Kessler Syndrome event happens blazingly fast in Cascade, in a few seconds or minutes at most. In reality, it takes decades. Space is incredibly vast, the Earth is pretty big, and satellites are very small!"
                    )

                    IconCard(
                        title: "Scaling",
                        icon: "square.resize.up",
                        description: "Cascade shrinks the Earth and enlarges the satellites so you can actually see them. If rendered to scale, space would look completely empty and you would have to zoom in for a long time."
                    )

                    IconCard(
                        title: "No Debris-Debris Collisions",
                        icon: "bolt.slash.fill",
                        description: "The engine calculates satellite-on-satellite and satellite-on-debris impacts. Debris fragments do not collide with each other. As debris amounts grow, calculating those interactions would stall the CPU and destroy your battery life."
                    )

                    IconCard(
                        title: "Representative Density",
                        icon: "square.grid.3x3.middle.filled",
                        description: "Rendering over 140 million fragments is not feasible. Therefore, Cascade uses a simplified density representation. One visible piece of debris in the simulation represents a cloud of hundreds or thousands of real fragments, and each cube represents a few dozen real satellites."
                    )

                    IconCard(
                        title: "Idealized Gravity",
                        icon: "circle.dashed",
                        description: "Cascade treats Earth as a perfect sphere. In reality, Earth's mass distribution is very uneven, and its shape is jagged and rough. This causes gravitational anomalies, which can change orbits over time. These perturbations do not exist in the simulation."
                    )

                    IconCard(
                        title: "No Atmospheric Drag",
                        icon: "wind",
                        description: "To help with the visualization of collision events, Cascade ignores atmospheric drag to avoid debris deorbiting. Fragments that achieve a stable orbit remain there forever. However, if any of them hit the Earth's surface for any reason, such as excessive ejection force or low velocity, they are deleted from the simulation."
                    )

                }
            }

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cascade was designed and developed by")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Pedro Wiezel")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                    Link("pedrowiezel.com", destination: URL(string: "https://pedrowiezel.com")!)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.signal)
                        .padding(.top, 2)
                }

                Text("Made with ❤️ in SwiftUI and RealityKit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
