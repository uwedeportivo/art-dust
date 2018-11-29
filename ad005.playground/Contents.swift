import UIKit
import GameKit

import PlaygroundSupport

func radians(_ v: Double) -> CGFloat {
    return CGFloat(v * Double.pi / 180.0)
}

func noisify(point: CGPoint, noiseMap: GKNoiseMap) -> CGPoint {
    var rPoint = CGPoint(x:point.x, y: point.y)
    let dr = noiseMap.value(at: vector_int2(Int32(point.x), Int32(point.y))) * 2.0
    rPoint.x += CGFloat(dr)
    rPoint.y += CGFloat(dr)
    return rPoint
}

func randomShade(_ rds:GKRandom) -> UIColor {
    let alpha = rds.nextUniform()
    let r = (1.0 - alpha) * (-0.2) + alpha * 0.05
    return UIColor(red: CGFloat(0.942 + r), green: CGFloat(0.919 + r),
                   blue: CGFloat(0.839 + r), alpha: CGFloat(1.0))
}

class QuadCell {
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

class Quad {
    var cells: [QuadCell]
    
    init(rect: CGRect, rds: GKRandomSource) {
        self.cells = [QuadCell]()
        
        let count = 5 + rds.nextInt(upperBound: 7) + rds.nextInt(upperBound: 5)
        let gap = rect.width / CGFloat(count)
        
        var lastRect = rect
        
        for _ in 0..<count {
            let inset = CGFloat(rds.nextUniform()) * gap
            let cellRect = lastRect.inset(by: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
            
            let cell = QuadCell(rect: cellRect, fillColor: randomShade(rds))
            self.cells.append(cell)
            lastRect = cellRect
        }
    }
    
    func addNoise(_ noiseMap: GKNoiseMap) {
        for cell in self.cells {
            cell.addNoise(noiseMap)
        }
    }
    
    func draw() {
        for cell in self.cells {
            cell.draw()
        }
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
    
    let m = (boundWidth - padding) / (width + padding)
    let n = (boundHeight - padding) / (height + padding)
    let dx = (boundWidth - (m * (width + padding) + padding)) / 2
    let dy = (boundHeight - (n * (height + padding) + padding)) / 2
    
    for i in 0..<m {
        for j in 0..<n {
            let quad = Quad(rect: CGRect(x:dx + padding + i * (width + padding),
                                         y: dy + padding + j * (height + padding),
                                         width: width, height:height),
                            rds: rds)
            quad.addNoise(noiseMap)
            quads.append(quad)
        }
    }
    return quads
}

class CustomView: UIView {
    let quads: [Quad]
    
    init(frame: CGRect, quads: [Quad]) {
        self.quads = quads
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        
        for quad in self.quads {
            quad.draw()
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

let quads = generateQuads(width: 35, height: 35, padding: 1, boundWidth: 600, boundHeight: 600)

let cv = CustomView(frame: CGRect(x: 0, y: 0, width: 600, height: 600), quads:quads)
cv.backgroundColor = UIColor.white
PlaygroundPage.current.liveView = cv

//cv.asImage()

let pdfData = cv.asPDF()

let url = playgroundSharedDataDirectory.appendingPathComponent("ad005.pdf")
let written = pdfData.write(to: url, atomically: true)



