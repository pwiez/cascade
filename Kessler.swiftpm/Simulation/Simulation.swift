import SwiftUI
import SceneKit

struct SimSettings {
    var debrisPerCrash: Double = 0
    var explosionForce: Double = 0
    var collisionRadius: Double = 0
    var spreadTangential: Double = 0
    var spreadVertical: Double = 0
    var spreadRadial: Double = 0
    var timeScale: Double = 0
}

struct SimStats {
    var debris: Int = 0
    var satellites: Int = 0
}

enum EngineCommand {
    case reset(Int)
    case detonate
    case updateSettings(SimSettings)
}

@MainActor
class Simulation: NSObject, SCNSceneRendererDelegate, ObservableObject {
    
    @Published var currentFact: SpaceFact? = nil
    @Published var isPaused: Bool = false
    
    @Published var leoCount: Double = 1024 { didSet { pushSettings() } }
    @Published var debrisPerCrash: Double = 4 { didSet { pushSettings() } }
    @Published var explosionForce: Double = 1.1 { didSet { pushSettings() } }
    @Published var collisionRadius: Double = 1.5 { didSet { pushSettings() } }
    @Published var spreadTangential: Double = 1 { didSet { pushSettings() } }
    @Published var spreadVertical: Double = 0.6 { didSet { pushSettings() } }
    @Published var spreadRadial: Double = 0.2 { didSet { pushSettings() } }
    @Published var timeScale: Double = 0.1 { didSet { pushSettings() } }
    
    @Published var debrisCount: Int = 0
    @Published var leoRemaining: Int = 0
    
    nonisolated let engine = PhysicsEngine()
    
    var scene: SCNScene { engine.scene }
    var cameraNode: SCNNode { engine.cameraNode }
    
    override init() {
        super.init()
        engine.sendCommand(.reset(1024))
        pushSettings()
    }
    
    func pushSettings() {
        let s = SimSettings(
            debrisPerCrash: debrisPerCrash,
            explosionForce: explosionForce,
            collisionRadius: collisionRadius,
            spreadTangential: spreadTangential,
            spreadVertical: spreadVertical,
            spreadRadial: spreadRadial,
            timeScale: timeScale
        )
        engine.sendCommand(.updateSettings(s))
    }
    
    func requestDetonation() {
        engine.sendCommand(.detonate)
    }
    
    func resetSimulation() {
        engine.sendCommand(.reset(Int(leoCount)))
    }
    
    func resetCamera() { engine.resetCamera() }
    func rotateCamera(deltaX: Float, deltaY: Float) { engine.rotateCamera(deltaX: deltaX, deltaY: deltaY) }
    func zoomCamera(scaleFactor: Float) { engine.zoomCamera(scaleFactor: scaleFactor) }
    func resumeSimulation() { isPaused = false; currentFact = nil }

    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        engine.updateLoop()
        
        if engine.frameCounter % 15 == 0 {
            let stats = engine.latestStats
            
            Task { @MainActor in
                self.debrisCount = stats.debris
                self.leoRemaining = stats.satellites
            }
        }
    }
}

class PhysicsEngine {
    
    private let dataLock = NSLock()
    private var commandQueue: [EngineCommand] = []
    var latestStats = SimStats()
    
    let scene = SCNScene()
    let earthNode = SCNNode()
    let cameraNode = SCNNode()
    let cameraPivotNode = SCNNode()
    let sunNode = SCNNode()
    
    var satellites: [PhysicsBody] = []
    var debris: [PhysicsBody] = []
    var settings = SimSettings()
    var frameCounter = 0
    
    private var grid: [Int: [PhysicsBody]] = [:]
    private let cellSize: Float = 10.0
    
    var currentZoom: Float = 350.0
    var currentAngleX: Float = 0.4
    var currentAngleY: Float = 0.3
    
    let debrisGeometry: SCNGeometry
    let debrisSmallGeometry: SCNGeometry
    let debrisLargeGeometry: SCNGeometry
    let boxGeometry: SCNGeometry
    
    let earthRadius: Float = 100.0
    let G: Float = 1.0
    let earthMass: Float = 50000
    let leoAltitude: Float = 120.0
    let MAX_DEBRIS = 4000
    
    init() {
        debrisSmallGeometry = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0)
        debrisSmallGeometry.firstMaterial?.diffuse.contents = UIColor.gray
        
        debrisGeometry = SCNBox(width: 0.4, height: 0.4, length: 0.4, chamferRadius: 0)
        debrisGeometry.firstMaterial?.diffuse.contents = UIColor.lightGray
        
        debrisLargeGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.1)
        debrisLargeGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        boxGeometry = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)
        
        grid.reserveCapacity(2000)
        setupScene()
    }
    
    func sendCommand(_ cmd: EngineCommand) {
        dataLock.lock()
        commandQueue.append(cmd)
        dataLock.unlock()
    }
    
    private func updateStats() {
        let s = SimStats(debris: debris.count, satellites: satellites.count)
        dataLock.lock()
        latestStats = s
        dataLock.unlock()
    }
    
    func updateLoop() {
        dataLock.lock()
        let commands = commandQueue
        commandQueue.removeAll()
        dataLock.unlock()
        
        for cmd in commands {
            switch cmd {
            case .reset(let count): setupUniverse(count: count)
            case .detonate: performDetonation()
            case .updateSettings(let s): self.settings = s
            }
        }
        
        updateSatellites()
        updateDebris()
        checkCollisionsSpatial()
        
        frameCounter += 1
        if frameCounter % 15 == 0 { updateStats() }
    }
    
    func checkCollisionsSpatial() {
        grid.removeAll(keepingCapacity: true)
        
        func addToGrid(_ body: PhysicsBody) {
            if body.node.isHidden { return }
            let x = Int((body.position.x / cellSize) + 50)
            let y = Int((body.position.y / cellSize) + 50)
            let z = Int((body.position.z / cellSize) + 50)
            if x >= 0 && x < 100 && y >= 0 && y < 100 && z >= 0 && z < 100 {
                let key = x | (y << 10) | (z << 20)
                grid[key, default: []].append(body)
            }
        }
        
        for s in satellites { addToGrid(s) }
        for d in debris { addToGrid(d) }
        
        var collisions: [(SIMD3<Float>, SIMD3<Float>)] = []
        let sqThreshold = Float(settings.collisionRadius * settings.collisionRadius)
        let neighborOffsets = [0, 1, -1, 1024, -1024, 1048576, -1048576]
        
        for b1 in satellites {
            if b1.node.isHidden { continue }
            let x = Int((b1.position.x / cellSize) + 50)
            let y = Int((b1.position.y / cellSize) + 50)
            let z = Int((b1.position.z / cellSize) + 50)
            if x < 0 || x >= 100 || y < 0 || y >= 100 || z < 0 || z >= 100 { continue }
            let centerKey = x | (y << 10) | (z << 20)
            
            for offset in neighborOffsets {
                let key = centerKey + offset
                guard let bucket = grid[key] else { continue }
                for b2 in bucket {
                    if b1 === b2 { continue }
                    if !b2.isDebris && b1.id > b2.id { continue }
                    if b2.node.isHidden { continue }
                    
                    let dx = b1.position.x - b2.position.x
                    let dy = b1.position.y - b2.position.y
                    let dz = b1.position.z - b2.position.z
                    
                    if dx*dx > sqThreshold || dy*dy > sqThreshold || dz*dz > sqThreshold { continue }
                    
                    let distSq = dx*dx + dy*dy + dz*dz
                    if distSq < sqThreshold {
                        b1.node.isHidden = true
                        b2.node.isHidden = true
                        collisions.append((b1.position, b1.velocity))
                    }
                }
            }
        }
        
        for (p, v) in collisions { spawnExplosion(at: p, velocity: v) }
    }
    
    func performDetonation() {
        let targets = satellites.filter { $0.type == .leo }
        if let victim = targets.randomElement() {
            victim.node.isHidden = true
            spawnExplosion(at: victim.position, velocity: victim.velocity)
        }
    }
    
    func updateSatellites() {
        for i in (0..<satellites.count).reversed() {
            let body = satellites[i]
            if body.node.isHidden {
                body.node.removeFromParentNode(); satellites.remove(at: i); continue
            }
            updatePhysics(body: body)
            
            if length(body.position) < (earthRadius + 2.0) {
                body.node.removeFromParentNode(); satellites.remove(at: i)
            }
        }
    }
    
    func updateDebris() {
        if debris.count > MAX_DEBRIS {
            let c = debris.count - MAX_DEBRIS
            for _ in 0..<c { debris.first?.node.removeFromParentNode(); debris.removeFirst() }
        }
        
        for i in (0..<debris.count).reversed() {
            let body = debris[i]
            
            if length(body.position) < (earthRadius + 2.0) {
                body.node.removeFromParentNode()
                debris.remove(at: i)
                continue
            }
            
            updatePhysics(body: body)
        }
    }
    
    private func updatePhysics(body: PhysicsBody) {
        let dt: Float = (1.0 / 60.0) * Float(settings.timeScale)
        
        let pos = body.position
        let r2 = pos.x*pos.x + pos.y*pos.y + pos.z*pos.z
        let invR = 1.0 / sqrt(r2)
        let accelMag = -(G * earthMass) / r2
        
        let accelX = pos.x * accelMag * invR
        let accelY = pos.y * accelMag * invR
        let accelZ = pos.z * accelMag * invR
        
        body.velocity.x += accelX * dt
        body.velocity.y += accelY * dt
        body.velocity.z += accelZ * dt
        
        body.position += body.velocity * dt
        body.node.position = SCNVector3(body.position.x, body.position.y, body.position.z)
        if body.isDebris { body.node.eulerAngles.x += 0.05 }
    }
    
    private func spawnExplosion(at pos: SIMD3<Float>, velocity: SIMD3<Float>) {
        let force = Float(settings.explosionForce)
        let count = Int(settings.debrisPerCrash)
        
        let forward = normalize(velocity)
        let up = normalize(pos)
        let right = cross(forward, up)
        
        let sx = Float(settings.spreadTangential) * 1.5
        let sy = Float(settings.spreadVertical) * 0.8
        let sz = Float(settings.spreadRadial) * 0.4
        
        for _ in 0...count {
            let rndX = Float.random(in: -1...1) * sx
            let rndY = Float.random(in: -1...1) * sy
            let rndZ = Float.random(in: -1...1) * sz
            let kx = (forward.x * rndX + right.x * rndY + up.x * rndZ) * force
            let ky = (forward.y * rndX + right.y * rndY + up.y * rndZ) * force
            let kz = (forward.z * rndX + right.z * rndY + up.z * rndZ) * force
            
            let finalVel = SIMD3<Float>(velocity.x + kx, velocity.y + ky, velocity.z + kz)
            let jx = Float.random(in: -1.5...1.5)
            let jy = Float.random(in: -1.5...1.5)
            let jz = Float.random(in: -1.5...1.5)
            let finalPos = SIMD3<Float>(pos.x + jx, pos.y + jy, pos.z + jz)
            
            let roll = Float.random(in: 0...1)
            let geo: SCNGeometry
            if roll < 0.5 { geo = debrisSmallGeometry }
            else if roll < 0.9 { geo = debrisGeometry }
            else { geo = debrisLargeGeometry }
            
            let node = SCNNode(geometry: geo)
            node.castsShadow = false
            node.position = SCNVector3(finalPos.x, finalPos.y, finalPos.z)
            node.eulerAngles = SCNVector3(Float.random(in: 0...3), Float.random(in: 0...3), 0)
            
            scene.rootNode.addChildNode(node)
            debris.append(PhysicsBody(node: node, pos: finalPos, vel: finalVel, radius: 1, type: .debris))
        }
    }
    
    func setupScene() {
        scene.background.contents = UIColor.black
        sunNode.light = SCNLight(); sunNode.light?.type = .directional; sunNode.light?.intensity = 1200
        sunNode.light?.castsShadow = true; sunNode.position = SCNVector3(0, 0, 500); sunNode.eulerAngles = SCNVector3(-0.5, 0.8, 0)
        scene.rootNode.addChildNode(sunNode)
        
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 150
        scene.rootNode.addChildNode(ambient)
        
        let earthGeo = SCNSphere(radius: CGFloat(earthRadius))
        earthGeo.firstMaterial?.diffuse.contents = UIImage(named: "earthTopographicMap.heic")
        earthNode.geometry = earthGeo
        earthNode.runAction(SCNAction.repeatForever(SCNAction.rotate(by: .pi * 2, around: SCNVector3(0, 1, 0), duration: 120)))
        scene.rootNode.addChildNode(earthNode)
        
        let atmoNode = SCNNode(geometry: SCNSphere(radius: CGFloat(earthRadius) + 2))
        atmoNode.opacity = 0.2; atmoNode.geometry?.firstMaterial?.blendMode = .add
        atmoNode.castsShadow = false
        atmoNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        scene.rootNode.addChildNode(atmoNode)
        
        cameraPivotNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraPivotNode)
        cameraNode.position = SCNVector3(0, 0, currentZoom); cameraNode.camera = SCNCamera(); cameraNode.camera?.zFar = 3000
        updateCameraRotation()
    }
    
    func setupUniverse(count: Int) {
        satellites.forEach { $0.node.removeFromParentNode() }
        debris.forEach { $0.node.removeFromParentNode() }
        satellites.removeAll(); debris.removeAll()
        grid.removeAll(keepingCapacity: true)
        
        for i in 0..<count {
            let angle = (Float(i) / Float(count)) * 2 * .pi
            let r = leoAltitude + Float.random(in: -8.0...8.0)
            let x = r * cos(angle); let z = r * sin(angle)
            let vAdj = sqrt((G * earthMass) / r)
            let vx = -sin(angle) * vAdj; let vz = cos(angle) * vAdj
            
            let rot = SCNMatrix4MakeRotation(Float.random(in: -360...360), 1, 0, 0)
            let pos = SIMD3<Float>(x * rot.m11 + z * rot.m31 + rot.m41, x * rot.m12 + z * rot.m32 + rot.m42, x * rot.m13 + z * rot.m33 + rot.m43)
            let vel = SIMD3<Float>(vx * rot.m11 + vz * rot.m31, vx * rot.m12 + vz * rot.m32, vx * rot.m13 + vz * rot.m33)
            
            let node = SCNNode(geometry: boxGeometry)
            node.scale = SCNVector3(0.3, 0.3, 0.3); node.position = SCNVector3(pos.x, pos.y, pos.z); node.castsShadow = false
            node.geometry?.firstMaterial = boxGeometry.firstMaterial?.copy() as? SCNMaterial
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
            scene.rootNode.addChildNode(node)
            satellites.append(PhysicsBody(node: node, pos: pos, vel: vel, radius: 0.5, type: .leo))
        }
    }
    
    func rotateCamera(deltaX: Float, deltaY: Float) {
        currentAngleX += deltaX; currentAngleY += deltaY; currentAngleX = max(-1.4, min(1.4, currentAngleX))
        updateCameraRotation()
    }
    func zoomCamera(scaleFactor: Float) {
        currentZoom /= scaleFactor; currentZoom = max(120, min(1500, currentZoom)); cameraNode.position.z = currentZoom
    }
    func resetCamera() {
        SCNTransaction.begin(); SCNTransaction.animationDuration = 1.0; currentAngleX = 0.5; currentAngleY = 0.5; currentZoom = 350.0; updateCameraRotation(); cameraNode.position.z = currentZoom; SCNTransaction.commit()
    }
    private func updateCameraRotation() { cameraPivotNode.eulerAngles = SCNVector3(currentAngleX, currentAngleY, 0) }
}
