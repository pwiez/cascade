//
//  MechanicsChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 15/02/26.
//

import SwiftUI

struct MechanicsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {

            VStack(alignment: .leading, spacing: 24) {

                TextParagraph("Kessler Syndrome is not a single event, and it also doesn't happen nearly as fast as it does in this simulation. It is a slow, self-reinforcing chain reaction that can take decades to reach criticality. We have been building up to it for 60 years however, and in recent years things have been ramping up.")

                CausalFlowDiagram()

                TryThisBox(
                    instruction: "Go to the Settings panel and increase the Debris Ejection Force parameter, then blow up some satellites. Notice how the higher kinetic force causes the debris cloud to spread much faster across different orbital planes, escape orbit, or even crash on Earth!"
                )
            }

            VStack(alignment: .leading, spacing: 24) {
                EditorialSectionHeader(title: "Orbital Energy")

                TextParagraph("Orbital collisions are catastrophic mostly because of speed. Objects in Low Earth Orbit travel at about 8.3 kilometers every second. At those speeds, everything becomes extremely dangerous: very small metal shards, loose bolts, frozen liquids, and even paint flecks gain massive amounts of kinetic energy.")

                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The Kinetic Energy Equation")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DesignTokens.dimText)

                        HStack(spacing: 6) {
                            Text("E")
                                .foregroundStyle(.green)
                            Text("=")
                                .foregroundStyle(.primary.opacity(0.5))
                            Text("½")
                                .foregroundStyle(.primary.opacity(0.8))
                            Text("m")
                                .foregroundStyle(.blue)
                            Text("v²")
                                .foregroundStyle(.orange)
                                .padding(.leading, -2)
                        }
                        .font(.largeTitle.weight(.semibold))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Kinetic energy equals one half times mass times velocity squared.")

                        Text("\(Text("Energy").foregroundStyle(.green)) scales with the **square** of \(Text("velocity").foregroundStyle(.orange)). This means that doubling the speed of impact quadruples the \(Text("destructive power").foregroundStyle(.green)). It's important to note that the \(Text("mass").foregroundStyle(.blue)) of the object is relevant too, but speed is what matters most for kinetic energy. If a 10-ton piece of metal touches a craft very, very slowly, perhaps not much will happen. However, if a hand-sized piece of metal hits it at 9 kilometers per second, things will get serious.")
                            .font(.body)
                            .foregroundStyle(DesignTokens.bodyText)
                            .lineSpacing(DesignTokens.bodyLineSpacing)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 24) {
                EditorialSectionHeader(title: "Invisible Missiles")

                TextParagraph("Space surveillance networks reliably track objects larger than 10 cm. However, fragments between 1 mm and 10 cm represent the most dangerous population. They are too small to track reliably, but large enough to destroy a satellite.\n\nIt is estimated there are millions upon millions of the smaller ones in orbit right now.")

                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "~14,500",
                        unit: "satellites",
                        label: "active as of 2026",
                        accent: .blue
                    )

                    OperationalStatCard(
                        value: "> 55,000",
                        unit: "objects",
                        label: "tracked in orbit by surveillance networks",
                        accent: .yellow
                    )
                }

                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "1.2 million+",
                        unit: "non-tracked objects",
                        label: "from 1-10cm estimated to be in orbit",
                        accent: .orange
                    )
                    OperationalStatCard(
                        value: "140 million+",
                        unit: "non-tracked objects",
                        label: "from 1mm to 1cm estimated to be in orbit",
                        accent: .red
                    )
                }
            }
        }
    }
}
