//
//  EngineCommand.swift
//  Cascade
//

/// A request from the UI to the engine, drained once per frame.
///
/// The UI never touches the scene graph directly. Queueing instead means a burst
/// of slider changes between two frames collapses into a single update, and
/// every mutation happens at one known point in the frame rather than whenever a
/// gesture happened to fire.
enum EngineCommand {
    case reset(satelliteCount: Int)
    case detonate
    case updateSettings(EngineSettings)
}
