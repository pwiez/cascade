import SwiftUI
import SceneKit

enum BodyType { case leo, meo, geo, debris }

struct SpaceFact: Identifiable, Equatable {
    let id = UUID()
    let title, description, icon: String
}

class PhysicsBody: Identifiable {
    let id = UUID()
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var radius: Float
    var type: BodyType
    var node: SCNNode
    var isDebris: Bool { return type == .debris }
    
    init(node: SCNNode, pos: SIMD3<Float>, vel: SIMD3<Float>, radius: Float, type: BodyType) {
        self.node = node
        self.position = pos
        self.velocity = vel
        self.radius = radius
        self.type = type
        self.node.position = SCNVector3(pos.x, pos.y, pos.z)
    }
}

class Simulation: NSObject, SCNSceneRendererDelegate, ObservableObject {
    @Published var currentFact: SpaceFact? = nil
    @Published var isPaused: Bool = false
    
    @Published var leoCount: Double = 24 { didSet { needsRespawn = true } }
    @Published var meoCount: Double = 24 { didSet { needsRespawn = true } }
    @Published var debrisPerCrash: Double = 50
    @Published var explosionForce: Double = 1.0
    
    @Published var debrisCount: Int = 0
    @Published var leoRemaining: Int = 0
    @Published var meoRemaining: Int = 0
    @Published var geoRemaining: Int = 0
    var totalSatellites: Int { leoRemaining + meoRemaining + geoRemaining }
    
    @Published var spreadX: Double = 0.5
    @Published var spreadY: Double = 1
    @Published var spreadZ: Double = 0.5
    
    var needsRespawn = false
    var scene: SCNScene
    var satellites: [PhysicsBody] = []
    var debris: [PhysicsBody] = []
    
    let earthRadius: Float = 100.0
    let G: Float = 1.0
    let earthMass: Float = 50000
    let fixedDeltaTime: Float = 1.0 / 30
    let MAX_DEBRIS = 3000
    
    var hasIntroShown = false
    var hasCrashed = false
    var hasCascadeStarted = false
    var hasShownSafeFact = false
    var hasShownDragFact = false
    var timeSinceStart: TimeInterval = 0
    var detonationQueued = false
    
    lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        node.camera = SCNCamera()
        node.camera?.zFar = 5000
        node.camera?.zNear = 1.0
        node.position = SCNVector3(0, 400, 400)
        node.look(at: SCNVector3(0,0,0))
        return node
    }()
    
    let debrisGeometry: SCNGeometry = {
        let geo = SCNPyramid(width: 1.5, height: 1.5, length: 1.5)
        geo.firstMaterial?.diffuse.contents = UIColor.white
        return geo
    }()
    let orangeGeometry: SCNGeometry = {
        let geo = SCNPyramid(width: 0.5, height: 0.5, length: 0.5)
        geo.firstMaterial?.diffuse.contents = UIColor.orange; geo.firstMaterial?.emission.contents = UIColor.orange; return geo
    }()
    let redGeometry: SCNGeometry = {
        let geo = SCNPyramid(width: 0.5, height: 0.5, length: 0.5)
        geo.firstMaterial?.diffuse.contents = UIColor.red; geo.firstMaterial?.emission.contents = UIColor.red; return geo
    }()
    let boxGeometry: SCNGeometry = {
        let geo = SCNBox(width: 4.0, height: 4.0, length: 4.0, chamferRadius: 0.5)
        return geo
    }()
    
    override init() {
        self.scene = SCNScene()
        super.init()
        setupScene()
        setupUniverse()
    }
    
    func setupScene() {
        scene.background.contents = UIColor.black
        let sun = SCNNode(); sun.light = SCNLight(); sun.light?.type = .omni; sun.light?.intensity = 1500; sun.position = SCNVector3(100, 100, 100)
        scene.rootNode.addChildNode(sun)
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 300
        scene.rootNode.addChildNode(ambient)
        
        let earthGeo = SCNSphere(radius: CGFloat(earthRadius))
        earthGeo.firstMaterial?.diffuse.contents = UIColor.systemBlue
        earthGeo.firstMaterial?.emission.contents = UIColor.systemBlue.withAlphaComponent(0.2)
        earthGeo.segmentCount = 80
        scene.rootNode.addChildNode(SCNNode(geometry: earthGeo))
    }
    
    func resetSimulation() {
        for body in satellites { body.node.removeFromParentNode() }
        for body in debris { body.node.removeFromParentNode() }
        satellites.removeAll()
        debris.removeAll()
        hasIntroShown = false; hasCrashed = false; hasCascadeStarted = false
        hasShownSafeFact = false; hasShownDragFact = false; timeSinceStart = 0
        setupUniverse()
        needsRespawn = false
    }
    
    func setupUniverse() {
        createRing(radius: 140.0, count: Int(leoCount), color: .purple, speedMult: 1.0, offset: -0.11, type: .leo)
        createRing(radius: 240.0, count: Int(meoCount), color: .green, speedMult: -1.0, offset: 0.0, type: .meo)
        createRing(radius: 480, count: 12, color: .yellow, speedMult: 1.0, offset: 0.0, type: .geo)
    }
    
    func createRing(radius: Float, count: Int, color: UIColor, speedMult: Float, offset: Float, type: BodyType) {
        let vOrbit = sqrt((G * earthMass) / radius) * speedMult
        
        for i in 0..<count {
            let angle = (Float(i) / Float(count)) * 2 * .pi + offset
            
            let inclination = Float.random(in: -1...1)
            
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let y = z * tan(inclination)
            
            let pos = SIMD3<Float>(x, y, z)
            
            let tangent = normalize(SIMD3<Float>(-sin(angle), 0, cos(angle)))
            let vel = tangent * vOrbit
            
            createSatellite(pos: pos, vel: vel, color: color, type: type)
        }
    }
    
    func createSatellite(pos: SIMD3<Float>, vel: SIMD3<Float>, color: UIColor, type: BodyType) {
        let geo = boxGeometry.copy() as! SCNGeometry
        geo.firstMaterial = boxGeometry.firstMaterial?.copy() as? SCNMaterial
        geo.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: geo)
        scene.rootNode.addChildNode(node)
        satellites.append(PhysicsBody(node: node, pos: pos, vel: vel, radius: 1, type: type))
    }
    
    func requestDetonation() { detonationQueued = true }
    
    private func performSafeDetonation() {
        let targets = satellites.filter { $0.type == .leo || $0.type == .meo }
        guard let victim = targets.randomElement() else { return }
        victim.node.isHidden = true
        
        if !hasCrashed {
            hasCrashed = true
            DispatchQueue.main.async { self.triggerFact(title: "Kessler Syndrome Initiated", description: "You have detonated a satellite. The debris field is now active.", icon: "exclamationmark.triangle.fill") }
        }
        spawnExplosion(at: victim.position, velocity: victim.velocity)
    }
    
    func spawnExplosion(at pos: SIMD3<Float>, velocity: SIMD3<Float>) {
        let baseVelocity = velocity
        
        let forward = normalize(velocity)
        let up = normalize(pos)
        let right = cross(forward, up)
        
        let sx = Float(spreadX)
        let sy = Float(spreadY)
        let sz = Float(spreadZ)
        let force = Float(explosionForce)
        
        for _ in 0...Int(debrisPerCrash) {
            let rndX = Float.random(in: -sx...sx)
            let rndY = Float.random(in: -sy...sy)
            let rndZ = Float.random(in: -sz...sz)
            
            let kickVector = (forward * rndX + right * rndY + up * rndZ) * force
            
            let finalVel = baseVelocity + kickVector
            
            let node = SCNNode(geometry: debrisGeometry)
            node.position = SCNVector3(pos.x, pos.y, pos.z)
            node.eulerAngles = SCNVector3(Float.random(in: 0...3), Float.random(in: 0...3), 0)
            scene.rootNode.addChildNode(node)
            debris.append(PhysicsBody(node: node, pos: pos, vel: finalVel, radius: 1, type: .debris))
        }
    }
    
    func triggerFact(title: String, description: String, icon: String) {
        isPaused = true
        currentFact = SpaceFact(title: title, description: description, icon: icon)
    }
    
    func resumeSimulation() { isPaused = false; currentFact = nil }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isPaused { return }
        if needsRespawn { DispatchQueue.main.async { self.resetSimulation() }; return }
        timeSinceStart += TimeInterval(fixedDeltaTime)
        if detonationQueued { performSafeDetonation(); detonationQueued = false }
        
        if timeSinceStart > 0.5 && !hasIntroShown {
            hasIntroShown = true
            DispatchQueue.main.async { self.triggerFact(title: "Systems Nominal", description: "Orbits are stable. Use 'Detonate' to start the chaos.", icon: "checkmark.circle.fill") }
        }
        
        for i in (0..<satellites.count).reversed() {
            let body = satellites[i]
            if body.node.isHidden { body.node.removeFromParentNode(); satellites.remove(at: i); continue }
            updatePhysics(body: body)
            if length(body.position) < earthRadius { body.node.removeFromParentNode(); satellites.remove(at: i) }
        }
        
        if debris.count > MAX_DEBRIS { let c = debris.count - MAX_DEBRIS; for _ in 0..<c { debris.first?.node.removeFromParentNode(); debris.removeFirst() } }
        
        for i in (0..<debris.count).reversed() {
            let body = debris[i]
            let r = length(body.position)
            if r < earthRadius { body.node.removeFromParentNode(); debris.remove(at: i); continue }
            else if r < (earthRadius + 4) { body.velocity *= 0.96; if body.node.geometry !== redGeometry { body.node.geometry = redGeometry } }
            else if r < (earthRadius + 8) { body.velocity *= 0.99; if body.node.geometry !== orangeGeometry { body.node.geometry = orangeGeometry } }
            else { if body.node.geometry !== debrisGeometry { body.node.geometry = debrisGeometry } }
            updatePhysics(body: body)
        }
        
        var collisions: [(SIMD3<Float>, SIMD3<Float>)] = []
        if satellites.count > 1 {
            for i in 0..<satellites.count {
                for j in (i+1)..<satellites.count { checkCollision(b1: satellites[i], b2: satellites[j], collisions: &collisions) }
            }
        }
        for sat in satellites {
            for rock in debris { checkCollision(b1: sat, b2: rock, collisions: &collisions) }
        }
        for (pos, vel) in collisions { spawnExplosion(at: pos, velocity: vel) }
        
        DispatchQueue.main.async {
            self.debrisCount = self.debris.count
            self.leoRemaining = self.satellites.filter { $0.type == .leo }.count
            self.meoRemaining = self.satellites.filter { $0.type == .meo }.count
            self.geoRemaining = self.satellites.filter { $0.type == .geo }.count
        }
    }
    
    func updatePhysics(body: PhysicsBody) {
        let dt = fixedDeltaTime
        
        let pos = body.position
        let rSq = length_squared(pos)
        let accel1 = -normalize(pos) * (G * earthMass / rSq)
        
        body.position += (body.velocity * dt) + (0.5 * accel1 * dt * dt)
        
        let newRSq = length_squared(body.position)
        let accel2 = -normalize(body.position) * (G * earthMass / newRSq)
        
        body.velocity += 0.5 * (accel1 + accel2) * dt
        
        let altitude = sqrt(newRSq) - earthRadius
        if altitude < 10.0 {
            let dragStrength = exp(-altitude / 2.0) * 0.02
            body.velocity *= (1.0 - dragStrength)
        }
        
        body.node.position = SCNVector3(body.position.x, body.position.y, body.position.z)
        if body.isDebris { body.node.eulerAngles.x += 0.1 }
    }
    
    func checkCollision(b1: PhysicsBody, b2: PhysicsBody, collisions: inout [(SIMD3<Float>, SIMD3<Float>)]) {
        if b1.node.isHidden || b2.node.isHidden { return }
        let distSq = length_squared(b1.position - b2.position)
        let radSum = b1.radius + b2.radius + 0.5
        if distSq < (radSum * radSum) {
            b1.node.isHidden = true; b2.node.isHidden = true
            collisions.append((b1.position, b1.velocity))
            if !hasCrashed { hasCrashed = true; DispatchQueue.main.async { self.triggerFact(title: "Collision", description: "Debris impact confirmed.", icon: "burst.fill") } }
            else if !hasCascadeStarted { hasCascadeStarted = true; DispatchQueue.main.async { self.triggerFact(title: "Chain Reaction", description: "The Kessler Syndrome has begun.", icon: "exclamationmark.triangle.fill") } }
        }
    }
}

enum MenuSelection: String, CaseIterable, Identifiable {
    case simulation = "Simulation"
    case settings = "Parameters"
    case encyclopedia = "Encyclopedia"
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .simulation: return "play.circle.fill"
        case .settings: return "slider.horizontal.3"
        case .encyclopedia: return "book.fill"
        }
    }
}

struct EncyclopediaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading) { Text("The Kessler Syndrome").font(.largeTitle).bold().foregroundStyle(.blue); Text("A Cascade of Chaos").font(.title3).foregroundStyle(.secondary) }
                FactCard(title: "What is it?", content: "A scenario where the density of objects in LEO becomes so high that collisions generate debris that increases the likelihood of further collisions.")
                Text("Simulation vs. Reality").font(.title2).bold().padding(.top)
                VStack(spacing: 15) {
                    CompromiseRow(icon: "clock.arrow.circlepath", title: "Time", desc: "Real collisions take decades. We sped this up by 10,000x.")
                    CompromiseRow(icon: "arrow.up.left.and.arrow.down.right", title: "Scale", desc: "Earth is 2x larger and satellites are 1000x larger for visibility.")
                }
            }.padding(40)
        }
    }
}

struct FactCard: View {
    let title: String, content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); Text(content).font(.body).foregroundStyle(.secondary) }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
    }
}

struct CompromiseRow: View {
    let icon: String, title: String, desc: String
    var body: some View {
        HStack(alignment: .top) { Image(systemName: icon).font(.title2).frame(width: 30).foregroundStyle(.blue); VStack(alignment: .leading) { Text(title).bold(); Text(desc).font(.callout).foregroundStyle(.secondary) } }
    }
}

struct SettingsView: View {
    @ObservedObject var simulation: Simulation
    var body: some View {
        Form {
            Section(header: Text("Population (Resets Sim)")) {
                Stepper("LEO Satellites: \(Int(simulation.leoCount))", value: $simulation.leoCount, in: 4...24)
                Stepper("MEO Satellites: \(Int(simulation.meoCount))", value: $simulation.meoCount, in: 4...24)
            }
            Section(header: Text("Physics (Real-time)")) {
                VStack(alignment: .leading) { Text("Debris per Crash: \(Int(simulation.debrisPerCrash))"); Slider(value: $simulation.debrisPerCrash, in: 5...75, step: 5) }
                VStack(alignment: .leading) { Text("Explosion Force: \(String(format: "%.1f", simulation.explosionForce))x"); Slider(value: $simulation.explosionForce, in: 0.0...5.0, step: 0.1) }
            }
            Section(header: Text("Debris Spread (Direction)")) {
                VStack(alignment: .leading) { Text("Tangential (Forward/Back): \(String(format: "%.2f", simulation.spreadX))"); Slider(value: $simulation.spreadX, in: 0.0...5.0) }
                VStack(alignment: .leading) { Text("Vertical (Up/Down): \(String(format: "%.2f", simulation.spreadY))"); Slider(value: $simulation.spreadY, in: 0.0...5.0) }
                VStack(alignment: .leading) { Text("Radial (In/Out): \(String(format: "%.2f", simulation.spreadZ))"); Slider(value: $simulation.spreadZ, in: 0.0...5.0) }
            }
            Section { Button("Respawn Simulation", role: .destructive) { simulation.resetSimulation() } }
        }
    }
}

struct MetricsHUD: View {
    @ObservedObject var sim: Simulation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ORBITAL STATUS").font(.caption).bold().opacity(0.7)
            
            MetricRow(label: "Debris", value: sim.debrisCount, color: .white)
            MetricRow(label: "Satellites", value: sim.totalSatellites, color: .cyan)
            
            Divider().background(.white.opacity(0.3))
            
            Group {
                MetricRow(label: "LEO", value: sim.leoRemaining, color: .purple)
                MetricRow(label: "MEO", value: sim.meoRemaining, color: .green)
                MetricRow(label: "GEO", value: sim.geoRemaining, color: .yellow)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 180)
    }
}

struct MetricRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(label).font(.system(.subheadline, design: .monospaced))
            Spacer()
            Text("\(value)")
                .font(.system(.subheadline, design: .monospaced))
                .bold()
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }
}

struct ContentView: View {
    @StateObject var simulation = Simulation()
    @State private var selectedMenu: MenuSelection? = .simulation
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(MenuSelection.allCases, selection: $selectedMenu) { item in
                NavigationLink(value: item) { Label(item.rawValue, systemImage: item.icon) }
            }
            .navigationTitle("Orbital Guard")
        } detail: {
            ZStack {
                SceneView(
                    scene: simulation.scene,
                    pointOfView: simulation.cameraNode,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting, .rendersContinuously],
                    delegate: simulation
                )
                .ignoresSafeArea()
                
                VStack {
                    HStack{
                        Spacer()
                        MetricsHUD(sim: simulation)
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
                
                
                if let selected = selectedMenu, selected != .simulation {
                    Color.black.opacity(0.6).ignoresSafeArea()
                        .overlay {
                            switch selected {
                            case .settings: SettingsView(simulation: simulation).frame(maxWidth: 500, maxHeight: 700).cornerRadius(20)
                            case .encyclopedia: EncyclopediaView().frame(maxWidth: 600, maxHeight: 700).background(.thickMaterial).cornerRadius(20)
                            default: EmptyView()
                            }
                        }
                } else {
                    VStack {
                        if columnVisibility != .detailOnly {
                            Spacer()
                            Text("SIMULATION PAUSED").font(.system(size: 24, weight: .heavy, design: .monospaced)).foregroundStyle(.white).padding().background(.ultraThinMaterial).cornerRadius(12)
                            Spacer()
                        } else {
                            Spacer()
                            Button(action: { simulation.requestDetonation() }) {
                                HStack { Image(systemName: "exclamationmark.triangle.fill"); Text("Detonate LEO/MEO") }
                                    .padding().foregroundStyle(.white).background(.red.opacity(0.8)).cornerRadius(20).shadow(radius: 10)
                            }
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                
                if let fact = simulation.currentFact {
                    Color.black.opacity(0.6).ignoresSafeArea().onTapGesture {}
                    VStack(spacing: 20) {
                        Image(systemName: fact.icon).font(.system(size: 50)).foregroundStyle(.blue)
                        Text(fact.title).font(.title).bold()
                        Text(fact.description).multilineTextAlignment(.center).foregroundStyle(.secondary)
                        Button("Resume") { withAnimation { simulation.resumeSimulation() } }
                            .padding().frame(maxWidth: .infinity).background(Color.blue).foregroundStyle(.white).cornerRadius(10)
                    }
                    .padding(30).background(.regularMaterial).cornerRadius(20).frame(maxWidth: 400).shadow(radius: 20)
                }
            }
            .onChange(of: columnVisibility) { newValue in simulation.isPaused = (newValue != .detailOnly) }
            .onChange(of: selectedMenu) { newValue in
                if newValue != .simulation { simulation.isPaused = true }
                else if columnVisibility == .detailOnly { simulation.isPaused = false }
            }
        }
    }
}
