//
//  RespawnTip.swift
//  Kessler
//
//  Created by Pedro Wiezel on 11/02/26.
//

import SwiftUI
import TipKit

struct SettingsTip: Tip {
    var title: Text { Text("Change Parameters") }
    var message: Text? { Text("You can open this menu to change a lot of simulation parameters.") }
    var image: Image? { Image(systemName: "gear") }
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
