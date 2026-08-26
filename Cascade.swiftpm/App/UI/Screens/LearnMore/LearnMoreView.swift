//
//  LearnMoreView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 12/02/26.
//

import SwiftUI

/// The Learn More tab.
///
/// iOS 26 gets a real `NavigationSplitView`, which brings Liquid Glass and the
/// system sidebar behaviours with it. Earlier releases get a hand-built
/// two-column layout, because a split view inside a `TabView` collapses
/// unpredictably there.
struct LearnMoreView: View {
    var body: some View {
        if #available(iOS 26, *) {
            LearnMoreNativeView()
        } else {
            LearnMoreLegacyView()
        }
    }
}
