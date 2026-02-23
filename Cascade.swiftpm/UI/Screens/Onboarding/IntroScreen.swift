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

                        Text("Cascade is an educational simulator that lets you trigger and observe a Kessler Syndrome scenario in real time. You can move the camera around to see the satellites, represented by green cubes \(Text(Image(systemName: "cube.fill")).foregroundStyle(.green)), orbiting our planet. When they collide, they will produce small clouds of debris, represented by small pyramids \(Text(Image(systemName: "pyramid.fill")).foregroundStyle(.white)), which can collide with other satellites and produce a runaway collision cascade. Keep in mind that what you will see here is not-to-scale, though.\n\nYou can learn more about Kessler Syndrome and Cascade in the Learn More tab. You can also tweak the settings to change every aspect of the simulation, as well as Accessibility settings to ensure you have an awesome experience. Have fun!")
                            .font(.default)
                            .foregroundStyle(CascadeTheme.bodyText)
                            .lineSpacing(CascadeTheme.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .staggerIn(appeared: appeared, index: 1)

                Rectangle()
                    .fill(CascadeTheme.dividerColor)
                    .frame(height: CascadeTheme.borderWidth)
                    .padding(.horizontal, 28)

                VStack(alignment: .leading, spacing: 14) {
                    Text("CONTROLS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)

                    VStack(spacing: 10) {
                        OnboardingControlRow(
                            icon: "burst.fill",
                            tint: .red,
                            label: "Detonate",
                            detail: "Destroy a satellite manually to make the Cascade faster"
                        )
                        OnboardingControlRow(
                            icon: "play.fill",
                            tint: .green,
                            label: "Play / Pause",
                            detail: "Pause and resume the simulation at any moment"
                        )
                        OnboardingControlRow(
                            icon: "camera.metering.center.weighted",
                            tint: .secondary,
                            label: "Play / Pause",
                            detail: "Reset the camera to its default position"
                        )
                        OnboardingControlRow(
                            icon: "gearshape.fill",
                            tint: .secondary,
                            label: "Settings",
                            detail: "Change accessibility settings, physics parameters, and more"
                        )
                    }
                }
                .padding(28)
                .staggerIn(appeared: appeared, index: 2)

                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Text("Begin the Cascade")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.innerRadius))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
                .staggerIn(appeared: appeared, index: 4)
            }
            .frame(maxWidth: 700)
            .background(CascadeTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
            )
            .shadow(color: .black.opacity(0.55), radius: 48, y: 14)
            .padding(40)
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
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(CascadeTheme.iconBackgroundOpacity))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 86, alignment: .leading)

            Text(detail)
                .font(.caption)
                .foregroundStyle(CascadeTheme.dimText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingCapability: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CascadeTheme.dimText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.08), lineWidth: CascadeTheme.borderWidth)
        )
        .padding(.horizontal, 3)
    }
}

private struct StaggerModifier: ViewModifier {
    let appeared: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(
                .easeOut(duration: 0.5).delay(Double(index) * 0.08),
                value: appeared
            )
    }
}

private extension View {
    func staggerIn(appeared: Bool, index: Int) -> some View {
        modifier(StaggerModifier(appeared: appeared, index: index))
    }
}
