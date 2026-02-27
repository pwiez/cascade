import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        HStack(alignment: .top, spacing: 16) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(.blue)
                                .frame(width: 4)
                            
                            Text("Cascade is a physics simulator created to spread awareness and education about Kessler Syndrome. It lets you create and observe a collision cascade scenario in real time. The satellites orbiting our planet, represented by green cubes \(Text(Image(systemName: "cube.fill")).foregroundStyle(.green)), can collide with each other. When they do, clouds of debris represented by white tetrahedrons \(Text(Image(systemName: "pyramid.fill")).foregroundStyle(.white)) will appear and spread. They can collide with other satellites. Eventually, this produces a runaway collision chain reaction!")
                                .font(.body)
                                .foregroundStyle(DesignTokens.bodyText)
                                .lineSpacing(DesignTokens.bodyLineSpacing)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Rectangle()
                            .fill(DesignTokens.dividerColor)
                            .frame(height: DesignTokens.borderWidth)
                        
                        HStack(alignment: .top, spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Simulation Controls")
                                    .font(.title2.weight(.semibold))
                                
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 24) {
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "burst.fill").foregroundStyle(.red).font(.body).imageScale(.large)
                                        Text("Detonate").font(.body.weight(.medium))
                                        Text("Explode a random satellite").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.orange).font(.body).imageScale(.large)
                                        Text("Restart").font(.body.weight(.medium))
                                        Text("Restart the simulation").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "play.fill").foregroundStyle(.green).font(.body).imageScale(.large)
                                        Text("Play / Pause").font(.body.weight(.medium))
                                        Text("Control the flow of time").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "camera.metering.center.weighted").foregroundStyle(.primary).font(.body).imageScale(.large)
                                        Text("Reset Camera").font(.body.weight(.medium))
                                        Text("Reset the camera's position and zoom").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "gearshape.fill").foregroundStyle(.primary).font(.body).imageScale(.large)
                                        Text("Settings").font(.body.weight(.medium))
                                        Text("Control visuals and other parameters").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                                .padding(.horizontal, 32)
                            
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Camera Controls")
                                    .font(.title2.weight(.semibold))
                                
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 24) {
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "hand.draw.fill").foregroundStyle(.primary).font(.body).imageScale(.large)
                                        Text("Drag").font(.body.weight(.medium))
                                        Text("Drag your finger to move the camera around Earth").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "hand.pinch.fill").foregroundStyle(.primary).font(.body).imageScale(.large)
                                        Text("Pinch").font(.body.weight(.medium))
                                        Text("Pinch with two fingers to zoom in or out").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Rectangle()
                            .fill(DesignTokens.dividerColor)
                            .frame(height: DesignTokens.borderWidth)
                        
                        HStack(alignment: .top, spacing: 16) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(.blue)
                                .frame(width: 4)
                            
                            Text("Cascade has a range of visual settings to make sure you have the best possible experience. If you want to learn more about Kessler Syndrome and Cascade itself, you can do so by tapping the Learn More tab. The simulation will be paused for you when you switch tabs.\n\nThe simulation will begin paused - simply tap the play button to get it going. Have fun, and I hope you learn a lot about this fascinating (and worrying) topic!")
                                .font(.body)
                                .foregroundStyle(DesignTokens.bodyText)
                                .lineSpacing(DesignTokens.bodyLineSpacing)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: onDismiss) {
                            Text("Enter the Cascade")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.green)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 16)
                    }
                    .padding(40)
                }
                .frame(maxWidth: .infinity)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 128)
                .padding(.vertical, 64)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appeared = true
                }
            }
        }
    }
}
