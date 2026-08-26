//
//  SimSettings.swift
//  Cascade
//

import SwiftUI

/// Every parameter the user can change while the simulation is running.
///
/// This is stored whole by ``Simulation`` and handed to the engine whole. It is
/// deliberately *not* flattened into individual properties: the engine needs all
/// of it at once, so keeping it as one value means adding a parameter is a
/// single edit the compiler checks, rather than four edits it does not.
///
/// Settings that require rebuilding the universe live in ``Scenario`` instead.
public struct SimSettings: Equatable, Sendable {

    // Collision physics
    public var debrisPerCollision: Double
    public var explosionForce: Double
    public var collisionRadius: Double
    public var maxDebris: Double
    public var eliminationRadius: Double

    /// Shape of the debris cloud immediately after a satellite breaks up,
    /// as a fraction of the ejection impulse along each orbital axis.
    public var spreadTangential: Double
    public var spreadVertical: Double
    public var spreadRadial: Double

    // World
    public var timeScale: Double
    public var gravityMultiplier: Double

    // Visuals
    public var satelliteColor: Color
    public var debrisColor: Color
    public var backgroundColor: Color
    public var satelliteScale: Double
    public var debrisScale: Double
    public var debrisRotation: Bool
    public var useOmniLight: Bool
    public var showEarth: Bool
    public var showSatellites: Bool
    public var showDebris: Bool
}

extension SimSettings {

    public static let defaults = SimSettings(
        debrisPerCollision: 7,
        explosionForce: 0.7,
        collisionRadius: 1.0,
        maxDebris: 5_000,
        eliminationRadius: 600,
        spreadTangential: 0.1,
        spreadVertical: 0.6,
        spreadRadial: 0.1,
        timeScale: 1.0,
        gravityMultiplier: 1.0,
        satelliteColor: Color(red: 0.108, green: 0.725, blue: 0.229),
        debrisColor: .red,
        // Near-black with a blue cast, rather than flat black: it reads as space
        // rather than as an unrendered view.
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.09),
        satelliteScale: 1.0,
        debrisScale: 1.0,
        debrisRotation: true,
        useOmniLight: false,
        showEarth: true,
        showSatellites: true,
        showDebris: true
    )

    // Slider ranges live beside the values they constrain so the settings UI and
    // the engine's fixed buffers cannot drift apart. See `Capacity`.
    public static let debrisPerCollisionRange: ClosedRange<Double> = 5...10
    public static let explosionForceRange: ClosedRange<Double> = 0.5...3.0
    public static let collisionRadiusRange: ClosedRange<Double> = 1.0...3.0
    public static let eliminationRadiusRange: ClosedRange<Double> = 380...1_000
    public static let spreadRange: ClosedRange<Double> = 0...2
    public static let timeScaleRange: ClosedRange<Double> = 0.1...5.0
    public static let scaleRange: ClosedRange<Double> = 0.5...5.0

    /// Capped below `Capacity.maxDebris` so one more burst can always resolve at
    /// the ceiling without the pool refusing to spawn mid-collision.
    public static let maxDebrisRange: ClosedRange<Double> = 3_000...7_500
}
