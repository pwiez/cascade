//
//  EngineCommand.swift
//  Cascade
//

enum EngineCommand {
    case reset(satelliteCount: Int)
    case detonate
    case updateSettings(EngineSettings)
}
