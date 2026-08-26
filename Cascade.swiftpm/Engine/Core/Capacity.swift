//
//  Capacity.swift
//  Cascade
//

/// Fixed sizes for every preallocated buffer in the engine.
///
/// Cascade never grows a buffer while the simulation is running — allocation in
/// the middle of a frame is exactly the kind of stall a real-time loop cannot
/// absorb. Instead every pool, mask and vertex buffer is sized once, up front,
/// from the numbers below.
///
/// That only works while these stay in sync with the sliders that feed them, so
/// the ceilings live here rather than being written out at each use site:
/// `SimSettings` clamps its own ranges against them, and the settings UI reads
/// those same ranges. Change a number here and the whole chain follows.
enum Capacity {

    /// Hard ceiling on live debris fragments.
    ///
    /// Sizes `DebrisPool`, the solver's kill mask, both `FrameBuffer`s and the
    /// `LowLevelMesh` ring. Sits above ``SimSettings/maxDebrisRange`` so that a
    /// collision resolving at the ceiling can still overspawn by one burst
    /// without dropping fragments.
    static let maxDebris = 8_000

    /// Hard ceiling on satellites, matching ``Scenario/satelliteCountRange``.
    static let maxSatellites = 500

    /// Every object the spatial grid may be asked to index in one frame.
    ///
    /// The grid keys its linked list by a single object index that runs
    /// satellites first, then debris, so it has to cover both populations at
    /// once.
    static let gridObjects = maxDebris + maxSatellites
}
