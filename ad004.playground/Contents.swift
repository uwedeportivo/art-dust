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

func randomShade(_ rds:GKRandom) -> UIColor {
    let r = rds.nextUniform()
    
    return UIColor(red: CGFloat(r), green: CGFloat(r),
                   blue: CGFloat(r), alpha: CGFloat(1.0))
}

class CustomView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        
        let rds = GKARC4RandomSource()
        let noiseSource = GKPerlinNoiseSource()
        let noise = GKNoise(noiseSource)
        let noiseMap = GKNoiseMap(noise,
                                  size: vector_double2(Double(self.frame.width), Double(self.frame.height)),
                                  origin: vector_double2(0.0, 0.0),
                                  sampleCount: vector_int2(Int32(self.frame.width), Int32(self.frame.height)),
                                  seamless: true)
        

        UIColor.black.set()
        
        let side = Float(self.frame.width) / 2.0 - 50.0
        
        var startRadius = CGFloat(side)
        UIColor.black.setStroke()
        for _ in 0..<10 {
            startRadius -= CGFloat(10.0)
            var radius = startRadius
            //randomShade(rds).setStroke()
            
            let angleA = rds.nextInt(upperBound: 360)
            let angleB = rds.nextInt(upperBound: 360)
            
            var startAngle = angleA
            var endAngle = angleB
            if startAngle > endAngle {
                startAngle = angleB
                endAngle = angleA
            }
            let centerX = self.frame.width / 2.0  +
                CGFloat(randomReal(rds, lower: -10.0, upper: 10.0))
            let centerY = self.frame.height / 2.0 +
                CGFloat(randomReal(rds, lower: -10.0, upper: 10.0))
            
            let outer1 = CGMutablePath()
            let outer2 = CGMutablePath()
            
            ctx.setAlpha(1.0)
            var started = false
            for a in stride(from: startAngle, to:endAngle, by: 5) {
                
                let angle = radians(Double(a))
                radius += CGFloat(randomReal(rds, lower: -3.0, upper: 3.0))

                let x1 = centerX + radius * cos(angle)
                let y1 = centerY + radius * sin(angle)
                
                var p1 = CGPoint(x: x1, y: y1)
                p1 = noisify(point: p1, noiseMap: noiseMap)
                
                let x2 = centerX + radius * cos(angle + CGFloat.pi)
                let y2 = centerY + radius * sin(angle + CGFloat.pi)
                
                var p2 = CGPoint(x: x2, y: y2)
                p2 = noisify(point: p2, noiseMap: noiseMap)

                ctx.move(to: p1)
                ctx.addLine(to: p2)
                ctx.strokePath()
                
                if started {
                    outer1.addLine(to: p1)
                    outer2.addLine(to: p2)
                } else {
                    started = true
                    outer1.move(to: p1)
                    outer2.move(to: p2)
                }
            }
            
            ctx.setAlpha(0.2)
            outer1.addLine(to: CGPoint(x: centerX, y: centerY))
            outer1.closeSubpath()
            ctx.addPath(outer1)
            ctx.fillPath()
            
            outer2.addLine(to: CGPoint(x: centerX, y: centerY))
            outer2.closeSubpath()
            ctx.addPath(outer2)
            ctx.fillPath()
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

let cv = CustomView(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
cv.backgroundColor = UIColor(red:0.942, green:0.919, blue:0.839, alpha:1.000)
PlaygroundPage.current.liveView = cv

//cv.asImage()

let pdfData = cv.asPDF()

let url = playgroundSharedDataDirectory.appendingPathComponent("ad004.pdf")
let written = pdfData.write(to: url, atomically: true)


