import SwiftUI
import TipKit

struct DetonateTip: Tip {
    var title: Text { Text("Trigger a Collision") }
    var message: Text? { Text("Destroys a satellite and scatters debris into orbit. Watch how fragments spread and collide with other objects.") }
    var image: Image? { Image(systemName: "burst.fill") }
}

struct SettingsTip: Tip {
    var title: Text { Text("Simulation Parameters") }
    var message: Text? { Text("Adjust satellite count, debris physics, explosion force, and more.") }
    var image: Image? { Image(systemName: "gearshape.fill") }
}

struct LearnMoreTip: Tip {
    var title: Text { Text("Learn About Kessler Syndrome") }
    var message: Text? { Text("Read about the real science behind orbital debris and why it matters.") }
    var image: Image? { Image(systemName: "book.closed.fill") }
}
