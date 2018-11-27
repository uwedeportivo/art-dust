import UIKit
import GameKit

import PlaygroundSupport

func radians(_ v: Double) -> CGFloat {
    return CGFloat(v * Double.pi / 180.0)
}

func noisify(point: CGPoint, noiseMap: GKNoiseMap) -> CGPoint {
    var rPoint = CGPoint(x:point.x, y: point.y)
    let dr = noiseMap.value(at: vector_int2(Int32(point.x), Int32(point.y))) * 3.0
    rPoint.x += CGFloat(dr)
    rPoint.y += CGFloat(dr)
    return rPoint
}

class Quad {
    var va, vb, vc, vd: CGPoint
    let fillColor: UIColor
    
    init(rect: CGRect, fillColor: UIColor) {
        self.va = CGPoint(x: rect.minX, y: rect.minY)
        self.vb = CGPoint(x: rect.minX, y: rect.maxY)
        self.vc = CGPoint(x: rect.maxX, y: rect.maxY)
        self.vd = CGPoint(x: rect.maxX, y: rect.minY)
        self.fillColor = fillColor
    }
    
    func addNoise(_ noiseMap: GKNoiseMap) {
        self.va = noisify(point: self.va, noiseMap: noiseMap)
        self.vb = noisify(point: self.vb, noiseMap: noiseMap)
        self.vc = noisify(point: self.vc, noiseMap: noiseMap)
        self.vd = noisify(point: self.vd, noiseMap: noiseMap)
    }
    
    func draw() {
        let path = CGMutablePath()
        
        path.move(to: self.va)
        path.addLine(to: self.vb)
        path.addLine(to: self.vc)
        path.addLine(to: self.vd)
        path.closeSubpath()
        
        let bezierPath = UIBezierPath(cgPath: path)
        self.fillColor.set()
        bezierPath.fill()
        UIColor.black.set()
        bezierPath.stroke()
    }
}

func generateQuads(width: Int, height: Int, padding: Int, boundWidth: Int, boundHeight: Int) -> [Quad] {
    let rds = GKARC4RandomSource()
    let noiseSource = GKPerlinNoiseSource()
    let noise = GKNoise(noiseSource)
    let noiseMap = GKNoiseMap(noise,
                              size: vector_double2(Double(boundWidth), Double(boundHeight)),
                              origin: vector_double2(0.0, 0.0),
                              sampleCount: vector_int2(Int32(boundWidth), Int32(boundHeight)),
                              seamless: true)
    
    var quads = [Quad]()
    
    let fillColors = [UIColor(red:0.00, green:0.94, blue:1.00, alpha:1.0),
                      UIColor(red:0.53, green:0.94, blue:0.55, alpha:1.0),
                      UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0),
                      UIColor.black]
    
    let rcp = GKRandomSource()
    
    let m = (boundWidth - padding) / (width + padding)
    let n = (boundHeight - padding) / (height + padding)
    let dx = (boundWidth - (m * (width + padding) + padding)) / 2
    let dy = (boundHeight - (n * (height + padding) + padding)) / 2
    
    for i in 0..<m {
        for j in 0..<n {
            if rds.nextInt(upperBound: 100) < 70 {
                let fillIndex = rcp.nextInt(upperBound: fillColors.count)
                let quad = Quad(rect: CGRect(x:dx + padding + i * (width + padding),
                                             y: dy + padding + j * (height + padding),
                                             width: width, height:height),
                                fillColor: fillColors[fillIndex])
                quad.addNoise(noiseMap)
                quads.append(quad)
            }
        }
    }
    return quads
}

class CustomView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        
        let quads = generateQuads(width: 20, height: 20, padding: 10, boundWidth: 400, boundHeight: 400)
        
        for quad in quads {
            quad.draw()
        }
        
        ctx.restoreGState()
    }
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
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

let cv = CustomView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
cv.backgroundColor = UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
PlaygroundPage.current.liveView = cv

//cv.asImage()

let pdfData = cv.asPDF()


let url = playgroundSharedDataDirectory.appendingPathComponent("foo.pdf")
let written = pdfData.write(to: url, atomically: true)



