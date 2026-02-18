//
//  PortraitWarningView.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct PortraitWarningView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "ipad.landscape")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 12) {
                    Text("Rotate your iPad")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    
                    Text("Cascade works best in landscape mode.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Please rotate your iPad to landscape orientation. Cascade works best in landscape mode.")
        }
    }
}