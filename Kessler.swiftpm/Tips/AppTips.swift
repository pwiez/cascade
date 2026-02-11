//
//  RespawnTip.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI
import TipKit

struct RespawnTip: Tip {
    var title: Text { Text("Reset Simulation") }
    var message: Text? { Text("We moved this! Tap here to clear all debris and start a fresh simulation.") }
    var image: Image? { Image(systemName: "arrow.counterclockwise") }
}

struct DetonateTip: Tip {
    var title: Text { Text("Start the Chain Reaction") }
    var message: Text? { Text("Tap this to explode a random satellite and watch the Kessler Syndrome unfold.") }
    var image: Image? { Image(systemName: "exclamationmark.triangle.fill") }
}

struct TimeScaleTip: Tip {
    var title: Text { Text("Control Time") }
    var message: Text? { Text("Speed up time to see decades of orbital decay in just a few seconds.") }
    var image: Image? { Image(systemName: "clock.arrow.circlepath") }
}
