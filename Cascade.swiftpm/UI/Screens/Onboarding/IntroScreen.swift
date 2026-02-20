import SwiftUI
import RealityKit
import Combine

struct IntroScreen: View {
    @State private var currentStep = 0
    var onComplete: () -> Void
    
    private let totalSteps = 2
    
    var body: some View {
        HStack(spacing: 0) {
            
            IntroSceneView(step: currentStep)
                .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: CascadeTheme.cardRadius)
                        .stroke(CascadeTheme.cardBorder, lineWidth: CascadeTheme.borderWidth)
                )
                .padding(32)
                .zIndex(1)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CASCADE")
                        .font(.subheadline.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.blue)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(stepLabel)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 24)
                
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i == currentStep ? Color.blue : Color.white.opacity(0.15))
                            .frame(width: i == currentStep ? 28 : 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                .accessibilityHidden(true)
                
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        if currentStep == 0 {
                            stepOneContent()
                                .transition(.opacity)
                        } else {
                            stepTwoContent()
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.bottom, 32)
                }
                
                HStack(spacing: 24) {
                    Button {
                        if currentStep > 0 { currentStep -= 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                                .font(.body.weight(.medium))
                        }
                        .foregroundStyle(currentStep > 0 ? .white.opacity(0.7) : .clear)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(currentStep > 0 ? CascadeTheme.raisedBackground : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.innerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: CascadeTheme.innerRadius)
                                .stroke(currentStep > 0 ? CascadeTheme.cardBorder : Color.clear, lineWidth: CascadeTheme.borderWidth)
                        )
                    }
                    .disabled(currentStep == 0)
                    .accessibilityLabel("Go back to previous step")
                    
                    Spacer()
                    
                    Button {
                        if currentStep < totalSteps - 1 {
                            currentStep += 1
                        } else {
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentStep == totalSteps - 1 ? "Start Simulation" : "Continue")
                                .font(.body.weight(.semibold))
                            Image(systemName: currentStep == totalSteps - 1 ? "play.fill" : "chevron.right")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: CascadeTheme.innerRadius))
                    }
                    .accessibilityLabel(currentStep == totalSteps - 1 ? "Start Simulation" : "Continue to next step")
                }
                .padding(.top, 16)
            }
            .frame(maxWidth: 500)
            .padding(.vertical, 48)
            .padding(.trailing, 48)
        }
        .preferredColorScheme(.dark)
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    private var stepLabel: String {
        switch currentStep {
        case 0: return "Orbital Infrastructure"
        case 1: return "The Chain Reaction"
        default: return ""
        }
    }
    
    
    @ViewBuilder
    private func stepOneContent() -> some View {
        VStack(alignment: .leading, spacing: 48) {
            introCard(
                icon: "antenna.radiowaves.left.and.right",
                iconColor: .green,
                title: "Satellites",
                body: "Over 10,000 active satellites orbit our planet. In the simulation, each one is represented as a green cube like this. They share a finite band of orbital space — and every launch makes it more crowded."
            )
            
            introCard(
                icon: "burst.fill",
                iconColor: .orange,
                title: "Orbital Debris",
                body: "When satellites collide at 28,000 km/h, they shatter into hundreds of high-speed fragments. Each fragment becomes a new, uncontrollable projectile threatening everything in its path."
            )
        }
    }
    
    @ViewBuilder
    private func stepTwoContent() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            SectionLabel(text: "Simulation Controls")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            
            VStack(alignment: .leading, spacing: 20) {
                guideCard(number: "1", icon: "burst.fill", color: .red,
                          title: "Detonate",
                          body: "Tap the burst button to destroy a satellite and scatter debris into orbit.")
                
                guideCard(number: "2", icon: "eye.fill", color: .cyan,
                          title: "Observe",
                          body: "Watch fragments collide with other satellites, triggering the cascade in real-time.")
                
                guideCard(number: "3", icon: "gearshape.fill", color: .purple,
                          title: "Experiment",
                          body: "Open settings to adjust satellite count, orbit altitude, speed, colors, and more.")
            }
        }
    }
    
    
    @ViewBuilder
    private func introCard(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ThemedIcon(systemName: icon, color: iconColor, shape: .roundedRect)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.body)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.compactLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cascadeAccentCard(iconColor, padding: CascadeTheme.compactPadding)
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func guideCard(number: String, icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.body.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(CascadeTheme.iconBackgroundOpacity))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                Text(body)
                    .font(.body)
                    .foregroundStyle(CascadeTheme.bodyText)
                    .lineSpacing(CascadeTheme.compactLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cascadeAccentCard(color, padding: CascadeTheme.compactPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(body)")
    }
}

struct IntroSceneView: UIViewRepresentable {
    let step: Int
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(.black)
        arView.environment.lighting.intensityExponent = -1.0
        arView.renderOptions = [
            .disableMotionBlur, .disableCameraGrain, .disableFaceMesh,
            .disableAREnvironmentLighting, .disableGroundingShadows
        ]
        arView.isUserInteractionEnabled = false
        
        context.coordinator.setupScenes(in: arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.currentStep != step {
            context.coordinator.setStep(step)
        }
    }
    
    func makeCoordinator() -> IntroSceneCoordinator {
        IntroSceneCoordinator()
    }
}

@MainActor
class IntroSceneCoordinator {
    var currentStep: Int = 0
    
    var stepOneRoot: Entity?
    var stepTwoRoot: Entity?
    
    var stepOneSatellite: ModelEntity?
    var stepOneDebrisCluster: Entity?
    var stepOneDebrisPieces: [ModelEntity] = []
    
    var collisionSatA: ModelEntity?
    var collisionSatB: ModelEntity?
    var debrisA: [ModelEntity] = []
    var debrisB: [ModelEntity] = []
    var velA: [SIMD3<Float>] = []
    var velB: [SIMD3<Float>] = []
    var rotAxesA: [SIMD3<Float>] = []
    var rotAxesB: [SIMD3<Float>] = []
    var collisionTime: Float = 0
    
    var cancellables = Set<AnyCancellable>()
    
    private let xOffset: Float = -0.08
    
    func setupScenes(in arView: ARView) {
        let anchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anchor)
        
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 30
        camera.transform.translation = [0, 0, 3.2]
        anchor.addChild(camera)
        
        let sun = DirectionalLight()
        sun.light.intensity = 4000
        sun.look(at: [0, 0, 0], from: [3, 2, -2], relativeTo: nil)
        anchor.addChild(sun)
        
        let root1 = Entity()
        let root2 = Entity()
        anchor.addChild(root1)
        anchor.addChild(root2)
        
        stepOneRoot = root1
        stepTwoRoot = root2
        
        buildStepOne(in: root1)
        buildStepTwo(in: root2)
        
        root1.isEnabled = true
        root2.isEnabled = false
        
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.updateAnimations(dt: Float(event.deltaTime))
        }.store(in: &cancellables)
    }
    
    func setStep(_ newStep: Int) {
        self.currentStep = newStep
        if newStep == 0 {
            stepTwoRoot?.isEnabled = false
            stepOneRoot?.isEnabled = true
        } else {
            stepOneRoot?.isEnabled = false
            stepTwoRoot?.isEnabled = true
            resetCollisionState()
        }
    }
    
    
    private func buildStepOne(in root: Entity) {
        let satMat = UnlitMaterial(color: .green)
        let satellite = ModelEntity(mesh: .generateBox(size: 0.14), materials: [satMat])
        satellite.position = [xOffset, 0.45, 0]
        root.addChild(satellite)
        stepOneSatellite = satellite
        
        let cluster = Entity()
        cluster.position = [xOffset, -0.45, 0]
        root.addChild(cluster)
        stepOneDebrisCluster = cluster
        
        let debrisMat = UnlitMaterial(color: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0))
        for _ in 0..<18 {
            let size = Float.random(in: 0.02...0.05)
            let d = ModelEntity(mesh: .generateDebrisTetrahedron(size: size), materials: [debrisMat])
            d.position = SIMD3<Float>(
                Float.random(in: -0.25...0.25), Float.random(in: -0.25...0.25), Float.random(in: -0.15...0.15)
            )
            d.transform.rotation = simd_quatf(
                angle: Float.random(in: 0...(2 * .pi)),
                axis: normalize([Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)])
            )
            cluster.addChild(d)
            stepOneDebrisPieces.append(d)
        }
    }
    
    private func buildStepTwo(in root: Entity) {
        let satMat = UnlitMaterial(color: .green)
        let boxSize: Float = 0.14
        
        let satA = ModelEntity(mesh: .generateBox(size: boxSize), materials: [satMat])
        let satB = ModelEntity(mesh: .generateBox(size: boxSize), materials: [satMat])
        root.addChild(satA)
        root.addChild(satB)
        collisionSatA = satA
        collisionSatB = satB
        
        let debrisMat = UnlitMaterial(color: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0))
        let debrisPerSat = 14
        
        for _ in 0..<debrisPerSat {
            let size = Float.random(in: 0.02...0.05)
            
            let dA = ModelEntity(mesh: .generateDebrisTetrahedron(size: size), materials: [debrisMat])
            dA.isEnabled = false
            root.addChild(dA)
            debrisA.append(dA)
            velA.append(.zero)
            rotAxesA.append(.zero)
            
            let dB = ModelEntity(mesh: .generateDebrisTetrahedron(size: size), materials: [debrisMat])
            dB.isEnabled = false
            root.addChild(dB)
            debrisB.append(dB)
            velB.append(.zero)
            rotAxesB.append(.zero)
        }
        
        regenerateCollisionTrajectories()
    }
    
    
    private func updateAnimations(dt: Float) {
        if stepOneRoot?.isEnabled == true {
            stepOneSatellite?.transform.rotation *= simd_quatf(angle: 0.5 * dt, axis: normalize([0.2, 1.0, 0.15]))
            stepOneDebrisCluster?.transform.rotation *= simd_quatf(angle: 0.2 * dt, axis: normalize([0.1, 1, 0.15]))
            for d in stepOneDebrisPieces {
                d.transform.rotation *= simd_quatf(angle: 0.8 * dt, axis: normalize([0.6, 1, 0.3]))
            }
        }
        
        if stepTwoRoot?.isEnabled == true {
            collisionTime += dt
            
            let approachDuration: Float = 2.0
            let explosionDuration: Float = 2.5
            let holdDuration: Float = 0.5
            let resetDuration: Float = 0.3
            let cycleDuration = approachDuration + explosionDuration + holdDuration + resetDuration
            
            let t = collisionTime.truncatingRemainder(dividingBy: cycleDuration)
            
            let startA = SIMD3<Float>(xOffset, 1.8, 0)
            let startB = SIMD3<Float>(xOffset, -1.8, 0)
            let targetA = SIMD3<Float>(xOffset, 0.07, 0)
            let targetB = SIMD3<Float>(xOffset, -0.07, 0)
            let contactPoint = SIMD3<Float>(xOffset, 0, 0)
            
            if t < approachDuration {
                let progress = t / approachDuration
                let eased = progress * progress * (3.0 - 2.0 * progress)
                
                collisionSatA?.isEnabled = true
                collisionSatB?.isEnabled = true
                collisionSatA?.position = startA + (targetA - startA) * eased
                collisionSatB?.position = startB + (targetB - startB) * eased
                
                for d in debrisA { d.isEnabled = false }
                for d in debrisB { d.isEnabled = false }
                
            } else if t < approachDuration + explosionDuration {
                let explosionT = t - approachDuration
                let progress = explosionT / explosionDuration
                
                collisionSatA?.isEnabled = false
                collisionSatB?.isEnabled = false
                
                for (i, d) in debrisA.enumerated() {
                    d.isEnabled = true
                    d.position = contactPoint + velA[i] * progress * 2.5
                    d.transform.rotation *= simd_quatf(angle: 2.0 * dt, axis: rotAxesA[i])
                }
                for (i, d) in debrisB.enumerated() {
                    d.isEnabled = true
                    d.position = contactPoint + velB[i] * progress * 2.5
                    d.transform.rotation *= simd_quatf(angle: 2.0 * dt, axis: rotAxesB[i])
                }
                
            } else if t < approachDuration + explosionDuration + holdDuration {
                collisionSatA?.isEnabled = false
                collisionSatB?.isEnabled = false
                
            } else {
                collisionSatA?.position = startA
                collisionSatB?.position = startB
                collisionSatA?.isEnabled = true
                collisionSatB?.isEnabled = true
                for d in debrisA { d.isEnabled = false }
                for d in debrisB { d.isEnabled = false }
                
                collisionTime = 0
                regenerateCollisionTrajectories()
            }
        }
    }
    
    
    private func resetCollisionState() {
        collisionTime = 0
        collisionSatA?.isEnabled = true
        collisionSatB?.isEnabled = true
        for d in debrisA { d.isEnabled = false }
        for d in debrisB { d.isEnabled = false }
        regenerateCollisionTrajectories()
    }
    
    private func regenerateCollisionTrajectories() {
        func randomSpread() -> SIMD3<Float> {
            SIMD3<Float>(Float.random(in: -0.4...0.4), Float.random(in: -0.4...0.4), Float.random(in: -0.2...0.2))
        }
        func randomAxis() -> SIMD3<Float> {
            normalize([Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)])
        }
        
        for i in 0..<debrisA.count {
            let bA = SIMD3<Float>(0, -1.0, 0) + randomSpread()
            velA[i] = normalize(bA) * Float.random(in: 0.4...0.9)
            rotAxesA[i] = randomAxis()
            
            let bB = SIMD3<Float>(0, 1.0, 0) + randomSpread()
            velB[i] = normalize(bB) * Float.random(in: 0.4...0.9)
            rotAxesB[i] = randomAxis()
        }
    }
}
