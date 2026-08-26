//
//  SimSettings.swift
//  Cascade
//

import SwiftUI

public struct SimSettings: Equatable, Sendable {

    public var debrisPerCollision: Double
    public var explosionForce: Double
    public var collisionRadius: Double
    public var maxDebris: Double
    public var eliminationRadius: Double

    public var spreadTangential: Double
    public var spreadVertical: Double
    public var spreadRadial: Double

    public var timeScale: Double
    public var gravityMultiplier: Double

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
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.09),
        satelliteScale: 1.0,
        debrisScale: 1.0,
        debrisRotation: true,
        useOmniLight: false,
        showEarth: true,
        showSatellites: true,
        showDebris: true
    )

    public static let debrisPerCollisionRange: ClosedRange<Double> = 5...10
    public static let explosionForceRange: ClosedRange<Double> = 0.5...3.0
    public static let collisionRadiusRange: ClosedRange<Double> = 1.0...3.0
    public static let eliminationRadiusRange: ClosedRange<Double> = 380...1_000
    public static let spreadRange: ClosedRange<Double> = 0...2
    public static let timeScaleRange: ClosedRange<Double> = 0.1...5.0
    public static let scaleRange: ClosedRange<Double> = 0.5...5.0

    public static let maxDebrisRange: ClosedRange<Double> = 3_000...7_500
}
