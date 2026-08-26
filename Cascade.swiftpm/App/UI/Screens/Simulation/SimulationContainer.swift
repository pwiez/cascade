import CascadeEngine
import SwiftUI

/// Wraps the rendered scene in the drag-to-orbit and pinch-to-zoom gestures.
///
/// Both gestures report cumulative values, so each handler stores the previous
/// reading and forwards only the delta — the camera rig works in increments.
struct SimulationContainer: View {
    let simulation: Simulation

    @State private var previousDrag: CGSize = .zero
    @State private var previousMagnification: CGFloat = 1.0

    /// Radians of camera rotation per point dragged.
    private let dragSensitivity: Float = 0.005

    var body: some View {
        SimulationView(simulation: simulation)
            .gesture(orbit)
            .simultaneousGesture(zoom)
    }

    private var orbit: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard simulation.isCameraEnabled else { return }

                // Horizontal drag turns the camera around Y, vertical around X.
                let deltaY = Float(value.translation.width - previousDrag.width) * -dragSensitivity
                let deltaX = Float(value.translation.height - previousDrag.height) * -dragSensitivity

                previousDrag = value.translation
                simulation.rotateCamera(deltaX: deltaX, deltaY: deltaY)
            }
            .onEnded { _ in previousDrag = .zero }
    }

    private var zoom: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0)
            .onChanged { value in
                guard simulation.isCameraEnabled else { return }
                simulation.zoomCamera(scaleFactor: Float(value.magnification / previousMagnification))
                previousMagnification = value.magnification
            }
            .onEnded { _ in previousMagnification = 1.0 }
    }
}
