//
//  TimelineVertical.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct TimelineVertical: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(TimelineEvent.all.enumerated()), id: \.element.id) { index, event in
                TimelineRow(event: event, isLast: index == TimelineEvent.all.count - 1)
            }
        }
    }
}
