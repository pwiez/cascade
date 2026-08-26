//
//  CameraRig.swift
//  Cascade
//
//  Created by Pedro Wiezel on 13/02/26.
//

import Foundation
import RealityKit
import simd

@MainActor
final class CameraRig {

    let pivot: Entity
    let camera: Entity

    private var zoomLevel = Defaults.zoom
    private var angleX = Defaults.angleX
    private var angleY = Defaults.angleY

    private var currentAspectRatio: Float = 1.77
    private var targetScreenOffset: Float = 0

    private enum Defaults {
        static let zoom: Float = 850
        static let angleX: Float = -0.35
        static let angleY: Float = 3.25
    }

    private let zoomRange: ClosedRange<Float> = 450...1800

    private let pitchRange: ClosedRange<Float> = -1.4...1.4

    private static let verticalFOVScalar: Float = 0.9755

    init(rootAnchor: Entity) {
        pivot = Entity()
        camera = Entity()

        var component = PerspectiveCameraComponent(near: 0.1, far: 3000)
        component.fieldOfViewInDegrees = 52.0
        camera.components.set(component)

        pivot.addChild(camera)
        rootAnchor.addChild(pivot)

        updateOrientation()
        updatePosition(animated: false)
    }

    func rotate(deltaX: Float, deltaY: Float) {
        angleX = min(max(angleX + deltaX, pitchRange.lowerBound), pitchRange.upperBound)
        angleY += deltaY
        updateOrientation()
    }

    func zoom(scaleFactor: Float) {
        guard scaleFactor > 0 else { return }
        zoomLevel = min(max(zoomLevel / scaleFactor, zoomRange.lowerBound), zoomRange.upperBound)
        updatePosition(animated: false)
    }

    func reset() {
        angleX = Defaults.angleX
        angleY = Defaults.angleY
        zoomLevel = Defaults.zoom

        pivot.move(to: Transform(rotation: orientation()),
                   relativeTo: pivot.parent,
                   duration: 1.5,
                   timingFunction: .easeInOut)
        updatePosition(animated: true, duration: 1.5)
    }

    func setTargetOffset(ratio: Float, aspectRatio: Float) {
        targetScreenOffset = ratio
        currentAspectRatio = aspectRatio
        updatePosition(animated: true)
    }

    private func orientation() -> simd_quatf {
        simd_quatf(angle: angleY, axis: [0, 1, 0]) * simd_quatf(angle: angleX, axis: [1, 0, 0])
    }

    private func updateOrientation() {
        pivot.orientation = orientation()
    }

    private func updatePosition(animated: Bool, duration: TimeInterval = 0.4) {
        let worldWidth = zoomLevel * Self.verticalFOVScalar * currentAspectRatio
        let transform = Transform(
            scale: .one,
            rotation: .init(),
            translation: SIMD3(worldWidth * targetScreenOffset, 0, zoomLevel)
        )

        if animated {
            camera.move(to: transform, relativeTo: pivot, duration: duration, timingFunction: .easeInOut)
        } else {
            camera.transform = transform
        }
    }
}
