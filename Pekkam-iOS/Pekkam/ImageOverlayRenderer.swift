import UIKit

struct ImageOverlayRenderer {
    static func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let result = renderer.image { ctx in
            image.draw(at: .zero)
            
            let text = "PEKKAM PRØVEVERSJON"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.3),
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let angle: CGFloat = -45 * .pi / 180
            let spacing: CGFloat = 150
            
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.saveGState()
            
            var x = -image.size.width
            while x < image.size.width * 2 {
                var y = -image.size.height
                while y < image.size.height * 2 {
                    ctx.cgContext.saveGState()
                    
                    let centerX = x + textSize.width / 2
                    let centerY = y + textSize.height / 2
                    
                    ctx.cgContext.translateBy(x: centerX, y: centerY)
                    ctx.cgContext.rotate(by: angle)
                    ctx.cgContext.translateBy(x: -centerX, y: -centerY)
                    
                    (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
                    
                    ctx.cgContext.restoreGState()
                    
                    y += spacing
                }
                x += spacing
            }
            
            ctx.cgContext.restoreGState()
        }
        
        return result
    }
    
    static func addCompassOverlay(to image: UIImage, heading: Double, direction: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let compassSize: CGFloat = 150
        let padding: CGFloat = 20
        
        let result = renderer.image { ctx in
            image.draw(at: .zero)
            
            let compassRect = CGRect(
                x: image.size.width - compassSize - padding,
                y: image.size.height - compassSize - padding,
                width: compassSize,
                height: compassSize
            )
            
            // Draw background circle
            UIColor.black.withAlphaComponent(0.5).setFill()
            UIBezierPath(ovalIn: compassRect).fill()
            
            // Draw border
            UIColor.white.setStroke()
            let borderPath = UIBezierPath(ovalIn: compassRect)
            borderPath.lineWidth = 2
            borderPath.stroke()
            
            let centerX = compassRect.midX
            let centerY = compassRect.midY
            let radius = compassSize / 2 - 10
            
            // Draw cardinal directions
            let directions = ["N", "E", "S", "W"]
            let angles: [CGFloat] = [0, CGFloat.pi / 2, CGFloat.pi, CGFloat.pi * 1.5]
            
            for (idx, dir) in directions.enumerated() {
                let angle = angles[idx]
                let x = centerX + sin(angle) * radius
                let y = centerY - cos(angle) * radius
                
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.white,
                ]
                
                let textSize = dir.size(withAttributes: textAttributes)
                (dir as NSString).draw(
                    at: CGPoint(x: x - textSize.width / 2, y: y - textSize.height / 2),
                    withAttributes: textAttributes
                )
            }
            
            // Draw needle pointing to heading
            let needleAngle = (heading * .pi / 180)
            let needleLength = radius * 0.8
            let needleEndX = centerX + sin(needleAngle) * needleLength
            let needleEndY = centerY - cos(needleAngle) * needleLength
            
            UIColor.red.setStroke()
            let needlePath = UIBezierPath()
            needlePath.move(to: CGPoint(x: centerX, y: centerY))
            needlePath.addLine(to: CGPoint(x: needleEndX, y: needleEndY))
            needlePath.lineWidth = 3
            needlePath.stroke()
            
            // Draw heading degree text
            let headingText = String(format: "%.0f°", heading)
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.white,
            ]
            let headingTextSize = headingText.size(withAttributes: headingAttributes)
            (headingText as NSString).draw(
                at: CGPoint(x: centerX - headingTextSize.width / 2, y: centerY + 15),
                withAttributes: headingAttributes
            )
            
            // Draw direction text below
            let dirAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.lightGray,
            ]
            (direction as NSString).draw(
                at: CGPoint(x: centerX - 20, y: centerY + 30),
                withAttributes: dirAttributes
            )
        }
        
        return result
    }
}
