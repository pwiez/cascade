import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {}
            
            ScrollView {
                VStack(spacing: 32) {
                    HStack(alignment: .top, spacing: 16) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.blue)
                            .frame(width: 4)
                        
                        Text("Cascade is an educational simulator that lets you create and observe a Kessler Syndrome scenario in real time. You can move the camera around Earth and zoom to see the satellites, represented by green cubes \(Text(Image(systemName: "cube.fill")).foregroundStyle(.green)), orbiting our planet.\n\nWhen satellites collide with each other or with debris, they will produce small clouds of debris, represented by small pyramids \(Text(Image(systemName: "pyramid.fill")).foregroundStyle(.white)), which can collide with other satellites and produce a runaway collision cascade. Keep in mind that the simulation is not-to-scale, though.\n\nYou can learn more about Kessler Syndrome and Cascade in the Learn More tab. You can also tweak the settings to change every aspect of the simulation, and there are many Accessibility settings to ensure you have an awesome experience.\n\nThe simulation will begin paused - tap the play button to get it going. Have fun, and I hope you learn a lot about this fascinating (albeit worrying) topic!")
                            .font(.body)
                            .foregroundStyle(CascadeTheme.bodyText)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    Rectangle()
                        .fill(CascadeTheme.dividerColor)
                        .frame(height: CascadeTheme.borderWidth)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Simulation Controls")
                            .font(.title2.weight(.semibold))
                        
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 24) {
                            
                            GridRow(alignment: .firstTextBaseline) {
                                Image(systemName: "burst.fill")
                                    .foregroundStyle(.red)
                                    .font(.body)
                                    .imageScale(.large)
                                Text("Detonate")
                                    .font(.body.weight(.medium))
                                Text("Explode a random satellite to make the Cascade happen faster!")
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
                                Text("Pause and resume the simulation.")
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
                                Text("Move the camera back to its default position.")
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
                                Text("Change simulation parameters, accessibility settings, and more!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                .padding(40)
            }
            .frame(maxWidth: 700)
            .background(CascadeTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.vertical, 40)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}
