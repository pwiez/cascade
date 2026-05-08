import UIKit
import RealityKit

final class ARViewContainer: UIView {
    var arView: ARView?
    override func layoutSubviews() {
        super.layoutSubviews()
        arView?.frame = self.bounds
    }
}
