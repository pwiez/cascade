//
//  CameraRigTests.swift
//  CascadeEngineTests
//

import RealityKit
import Testing
import simd
@testable import CascadeEngine

@Suite("Camera controls")
@MainActor
struct CameraRigTests {
    @Test("The camera attaches to its orbit pivot with the intended projection")
    func attachesToRoot() throws {
        let root = Entity()
        let rig = CameraRig(rootAnchor: root)
        let projection = try #require(rig.camera.components[PerspectiveCameraComponent.self])

        #expect(rig.pivot.parent === root)
        #expect(rig.camera.parent === rig.pivot)
        #expect(projection.near == 0.1)
        #expect(projection.far == 3_000)
        #expect(projection.fieldOfViewInDegrees == 52)
        #expect(rig.camera.position == SIMD3(0, 0, 850))
    }

    @Test("Opposite orbit gestures restore the original view")
    func oppositeRotationsCancel() {
        let rig = CameraRig(rootAnchor: Entity())
        let original = rig.pivot.orientation.act(SIMD3<Float>(0, 0, 1))

        rig.rotate(deltaX: 0.2, deltaY: 0.7)
        rig.rotate(deltaX: -0.2, deltaY: -0.7)

        #expect(distance(rig.pivot.orientation.act(SIMD3(0, 0, 1)), original) < 0.00001)
        #expect(rig.camera.position == SIMD3(0, 0, 850))
    }

    @Test("Yaw rotates the view around world up without changing its pitch")
    func yawRotatesAroundWorldUp() {
        let rig = CameraRig(rootAnchor: Entity())
        let original = rig.pivot.orientation.act(SIMD3<Float>(0, 0, 1))

        rig.rotate(deltaX: 0, deltaY: .pi / 2)

        let expected = SIMD3(original.z, original.y, -original.x)
        #expect(distance(rig.pivot.orientation.act(SIMD3(0, 0, 1)), expected) < 0.00001)

        rig.rotate(deltaX: 0, deltaY: -.pi / 2)
        #expect(distance(rig.pivot.orientation.act(SIMD3(0, 0, 1)), original) < 0.00001)
    }

    @Test("Pitch stops before the camera flips over either pole")
    func pitchIsClamped() {
        let rig = CameraRig(rootAnchor: Entity())
        rig.rotate(deltaX: 100, deltaY: 0)
        let upper = rig.pivot.orientation.act(SIMD3<Float>(0, 0, 1))
        rig.rotate(deltaX: 100, deltaY: 0)

        #expect(abs(upper.y + sin(Float(1.4))) < 0.00001)
        #expect(distance(rig.pivot.orientation.act(SIMD3(0, 0, 1)), upper) < 0.00001)

        rig.rotate(deltaX: -100, deltaY: 0)
        let lower = rig.pivot.orientation.act(SIMD3<Float>(0, 0, 1))
        #expect(abs(lower.y - sin(Float(1.4))) < 0.00001)
    }

    @Test("Zoom uses relative magnification and respects its near and far limits")
    func zoomIsClamped() {
        let rig = CameraRig(rootAnchor: Entity())
        rig.zoom(scaleFactor: 1.5)
        #expect(abs(rig.camera.position.z - 850 / 1.5) < 0.001)
        rig.zoom(scaleFactor: 1 / 1.5)
        #expect(abs(rig.camera.position.z - 850) < 0.001)

        rig.zoom(scaleFactor: 100)
        #expect(rig.camera.position.z == 450)
        rig.zoom(scaleFactor: 0.001)
        #expect(rig.camera.position.z == 1_800)
    }

    @Test("Invalid magnification leaves the camera unchanged", arguments: [Float.zero, -1, .nan])
    func invalidMagnificationIsIgnored(_ factor: Float) {
        let rig = CameraRig(rootAnchor: Entity())
        let original = rig.camera.transform

        rig.zoom(scaleFactor: factor)

        #expect(rig.camera.transform == original)
    }

    @Test("The panel offset scales with the viewport and zoom, and closing recenters it")
    func offsetTracksProjection() throws {
        let rig = CameraRig(rootAnchor: Entity())
        rig.setTargetOffset(ratio: 0.1, aspectRatio: 2)
        // Neutral input applies the target without depending on animation playback.
        rig.zoom(scaleFactor: 1)
        let initialOffset = rig.camera.position.x
        let projection = try #require(rig.camera.components[PerspectiveCameraComponent.self])
        let radians = projection.fieldOfViewInDegrees * .pi / 180
        let projectedOffset = 2 * rig.camera.position.z * tan(radians / 2) * 2 * 0.1
        #expect(abs(initialOffset - projectedOffset) < 0.02)

        rig.setTargetOffset(ratio: 0.1, aspectRatio: 1)
        rig.zoom(scaleFactor: 1)
        #expect(abs(rig.camera.position.x - initialOffset / 2) < 0.001)

        rig.zoom(scaleFactor: 0.5)
        #expect(abs(rig.camera.position.x - initialOffset) < 0.001)

        rig.setTargetOffset(ratio: 0, aspectRatio: 1)
        rig.zoom(scaleFactor: 1)
        #expect(rig.camera.position.x == 0)
        #expect(rig.camera.position.z == 1_700)
    }

    @Test("Reset restores orbit and zoom while retaining the open panel offset")
    func resetRestoresDefaults() {
        let rig = CameraRig(rootAnchor: Entity())
        let originalForward = rig.pivot.orientation.act(SIMD3<Float>(0, 0, 1))
        rig.setTargetOffset(ratio: 0.12, aspectRatio: 1.5)
        rig.zoom(scaleFactor: 1)
        let originalPosition = rig.camera.position

        rig.rotate(deltaX: 0.8, deltaY: 2)
        rig.zoom(scaleFactor: 0.5)
        rig.reset()
        // Verify reset's target state separately from RealityKit's animation clock.
        rig.rotate(deltaX: 0, deltaY: 0)
        rig.zoom(scaleFactor: 1)

        #expect(distance(rig.pivot.orientation.act(SIMD3(0, 0, 1)), originalForward) < 0.00001)
        #expect(distance(rig.camera.position, originalPosition) < 0.001)
    }
}
