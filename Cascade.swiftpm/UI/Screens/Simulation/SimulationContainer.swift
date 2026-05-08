import SwiftUI

struct SimulationContainer: View {
    let simulation: Simulation

    @State private var previousDrag: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        SimulationView(simulation: simulation)
            .gesture(
                SimultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard simulation.isCameraEnabled else { return }

                            let sensitivity: Float = 0.005
                            let deltaY = Float(value.translation.width - previousDrag.width) * -sensitivity
                            let deltaX = Float(value.translation.height - previousDrag.height) * -sensitivity

                            previousDrag = value.translation
                            simulation.rotateCamera(deltaX: deltaX, deltaY: deltaY)
                        }
                        .onEnded { _ in previousDrag = .zero },

                    MagnificationGesture(minimumScaleDelta: 0)
                        .onChanged { value in
                            guard simulation.isCameraEnabled else { return }

                            let delta = Float(value / lastScale)
                            lastScale = value
                            simulation.zoomCamera(scaleFactor: delta)
                        }
                        .onEnded { _ in lastScale = 1.0 }
                )
            )
    }
}
