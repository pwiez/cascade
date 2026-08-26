//
//  ControlsPage.swift
//  Cascade
//
//  Created by Pedro Wiezel on 27/05/26.
//

import SwiftUI

struct ControlsPage: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Controls")
                .font(.system(size: titleSize, weight: .bold))

            HStack(alignment: .top, spacing: 56) {
                ControlColumn(items: ControlItem.simulationControls)
                ControlColumn(items: ControlItem.cameraControls)
            }
            .padding(.vertical, 32)
        }
    }
}
