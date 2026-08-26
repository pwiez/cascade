//
//  Scenario.swift
//  Cascade
//

public struct Scenario: Equatable, Sendable {
    public var satelliteCount: Double
    public var orbitAltitude: Double
    public var orbitVariance: Double

    public var useRandomInclination: Bool
}

extension Scenario {

    public static let defaults = Scenario(
        satelliteCount: 300,
        orbitAltitude: 290,
        orbitVariance: 10,
        useRandomInclination: true
    )

    public static let satelliteCountRange: ClosedRange<Double> = 200...Double(Capacity.maxSatellites)
    public static let orbitAltitudeRange: ClosedRange<Double> = 250...320
    public static let orbitVarianceRange: ClosedRange<Double> = 0...40
}
