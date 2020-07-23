//
//  CardView.swift
//  Set Game
//
//  Created by Bogdan Chernobrivec on 27.07.2018.
//  Copyright © 2018 Bogdan Chornobryvets. All rights reserved.
//

import UIKit


class CardView: UIView {
    var cardType: (shape: Card.CardShape, shapesCount: Card.CardShapeCount, color: Card.CardColor, shading: Card.CardShading, id: Int) {
        didSet {
            cardId = cardType.id
            shapes = [SingleShape]()
        }
    }
    var shapes: [SingleShape]
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var cardId: Int
    override func draw(_ rect: CGRect) {
        let cardSurface = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: cardCornerRadius)
        cardSurface.addClip()
        UIColor.white.setFill()
        cardSurface.fill()
        updateCard()
        UIColor.orange.setStroke()
        cardSurface.lineWidth = isSelected ? strokeWidth : 0
        cardSurface.stroke()
    }
    
    func animate(to newFrame: CGRect, delay: TimeInterval = 0) {
        var delay: TimeInterval = 0
        if frame == CGRect.zero {
            frame = newFrame
            frame.origin.x = -frame.size.width * 1.4
            updateCard()
            delay = TimeInterval(700.arc4random) / 1000
        }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5,
                                                        delay: delay,
                                                        options: [.transitionFlipFromLeft],
                                                        animations: {[unowned self] in
                                                            self.frame = CGRect(origin: newFrame.origin, size: newFrame.size)
                                                            self.updateCard()
                                                        },
                                                       
                                                        completion: { (position) in
                                                        
                                                        })
        
    }
    
    func updateCard() {
        let shapesOrigin = CGPoint(x: (frame.width - shapeWidth) / 2 , y: (frame.height - shapeHeight * CGFloat(shapes.count)) / 2)
        for index in 0..<shapes.count {
            shapes[index].frame.origin = CGPoint(x: shapesOrigin.x, y: shapesOrigin.y + shapeHeight * CGFloat(index))
            shapes[index].frame.size.width = shapeWidth
            shapes[index].frame.size.height = shapeHeight
        }
    }
    
    init(shape: Card.CardShape, shapesCount: Card.CardShapeCount, color: Card.CardColor, shading: Card.CardShading, id: Int){
        cardId = id
        shapes = [SingleShape]()
        for _ in 0..<shapesCount.rawValue {
            shapes.append(SingleShape(frame: CGRect.zero, shape: shape, color: color, shading: shading))
        }
        super.init(frame: CGRect.zero)
        contentMode = UIViewContentMode.redraw
        backgroundColor = UIColor.clear
        for shape in shapes {
            self.addSubview(shape)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinited cardview \(cardId)")
    }
}


class SingleShape: UIView {
    var shapesColor: Card.CardColor
    var shapesShading: Card.CardShading
    var shape: Card.CardShape
    var color: UIColor {
        switch shapesColor {
        case .green: return UIColor.green
        case .red: return UIColor.red
        case .purple: return UIColor.purple
        }
    }
    override func draw(_ rect: CGRect) {
        var path: UIBezierPath
        switch shape {
        case .oval:
            path = drawOval()
        case .diamond:
            path = drawDiamond()
        case .squiggle:
            path = drawSquiggle()
        }
        path.lineWidth = strokeWidth
        color.setStroke()
        color.setFill()
        path.stroke()
        switch shapesShading {
        case .solid: path.fill()
        case .striped:
            drawStripes(outline: path)
        default: break
        }
        
        self.sizeToFit()
    }
    
    func drawStripes(outline: UIBezierPath) {
        outline.addClip()
        let stripes = UIBezierPath()
        var xOffset: CGFloat = 0
        while xOffset < frame.width {
            stripes.move(to: CGPoint(x: xOffset, y: 0))
            stripes.addLine(to: CGPoint(x: xOffset, y: frame.height))
            xOffset += strokeWidth * 3
        }
        stripes.lineWidth = strokeWidth
        stripes.stroke()
    }
    
    func drawOval() -> UIBezierPath {
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: shapeMargin, y: shapeMargin), size: shapeSize), cornerRadius: shapeHeight / 2)
        return path
    }
    
    func drawDiamond() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: shapeWidth / 2 + shapeMargin, y: 0 + shapeMargin))
        path.addLine(to: CGPoint(x: shapeWidth + shapeMargin, y: shapeHeight / 2 + shapeMargin))
        path.addLine(to: CGPoint(x: shapeWidth / 2 + shapeMargin, y: shapeHeight + shapeMargin))
        path.addLine(to: CGPoint(x: 0 + shapeMargin, y: shapeHeight / 2 + shapeMargin))
        path.close()
        return path
    }
    
    func drawSquiggle() -> UIBezierPath {
        let controlPointsNumbers: [[CGFloat]] = [[0, shapeHeight * 0.66],
                                          [shapeWidth * 0.33, shapeHeight * 0.1],
                                          [shapeWidth * 0.66, shapeHeight * 0.25],
                                          [shapeWidth * 0.9, 0],
                                          [shapeWidth, shapeHeight * 0.33],
                                          [shapeWidth * 0.66, shapeHeight * 0.9],
                                          [shapeWidth * 0.33, shapeHeight * 0.75],
                                          [shapeWidth * 0.1, shapeHeight]]
        let shape = SmoothBezier(points: controlPointsNumbers, boundsWidth: frame.size.width, boundsHeight: frame.size.height, margin: shapeMargin, smoothinessRatio: 0.35)
        return shape.drawShape()
    }
    
    init(frame: CGRect, shape: Card.CardShape, color: Card.CardColor, shading: Card.CardShading) {
        self.shape = shape
        shapesColor = color
        shapesShading = shading
        super.init(frame: frame)
        contentMode = UIViewContentMode.redraw
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct SmoothBezier {
    var controlPoints: [CGPoint] {
        didSet {
            calculateSmoothPoints()
        }
    }
    var smoothControlPoints = [SmoothPoint]()
    var shapeWidth: CGFloat
    var shapeHeight: CGFloat
    var smoothinessRatio: CGFloat
    
    init (points: [[CGFloat]], boundsWidth: CGFloat, boundsHeight: CGFloat, margin: CGFloat = 0, smoothinessRatio: CGFloat = 33) {
        controlPoints = [CGPoint]()
        shapeWidth = boundsWidth - margin * 2
        shapeHeight = boundsHeight - margin * 2
        self.smoothinessRatio = smoothinessRatio
        for point in points { controlPoints.append(CGPoint(x: point[0] + margin, y: point[1] + margin))}
        calculateSmoothPoints()
    }
    
    func drawShape() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: smoothControlPoints.first!.point)
        for (index, smoothPoint) in smoothControlPoints.enumerated() {
            switch index {
            case _ where index < smoothControlPoints.count - 1:
                path.addCurve(to: smoothControlPoints[index + 1].point, controlPoint1: smoothPoint.controlPointAfter, controlPoint2: smoothControlPoints[index + 1].controlPointBefore)
            case _ where index == smoothControlPoints.count - 1:
                path.addCurve(to: smoothControlPoints.first!.point, controlPoint1: smoothPoint.controlPointAfter, controlPoint2: smoothControlPoints.first!.controlPointBefore)
            default:
                break
            }
            /*let strokeWidth = shapeWidth * 0.02
            let circle1 = UIBezierPath(arcCenter: smoothPoint.point, radius: strokeWidth, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circle2 = UIBezierPath(arcCenter: smoothPoint.controlPointAfter, radius: strokeWidth, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circle3 = UIBezierPath(arcCenter: smoothPoint.controlPointBefore, radius: strokeWidth, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let line = UIBezierPath()
            line.move(to: smoothPoint.controlPointAfter)
            line.addLine(to: smoothPoint.controlPointBefore)
            line.lineWidth = strokeWidth / 2
            UIColor.red.setFill()
            circle1.fill()
            UIColor.yellow.setStroke()
            line.stroke()
            UIColor.purple.setFill()
            circle2.fill()
            circle3.fill()*/
        }
        path.close()
        return path
    }
    
    private mutating func calculateSmoothPoints() {
        smoothControlPoints = [SmoothPoint]()
        for (index, point) in controlPoints.enumerated() {
            switch index {
            case 0 where index < controlPoints.count - 1:
                smoothControlPoints.append(SmoothPoint(point: point, previousPoint: controlPoints.last!, nextPoint: controlPoints[index + 1], smoothinessRatio: smoothinessRatio))
            case _ where index < controlPoints.count - 1 && index > 0:
                smoothControlPoints.append(SmoothPoint(point: point, previousPoint: controlPoints[index - 1], nextPoint: controlPoints[index + 1], smoothinessRatio: smoothinessRatio))
            case _ where index == controlPoints.count - 1:
                smoothControlPoints.append(SmoothPoint(point: point, previousPoint: controlPoints[index - 1], nextPoint: controlPoints.first!, smoothinessRatio: smoothinessRatio))
            default:
                break
            }
        }
    }
    
    struct SmoothPoint {
        var point: CGPoint
        var controlPointBefore: CGPoint
        var controlPointAfter: CGPoint
        
        init (point: CGPoint, previousPoint: CGPoint, nextPoint: CGPoint, smoothinessRatio: CGFloat) {
            self.point = point
            
            let previousDistance = point.distance(to: previousPoint)
            let nextDistance = point.distance(to: nextPoint)
            let distance = previousPoint.distance(to: nextPoint)
            
            var previousRatio = previousDistance / distance
            var nextRatio = nextDistance / distance
            previousRatio = previousRatio > 1 ? smoothinessRatio : previousRatio * smoothinessRatio
            nextRatio = nextRatio > 1 ? smoothinessRatio : nextRatio * smoothinessRatio
            let offset = nextPoint.resetOrigin(to: previousPoint)
            controlPointAfter = CGPoint(x: point.x - offset.x * nextRatio, y: point.y - offset.y * nextRatio)
            controlPointBefore = CGPoint(x: point.x + offset.x * previousRatio, y: point.y + offset.y * previousRatio)
        }
    }
}

extension CGPoint {
    func resetOrigin(to previousPoint: CGPoint) -> CGPoint {
        return CGPoint(x: previousPoint.x - self.x, y: previousPoint.y - self.y)
    }
    func distance(to targetPoint: CGPoint) -> CGFloat {
        let basePoint = self.resetOrigin(to: targetPoint)
        return (basePoint.x.magnitude * basePoint.x.magnitude + basePoint.y.magnitude * basePoint.y.magnitude).squareRoot()
    }
}

extension CardView {
    private struct SizeRatio {
        static let faceShapesWidthToCardWidth: CGFloat = 0.8
        static let cardCornerRadiusToCardWidth: CGFloat = 0.1
        static let strokeWidthToCardWidth: CGFloat = 0.15
    }
    private var shapeWidth: CGFloat {
        return frame.width * SizeRatio.faceShapesWidthToCardWidth
    }
    private var shapeHeight: CGFloat {
        return shapeWidth / 2.1
    }
    private var cardCornerRadius: CGFloat {
        return frame.width * SizeRatio.cardCornerRadiusToCardWidth
    }
    private var strokeWidth: CGFloat {
        return shapeWidth * SizeRatio.strokeWidthToCardWidth
    }
}

extension SingleShape {
    private var strokeWidth: CGFloat {
        return frame.size.width * 0.02
    }
    private var shapeMargin: CGFloat {
        return strokeWidth * 4
    }
    private var shapeWidth: CGFloat {
        return frame.width - shapeMargin * 2
    }
    private var shapeHeight: CGFloat {
        return frame.height - shapeMargin * 2
    }
    private var shapeSize: CGSize {
        return CGSize(width: shapeWidth, height: shapeHeight)
    }
}
