//
//  PortraitWarningView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/02/26.
//

import SwiftUI

struct PortraitWarningView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "ipad.landscape")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("Please Rotate Your Device")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Cascade is designed to be experienced in landscape mode.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}
