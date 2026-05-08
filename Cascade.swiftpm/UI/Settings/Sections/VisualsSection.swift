import SwiftUI

struct VisualsSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section {
            Toggle("Camera Control", isOn: $simulation.isCameraEnabled)
            Toggle("Debris Rotation", isOn: $simulation.debrisRotation)
            Toggle("Full Lighting", isOn: $simulation.useOmniLight)

            DisclosureGroup("Visibility") {
                Toggle("Show Earth", isOn: $simulation.showEarth)
                Toggle("Show Satellites", isOn: $simulation.showSatellites)
                Toggle("Show Debris", isOn: $simulation.showDebris)
                Toggle("Show Simulation Stats", isOn: $simulation.showStats)
            }

            DisclosureGroup("Colors & Scaling") {
                ColorPicker("Satellite Color", selection: $simulation.satelliteColor, supportsOpacity: false)
                ColorPicker("Debris Color", selection: $simulation.debrisColor, supportsOpacity: false)
                ColorPicker("Background Color", selection: $simulation.backgroundColor, supportsOpacity: false)

                SliderRow(
                    label: "Satellite Scale",
                    value: $simulation.satelliteScale,
                    range: 0.5...5.0,
                    format: "%.1fx"
                )

                if simulation.satelliteScale > (simulation.collisionRadius * 1.5) {
                    Label("Visual scale exceeds collision radius. Objects may overlap visually.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.bottom, 4)
                }

                SliderRow(
                    label: "Debris Scale",
                    value: $simulation.debrisScale,
                    range: 0.5...5.0,
                    format: "%.1fx"
                )
            }
        } header: {
            Text("Accessibility & Visuals")
        }
    }
}
