//
//  CollisionPhysicsSection.swift
//  Cascade
//
//  Created by Pedro Wiezel on 08/05/26.
//

import CascadeEngine
import SwiftUI

struct CollisionPhysicsSection: View {
    @Bindable var simulation: Simulation

    var body: some View {
        Section("Collision Physics") {
            SliderRow(label: "Debris Ejection Force",
                      value: $simulation.settings.explosionForce,
                      range: SimSettings.explosionForceRange,
                      unit: "x")

            SliderRow(label: "Satellite Collision Radius",
                      value: $simulation.settings.collisionRadius,
                      range: SimSettings.collisionRadiusRange,
                      step: 0.1)

            SliderRow(label: "Debris per Collision",
                      value: $simulation.settings.debrisPerCollision,
                      range: SimSettings.debrisPerCollisionRange,
                      step: 1,
                      fractionDigits: 0)

            SliderRow(label: "Max Debris Count",
                      value: $simulation.settings.maxDebris,
                      range: SimSettings.maxDebrisRange,
                      step: 250,
                      fractionDigits: 0)

            SliderRow(label: "Debris Removal Distance",
                      value: $simulation.settings.eliminationRadius,
                      range: SimSettings.eliminationRadiusRange,
                      step: 25,
                      fractionDigits: 0,
                      caption: "Debris that drifts farther than this from Earth is removed from the simulation.")
        }
    }
}
