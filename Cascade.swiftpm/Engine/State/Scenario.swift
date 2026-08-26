//
//  Scenario.swift
//  Cascade
//

/// The parameters baked into the universe when it is built.
///
/// Unlike ``SimSettings``, these cannot take effect on the next frame — changing
/// an orbit altitude means respawning every satellite. So ``Simulation`` keeps
/// two of these: a `draft` the user edits freely, and the `active` one the
/// running universe was actually built from. The difference between them is what
/// puts the settings panel into its "restart pending" state.
public struct Scenario: Equatable, Sendable {
    public var satelliteCount: Double
    public var orbitAltitude: Double
    public var orbitVariance: Double

    /// When true, satellites are distributed over a sphere rather than a single
    /// equatorial ring — the difference between a shell and a flat belt.
    public var useRandomInclination: Bool
}

extension Scenario {

    public static let defaults = Scenario(
        satelliteCount: 300,
        orbitAltitude: 290,
        orbitVariance: 10,
        useRandomInclination: true
    )

    /// Upper bound matches `Capacity.maxSatellites`, which sizes the spatial grid.
    public static let satelliteCountRange: ClosedRange<Double> = 200...Double(Capacity.maxSatellites)
    public static let orbitAltitudeRange: ClosedRange<Double> = 250...320
    public static let orbitVarianceRange: ClosedRange<Double> = 0...40
}
