//
//  IntroScreen.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI

struct IntroScreen: View {
    var onEnter: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe.americas.fill")
                                .foregroundStyle(.blue)
                            Text("INTRODUCTION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.blue)
                                .tracking(1.2)
                        }
                        
                        Text("Cascade")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("A Kessler Syndrome Simulator")
                            .font(.title2)
                            .foregroundStyle(CascadeTheme.dimText)
                    }
                    
                    Spacer().frame(height: 44)
                    
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Low Earth Orbit is getting crowded. Thousands of satellites share space with millions of debris fragments — and at orbital speeds, even a fleck of paint hits like a bullet.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                        
                        Text("Cascade lets you explore what happens when collisions start a chain reaction. Trigger a detonation, watch debris spread, and see how one event can spiral out of control.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                    }
                    .frame(maxWidth: 500)
                    
                    Spacer()
                    
                    Button(action: onEnter) {
                        Text("Enter Simulation")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 54)
                            .background(.blue)
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 10, y: 4)
                    }
                    .accessibilityHint("Starts the orbital debris simulation")
                    .padding(.bottom, 60)
                }
                .padding(.leading, 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    IntroFeatureCard(
                        icon: "cube.transparent",
                        title: "Simulate",
                        description: "Watch satellites orbit Earth in real time. Trigger collisions and observe how debris cascades through orbital shells."
                    )
                    
                    IntroFeatureCard(
                        icon: "book.closed.fill",
                        title: "Learn More",
                        description: "Read about the science behind orbital debris — from collision mechanics to the strategies engineers are developing to clean up orbit."
                    )
                    
                    IntroFeatureCard(
                        icon: "gearshape.fill",
                        title: "Configure",
                        description: "Adjust satellite count, debris physics, explosion force, and time scale to explore different scenarios."
                    )
                    
                    Spacer()
                }
                .frame(maxWidth: 380)
                .padding(.trailing, 64)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct IntroFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ThemedIcon(systemName: icon, color: .blue, shape: .roundedRect)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(CascadeTheme.dimText)
                    .lineSpacing(CascadeTheme.compactLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cascadeCard(padding: CascadeTheme.cardPadding)
        .accessibilityElement(children: .combine)
    }
}