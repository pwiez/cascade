//
//  Telemetry.swift
//  Cascade
//

import Observation

@MainActor @Observable
public final class Telemetry {
    public var stats = SimStats()

    init() {}
}
