import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        GeometryReader { geometry in
            let overlayWidth = geometry.size.width
            
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
                            
                            Text("Cascade is an educational physics simulator that lets you create and observe a Kessler Syndrome scenario in real time. The satellites orbiting our planet, represented by green cubes \(Text(Image(systemName: "cube.fill")).foregroundStyle(.green)), can collide with each other. When they do, clouds of debris represented by small tetrahedrons \(Text(Image(systemName: "pyramid.fill")).foregroundStyle(.white)) will appear and spread. They can collide with other satellites. Eventually, this produces a runaway collision chain reaction.\n\nYou can tweak the settings to change the parameters of collisions and debris generation physics, and there are Accessibility settings, such as changing the color and size of satellites and debris, to ensure you have an awesome experience.\n\nIf you want to learn more about Kessler Syndrome and Cascade itself, you can do so by tapping the Learn More tab. The simulation will be paused for you when you switch tabs.\n\nThe simulation will begin paused - simply tap the play button to get it going. Have fun, and I hope you learn a lot about this fascinating (and worrying) topic!")
                                .font(.body)
                                .foregroundStyle(CascadeTheme.bodyText)
                                .lineSpacing(CascadeTheme.bodyLineSpacing)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Rectangle()
                            .fill(CascadeTheme.dividerColor)
                            .frame(height: CascadeTheme.borderWidth)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            HStack{
                                Text("Simulation Controls")
                                    .font(.title2.weight(.semibold))
                                
                                Spacer()
                                
                                Text("Camera Controls")
                                    .font(.title2.weight(.semibold))
                                
                                Spacer()
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 24) {
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "burst.fill")
                                            .foregroundStyle(.red)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Detonate")
                                            .font(.body.weight(.medium))
                                        Text("Explode a random satellite to hasten the chaos")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .foregroundStyle(.orange)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Restart")
                                            .font(.body.weight(.medium))
                                        Text("Clear debris and restart the simulation")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "play.fill")
                                            .foregroundStyle(.green)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Play / Pause")
                                            .font(.body.weight(.medium))
                                        Text("Pause or resume the simulation.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    GridRow(alignment: .firstTextBaseline) {
                                         Image(systemName: "camera.metering.center.weighted")
                                            .foregroundStyle(.white)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Reset Camera")
                                            .font(.body.weight(.medium))
                                        Text("Move the camera back to its default position and zoom level")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(.white)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Settings")
                                            .font(.body.weight(.medium))
                                        Text("Change physics parameters, accessibility settings, and more")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }.frame(maxWidth: overlayWidth / 2, alignment: .leading)
                                
                                Divider()
                                    .padding(.horizontal, 24)
                                
                                Grid(alignment: .leading, verticalSpacing: 24) {
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "hand.draw.fill")
                                            .foregroundStyle(.white)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Drag")
                                            .font(.body.weight(.medium))
                                        Text("Drag your finger on the screen to move the camera around Earth")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    GridRow(alignment: .firstTextBaseline) {
                                        Image(systemName: "hand.pinch.fill")
                                            .foregroundStyle(.white)
                                            .font(.body)
                                            .imageScale(.large)
                                        Text("Pinch")
                                            .font(.body.weight(.medium))
                                        Text("Pinch the screen with two fingers to zoom the camera in or out")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Button(action: onDismiss) {
                                Text("Begin the Cascade")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.green)
                                    .foregroundStyle(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.top, 16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(40)
                }
                .frame(maxWidth: .infinity)
                .background(CascadeTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(64)
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
