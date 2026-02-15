import SwiftUI
import TipKit

struct SettingsTip: Tip {
    var title: Text { Text("Customize Simulation") }
    var message: Text? { Text("Tap here to adjust gravity, debris count, and collision physics.") }
    var image: Image? { Image(systemName: "gear") }
}

struct LearnMoreTip: Tip {
    var title: Text { Text("Understand the Science") }
    var message: Text? { Text("Learn about the real-world implications of the Kessler Syndrome here.") }
    var image: Image? { Image(systemName: "book.closed.fill") }
}

struct MitigationTip: Tip {
    var title: Text { Text("We Can Fix This") }
    var message: Text? { Text("Explore real strategies scientists are using to clean up orbit.") }
}
