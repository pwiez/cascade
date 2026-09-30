//
//  SatelliteSpawner.swift
//  Cascade
//

import RealityKit
import simd

/// Builds a fresh constellation with the scenario and visibility settings applied.
@MainActor
enum SatelliteSpawner {
    static func makeSatellites(count: Int, settings: EngineSettings, earthMass: Float,
                               mesh: MeshResource, material: UnlitMaterial) -> [ModelEntity] {
        let scenario = settings.scenario
        let altitude = Float(scenario.orbitAltitude)
        let variance = Float(scenario.orbitVariance)
        let gm = earthMass * Float(settings.sim.gravityMultiplier)
        let scale = Float(settings.sim.satelliteScale)

        var satellites: [ModelEntity] = []
        satellites.reserveCapacity(count)

        for i in 0..<count {
            let radius = altitude + .random(in: -variance...variance)
            let orbitalSpeed = sqrt(gm / radius)

            let (position, velocity) = scenario.useRandomInclination
                ? Self.shellOrbit(index: i, count: count, radius: radius, speed: orbitalSpeed)
                : Self.ringOrbit(index: i, count: count, radius: radius, speed: orbitalSpeed)

            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.scale = SIMD3(repeating: scale)
            entity.position = position
            entity.components.set(OrbitalData(velocity: velocity))
            if !settings.sim.showSatellites {
                entity.components.remove(ModelComponent.self)
            }

            satellites.append(entity)
        }
        return satellites
    }

    private static func shellOrbit(index: Int, count: Int, radius: Float, speed: Float)
        -> (position: SIMD3<Float>, velocity: SIMD3<Float>) {

        let goldenAngle: Float = 2.399963229
        let z = 1.0 - (2.0 * Float(index) + 1.0) / Float(count)
        let sinTheta = sqrt(max(0.0, 1.0 - z * z))
        let phi = goldenAngle * Float(index)

        let radial = SIMD3<Float>(sinTheta * cos(phi), z, sinTheta * sin(phi))

        var tangent = SIMD3<Float>(.random(in: -1...1), .random(in: -1...1), .random(in: -1...1))
        tangent -= radial * dot(tangent, radial)
        if length(tangent) < 0.001 {
            tangent = abs(radial.x) < 0.9 ? cross(radial, SIMD3(1, 0, 0)) : cross(radial, SIMD3(0, 1, 0))
        }

        return (radial * radius, normalize(tangent) * speed)
    }

    private static func ringOrbit(index: Int, count: Int, radius: Float, speed: Float)
        -> (position: SIMD3<Float>, velocity: SIMD3<Float>) {

        let anomaly = (Float(index) / Float(count)) * 2.0 * .pi
        return (
            SIMD3(cos(anomaly), 0, sin(anomaly)) * radius,
            SIMD3(-sin(anomaly), 0, cos(anomaly)) * speed
        )
    }

}
