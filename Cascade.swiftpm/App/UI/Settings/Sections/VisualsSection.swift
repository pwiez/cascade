import CascadeEngine
import SwiftUI

struct VisualsSection: View {
    @Bindable var simulation: Simulation

    /// Warns when a satellite is drawn larger than the volume it actually
    /// collides in, which makes near-misses look like hits.
    private var scaleExceedsHitbox: Bool {
        simulation.settings.satelliteScale > simulation.settings.collisionRadius * 1.5
    }

    var body: some View {
        Section("Visuals") {
            Toggle("Camera Control", isOn: $simulation.isCameraEnabled)
            Toggle("Debris Rotation", isOn: $simulation.settings.debrisRotation)
            Toggle("Full Lighting", isOn: $simulation.settings.useOmniLight)

            DisclosureGroup("Visibility") {
                Toggle("Show Earth", isOn: $simulation.settings.showEarth)
                Toggle("Show Satellites", isOn: $simulation.settings.showSatellites)
                Toggle("Show Debris", isOn: $simulation.settings.showDebris)
                Toggle("Show Simulation Stats", isOn: $simulation.showStats)
            }

            DisclosureGroup("Colors & Scaling") {
                ColorPicker("Satellite Color", selection: $simulation.settings.satelliteColor, supportsOpacity: false)
                ColorPicker("Debris Color", selection: $simulation.settings.debrisColor, supportsOpacity: false)
                ColorPicker("Background Color", selection: $simulation.settings.backgroundColor, supportsOpacity: false)

                SliderRow(label: "Satellite Scale",
                          value: $simulation.settings.satelliteScale,
                          range: SimSettings.scaleRange,
                          unit: "x")

                if scaleExceedsHitbox {
                    Label("Visual scale exceeds collision radius. Objects may overlap visually.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.bottom, 4)
                }

                SliderRow(label: "Debris Scale",
                          value: $simulation.settings.debrisScale,
                          range: SimSettings.scaleRange,
                          unit: "x")
            }
        }
    }
}
