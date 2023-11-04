import UIKit

class PPGGraphView: UIView {
    var data: [CGFloat] = [] {
        didSet {
            self.setNeedsDisplay()  // Request redraw when data changes
        }
    }

    override func draw(_ rect: CGRect) {
        guard data.count > 1 else { return }  // Need at least 2 data points to draw a line
        
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setLineWidth(2.0)
        
        let xSpacing = self.bounds.width / CGFloat(data.count - 1)
        
        context?.move(to: CGPoint(x: 0, y: data[0]))
        for i in 1..<data.count {
            let x = CGFloat(i) * xSpacing
            let y = data[i]
            context?.addLine(to: CGPoint(x: x, y: y))
        }
        
        context?.strokePath()
    }
}
