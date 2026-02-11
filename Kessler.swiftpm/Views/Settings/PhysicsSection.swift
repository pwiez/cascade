//
//  PhysicsSection.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI

struct PhysicsSection: View {
    @ObservedObject var simulation: Simulation
    
    var body: some View {
        Section(header: Text("Collision Physics")) {
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "slowmo")
                        .foregroundStyle(.orange)
                    Text("Explosion Force")
                    Spacer()
                    Text(String(format: "%.1f", simulation.explosionForce))
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $simulation.explosionForce, in: 0.1...10.0, step: 0.1)
                    .tint(.orange)
                
                HStack {
                    Text("Nudge")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("Violent")
                        .foregroundStyle(.red)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.orange)
                    Text("Debris per Collision")
                    Spacer()
                    Text("\(Int(simulation.debrisPerCollision))")
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $simulation.debrisPerCollision, in: 1...30, step: 1)
                    .tint(.orange)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "square.resize")
                        .foregroundStyle(.orange)
                    Text("Hitbox Size")
                    Spacer()
                    Text(String(format: "%.1f km", simulation.collisionRadius))
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $simulation.collisionRadius, in: 0.5...5.0, step: 0.1)
                    .tint(.yellow)
                Text("Making hitboxes smaller will make collisions harder to happen, but more precise. Making hitboxes bigger will cause more collisions, but they will look more random.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
