//
//  LearnMoreView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 12/02/26.
//

import SwiftUI

struct LearnMoreView: View {
    var body: some View {
        if #available(iOS 26, *) {
            LearnMoreNativeView()
        } else {
            LearnMoreLegacyView()
        }
    }
}
