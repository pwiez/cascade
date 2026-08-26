import SwiftUI

/// A dated event annotated on the debris chart.
struct DebrisMilestone: Identifiable {
    var id: Int { year }

    let year: Int
    let name: String
    let color: Color

    /// Which side of the rule the label sits on, so the two don't overlap.
    let alignment: Alignment
}
