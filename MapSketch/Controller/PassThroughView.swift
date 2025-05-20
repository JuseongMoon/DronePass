import UIKit

final class PassThroughView: UIView {
    weak var passThroughTarget: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let target = passThroughTarget {
            let targetPoint = convert(point, to: target)
            if target.bounds.contains(targetPoint) {
                return super.hitTest(point, with: event)
            }
            return nil
        }
        return super.hitTest(point, with: event)
    }
} 