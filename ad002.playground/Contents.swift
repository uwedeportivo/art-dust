import UIKit
import GameKit

import PlaygroundSupport

class AffineSquare {
    let rect: CGRect
    let angle: CGFloat
    
    init(rect: CGRect, angle: Float) {
        self.rect = rect
        self.angle = radians(Double(angle))
    }
    
    func draw(_ ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: self.rect.minX, y: self.rect.minY)
        ctx.rotate(by: self.angle)
        let bezierPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.rect.width, height: self.rect.height))
        UIColor.black.set()
        bezierPath.stroke()
        ctx.restoreGState()
    }
}

func radians(_ v: Double) -> CGFloat {
    return CGFloat(v * Double.pi / 180.0)
}

func randomReal(_ rds: GKRandom, lower: Float, upper: Float) -> Float {
    let alpha = rds.nextUniform()
    return (1.0 - alpha) * lower + alpha * upper
}

func generateSquares(length: Int, boundWidth: Int, boundHeight: Int) -> [AffineSquare] {
    let rds = GKARC4RandomSource()
    var squares = [AffineSquare]()
    
    let m = (boundWidth - length) / length
    let n = (boundHeight - length) / length
    let dx = (boundWidth - length * m) / 2
    let dy = (boundHeight - length * n) / 2
    
    for i in 0..<m {
        for j in 0..<n{
            let x = dx + i * length
            let y = dy + j * length
            let r = Float(y) * Float(y) * Float(0.22) / 1000.0
            let angle = randomReal(rds, lower: -r, upper: r)
            let randx = Float(x) + randomReal(rds, lower: -0.03, upper: 0.03)
            let randy = Float(y) + randomReal(rds, lower: -0.03, upper: 0.03)
            
            let square = AffineSquare(rect:CGRect(x: Double(randx), y: Double(randy),
                                                  width: Double(length), height: Double(length)),
                                      angle: angle)
            
            squares.append(square)
        }
    }
    
    return squares
}

class CustomView: UIView {
    let squares: [AffineSquare]
    
    init(frame: CGRect, squares: [AffineSquare]) {
        self.squares = squares
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        
        
        for square in squares {
            square.draw(ctx)
        }
    }
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func asPDF() -> NSData {
        let pdfPageBounds = CGRect(x:0, y:0, width:self.frame.width, height:self.frame.height)
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageBounds, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageBounds, nil)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        UIGraphicsEndPDFContext()
        return pdfData
    }
}
let squares = generateSquares(length: 20, boundWidth: 410, boundHeight: 610)

let cv = CustomView(frame: CGRect(x: 0, y: 0, width: 410, height: 610), squares: squares)
cv.backgroundColor = UIColor.white
PlaygroundPage.current.liveView = cv

//cv.asImage()

let pdfData = cv.asPDF()

let url = playgroundSharedDataDirectory.appendingPathComponent("ad002.pdf")
let written = pdfData.write(to: url, atomically: true)



