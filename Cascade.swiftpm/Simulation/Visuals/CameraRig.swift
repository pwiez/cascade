//
//  CameraRig.swift
//  Cascade
//
//  Created by Pedro Wiezel on 13/02/26.
//

import RealityKit
import simd
import Foundation

@MainActor
class CameraRig {
    
    let pivot: Entity
    let camera: Entity
    
    
    private var zoomLevel: Float = 555.0 
    private var angleX: Float = -0.35
    private var angleY: Float = 3.25
    
    private var currentAspectRatio: Float = 1.77 
    private var targetScreenOffset: Float = 0.0
    
    private var savedTransform: Transform?
    private var savedZoom: Float?
    private var savedAngleX: Float?
    private var savedAngleY: Float?
    
    
    private let minZoom: Float = 190.0
    private let maxZoom: Float = 1200.0
    private let minAngleX: Float = -1.4
    private let maxAngleX: Float = 1.4
    
    
    init(rootAnchor: Entity) {
        self.pivot = Entity()
        self.camera = Entity()
        
        
        var cameraComponent = PerspectiveCameraComponent(near: 0.1, far: 3000)
        cameraComponent.fieldOfViewInDegrees = 40.0 
        camera.components.set(cameraComponent)
        
        pivot.addChild(camera)
        rootAnchor.addChild(pivot)
        
        
        updateTransform()
        updatePosition(animated: false)
    }
    
    func rotate(deltaX: Float, deltaY: Float) {
        angleX = max(minAngleX, min(maxAngleX, angleX + deltaX))
        angleY += deltaY
        updateTransform()
    }

    func zoom(scaleFactor: Float) {
        let newZoom = zoomLevel / scaleFactor
        zoomLevel = max(minZoom, min(maxZoom, newZoom))
        updatePosition(animated: false)
    }

    func focusOn(position: SIMD3<Float>) {
        saveState()
        let direction = normalize(position)
        let targetRotation = simd_quatf(from: SIMD3(0,0,1), to: direction)
        let distanceToCenter = length(position)
        let targetZoom = distanceToCenter + 40.0
        let pivotTarget = Transform(scale: .one, rotation: targetRotation, translation: .zero)
        pivot.move(to: pivotTarget, relativeTo: pivot.parent, duration: 1.5, timingFunction: .easeInOut)
        let cameraTarget = Transform(scale: .one, rotation: .init(), translation: SIMD3(0, 0, targetZoom))
        camera.move(to: cameraTarget, relativeTo: pivot, duration: 1.5, timingFunction: .easeInOut)
    }

    func restoreState() {
        guard let savedT = savedTransform,
              let z = savedZoom,
              let ax = savedAngleX,
              let ay = savedAngleY else { return }
        
        pivot.move(to: savedT, relativeTo: pivot.parent, duration: 1.0, timingFunction: .easeInOut)
        let cameraTarget = Transform(scale: .one, rotation: .init(), translation: SIMD3(0, 0, z))
        camera.move(to: cameraTarget, relativeTo: pivot, duration: 1.5, timingFunction: .easeInOut)
        self.angleX = ax
        self.angleY = ay
        self.zoomLevel = z
    }
    
    private func saveState() {
        self.savedTransform = pivot.transform
        self.savedZoom = zoomLevel
        self.savedAngleX = angleX
        self.savedAngleY = angleY
    }
    
    func reset() {
        self.angleX = -0.35
        self.angleY = 3.25
        self.zoomLevel = 555.0
        
        let targetOrientation = simd_quatf(angle: angleY, axis: [0, 1, 0]) * simd_quatf(angle: angleX, axis: [1, 0, 0])
        pivot.move(to: Transform(rotation: targetOrientation), relativeTo: pivot.parent, duration: 1.5, timingFunction: .easeInOut)
        
        updatePosition(animated: true, duration: 1.5)
    }
    
    func setTargetOffset(ratio: Float, aspectRatio: Float) {
        self.targetScreenOffset = ratio
        self.currentAspectRatio = aspectRatio
        updatePosition(animated: true)
    }
    
    private func updateTransform() {
        let rotationY = simd_quatf(angle: angleY, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: angleX, axis: [1, 0, 0])
        pivot.orientation = rotationY * rotationX
    }
    
    private func updatePosition(animated: Bool, duration: TimeInterval = 0.4) {
        let verticalFOVScalar: Float = 0.7279
        let worldWidthAtZoom = zoomLevel * verticalFOVScalar * currentAspectRatio
        let targetX = worldWidthAtZoom * targetScreenOffset
        
        let targetTransform = Transform(scale: .one, rotation: .init(), translation: SIMD3<Float>(targetX, 0, zoomLevel))
        
        if animated {
            camera.move(to: targetTransform, relativeTo: pivot, duration: duration, timingFunction: .easeInOut)
        } else {
            camera.transform = targetTransform
        }
    }
}
