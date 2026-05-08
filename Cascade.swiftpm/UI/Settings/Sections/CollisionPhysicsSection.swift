import SwiftUI

struct CollisionPhysicsSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section {
            SliderRow(label: "Debris Ejection Force",
                      value: $simulation.explosionForce,
                      range: 0.5...3.0,
                      format: "%.1fx")
            SliderRow(label: "Satellite Collision Radius",
                      value: $simulation.collisionRadius,
                      range: 1.0...3.0,
                      step: 0.1,
                      format: "%.1f")
            SliderRow(label: "Debris per Collision",
                      value: $simulation.debrisPerCollision,
                      range: 5...10,
                      step: 1,
                      format: "%.0f")
            SliderRow(label: "Max Debris Count",
                      value: $simulation.maxDebris,
                      range: 3000...7500,
                      step: 250,
                      format: "%.0f")
        } header: {
            Text("Collision Physics")
        }
    }
}
