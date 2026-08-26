//
//  SpreadSliderRow.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import CascadeEngine
import SwiftUI

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
