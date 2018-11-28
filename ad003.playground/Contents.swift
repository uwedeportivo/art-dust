import UIKit
import GameKit

import PlaygroundSupport

func radians(_ v: Double) -> CGFloat {
    return CGFloat(v * Double.pi / 180.0)
}

func randomReal(_ rds: GKRandom, lower: Float, upper: Float) -> Float {
    let alpha = rds.nextUniform()
    return (1.0 - alpha) * lower + alpha * upper
}

func noisify(point: CGPoint, noiseMap: GKNoiseMap) -> CGPoint {
    var rPoint = CGPoint(x:point.x, y: point.y)
    let dr = noiseMap.value(at: vector_int2(Int32(point.x), Int32(point.y))) * 10.0
    rPoint.x += CGFloat(dr)
    rPoint.y += CGFloat(dr)
    return rPoint
}

class LongRect {
    var origin: CGPoint
    let width: CGFloat
    let height: CGFloat
    
    init(origin: CGPoint, width: CGFloat, height: CGFloat) {
        self.origin = origin
        self.width = width
        self.height = height
    }
    
    func addNoise(_ noiseMap: GKNoiseMap) {
        self.origin = noisify(point: self.origin, noiseMap: noiseMap)
    }
    
    func draw() {
        let rect = CGRect(x: self.origin.x, y: self.origin.y,
                          width: self.width, height: self.height)
        
        let bezierPath = UIBezierPath(rect: rect)
        bezierPath.stroke()
    }
}

func generateLongRects(count: Int, width: Int, height: Int,
                       padding: Int, boundWidth: Int, boundHeight: Int) -> [LongRect] {
    let rds = GKARC4RandomSource()
    let noiseSource = GKPerlinNoiseSource()
    let noise = GKNoise(noiseSource)
    let noiseMap = GKNoiseMap(noise,
                              size: vector_double2(Double(boundWidth), Double(boundHeight)),
                              origin: vector_double2(0.0, 0.0),
                              sampleCount: vector_int2(Int32(boundWidth), Int32(boundHeight)),
                              seamless: true)
    
    var longRects = [LongRect]()
    
    for _ in 0..<count {
        let x1 = Float(padding * 2)
        let x2 = Float(boundWidth - padding * 2)
        
        let ux = Double(randomReal(rds, lower: x1, upper: x2))
        let uh = -ux * ux + ux * Double (x1 + x2) - Double(x1 * x2)
        let uy = Double(padding) + uh / 2000.0
        
        let lx = Double(randomReal(rds, lower: x1, upper: x2))
        let lh = -lx * lx + lx * Double (x1 + x2) - Double(x1 * x2)
        let ly = Double(padding / 2) + Double(height) - lh / 10000.0

        
        let upperRect = LongRect(origin: CGPoint(x: ux, y: uy), width:CGFloat(width), height: CGFloat(height))
        let lowerRect = LongRect(origin: CGPoint(x: lx, y: ly), width:CGFloat(width), height: CGFloat(height))
        
        upperRect.addNoise(noiseMap)
        lowerRect.addNoise(noiseMap)
        
        longRects.append(upperRect)
        longRects.append(lowerRect)
    }
    return longRects
}

class CustomView: UIView {
    let longRects: [LongRect]
    
    init(frame: CGRect, longRects: [LongRect]) {
        self.longRects = longRects
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        
        UIColor.red.set()
        
        for longRect in self.longRects {
            longRect.draw()
        }
        
        ctx.restoreGState()
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

let longRects = generateLongRects(count: 80, width: 20, height: 180,
                                  padding: 20, boundWidth: 600, boundHeight: 400)

let cv = CustomView(frame: CGRect(x: 0, y: 0, width: 600, height: 400), longRects:longRects)
cv.backgroundColor = UIColor(red:0.926, green:0.922, blue:0.913, alpha:1.000)
PlaygroundPage.current.liveView = cv

//cv.asImage()

let pdfData = cv.asPDF()

let url = playgroundSharedDataDirectory.appendingPathComponent("ad003.pdf")
let written = pdfData.write(to: url, atomically: true)



