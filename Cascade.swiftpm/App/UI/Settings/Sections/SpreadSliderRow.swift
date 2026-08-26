import CascadeEngine
import SwiftUI

/// A spread slider with its physical meaning spelled out underneath.
struct SpreadSliderRow: View {
    let label: String
    @Binding var value: Double
    let explanation: String

    var body: some View {
        SliderRow(
            label: label,
            value: $value,
            range: SimSettings.spreadRange,
            caption: explanation
        )
        .padding(.bottom, 6)
    }
}
