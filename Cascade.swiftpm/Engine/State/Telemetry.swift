//
//  Telemetry.swift
//  Cascade
//

import Observation

/// The live object counts, in their own observable box.
///
/// This looks like pointless indirection but earns its keep: these numbers change
/// several times a second, and SwiftUI invalidates observers per *object*, not
/// per property. Keeping them out of ``Simulation`` means a ticking debris count
/// doesn't re-evaluate the settings panel, and dragging a slider doesn't
/// re-evaluate the readout.
@MainActor @Observable
public final class Telemetry {
    public var stats = SimStats()

    init() {}
}
