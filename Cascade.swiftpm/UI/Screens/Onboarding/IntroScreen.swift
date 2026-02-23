import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void
    
    @State private var appeared = false
    @State private var glowPulse = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {}
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    
                    Spacer().frame(height: 20)
                    
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.blue)
                            .frame(width: 3)
                        
                        Text("Cascade is an educational simulator that lets you create and observe a Kessler Syndrome scenario in real time. You can move the camera around Earth and zoom to see the satellites, represented by green cubes \(Text(Image(systemName: "cube.fill")).foregroundStyle(.green)), orbiting our planet.\n\nWhen satellites collide with each other or with debris, they will produce small clouds of debris, represented by small pyramids \(Text(Image(systemName: "pyramid.fill")).foregroundStyle(.white)), which can collide with other satellites and produce a runaway collision cascade. Keep in mind that the simulation is not-to-scale, though.\n\nYou can learn more about Kessler Syndrome and Cascade in the Learn More tab. You can also tweak the settings to change every aspect of the simulation, and there are many Accessibility settings to ensure you have an awesome experience.\n\nThe simulation will begin paused - hit the play button to get it going. Good luck and have fun!")
                            .font(.default)
                            .foregroundStyle(CascadeTheme.bodyText)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                
                Rectangle()
                    .fill(CascadeTheme.dividerColor)
                    .frame(height: CascadeTheme.borderWidth)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Simulation Controls")
                        .font(.title2.weight(.semibold))
                        .padding()
                    
                    VStack(spacing: 8) {
                        OnboardingControlRow(
                            icon: "burst.fill",
                            tint: .red,
                            label: "Detonate",
                            detail: "Explode a random satellite to make the Cascade happen faster!"
                        )
                        OnboardingControlRow(
                            icon: "play.fill",
                            tint: .green,
                            label: "Play / Pause",
                            detail: "Pause and resume the simulation,"
                        )
                        OnboardingControlRow(
                            icon: "camera.metering.center.weighted",
                            tint: .white,
                            label: "Reset Camera",
                            detail: "Move the camera back to its default position."
                        )
                        OnboardingControlRow(
                            icon: "gearshape.fill",
                            tint: .white,
                            label: "Settings",
                            detail: "Change simulation parameters, accessibility settings, and more!"
                        )
                    }
                }
                .padding(28)
                
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Text("Begin the Cascade")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.green)
                .frame(maxWidth: 360)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
            .background(CascadeTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(128)
            .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

private struct OnboardingControlRow: View {
    let icon: String
    let tint: Color
    let label: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 6){
            VStack(spacing: 8) {
                HStack{
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .frame(width: 56, height: 56)
                    
                    Text(label)
                        .font(.title3.weight(.medium))
                    
                    Spacer()
                    
                }
            }
            Text(detail)
                .font(.body.weight(.regular))
                .foregroundStyle(.secondary)
        }
    }
}
