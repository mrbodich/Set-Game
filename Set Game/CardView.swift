//
//  CardView.swift
//  Set Game
//
//  Created by bodich on 27.07.2018.
//  Copyright © 2018 bodich. All rights reserved.
//

import UIKit

class CardView: UIView {
    var shapes = [SingleShape]()
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    enum CardViewState {
        case inDeck, flying, flyingOut, goingToFly, goingToFlyOut, onTable, out
    }
    
    var state: CardViewState = .inDeck
    var destination: CardViewState = .inDeck {
        didSet {
            switch destination {
            case .out:
                isSelected = true
            default:
                break
            }
        }
    }
    var isReadyToFlip = false
    
    override var frame: CGRect {
        didSet {
            updateShapes()
            setNeedsDisplay()
        }
    }
    
    var unfinishedAnimationsCount = 0
    var timerAdded = false
    var label: UILabel
    
    var cardId: Int = -1
    override func draw(_ rect: CGRect) {
        let cardSurface = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: cardCornerRadius)
        cardSurface.addClip()
        
        switch state {
        case .inDeck, .flying, .goingToFly, .out:
            UIColor.green.setFill()
            cardSurface.fill()
            let circle = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), radius: frame.width / 2 - strokeWidth, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            UIColor.white.setStroke()
            circle.lineWidth = strokeWidth
            circle.stroke()
            cardSurface.lineWidth = strokeWidth
            cardSurface.stroke()
        case .onTable, .flyingOut, .goingToFlyOut:
            UIColor.white.setFill()
            cardSurface.fill()
            UIColor.orange.setStroke()
            cardSurface.lineWidth = isSelected ? strokeWidth : 0
            cardSurface.stroke()
//        case .out:
//            UIColor.red.setFill()
        }
        updateShapes()
    }
    
    func updateShapes() {
        let shapesOrigin = CGPoint(x: (frame.width - shapeWidth) / 2 , y: (frame.height - shapeHeight * CGFloat(shapes.count)) / 2)
        for index in 0..<shapes.count {
            shapes[index].frame.origin = CGPoint(x: shapesOrigin.x, y: shapesOrigin.y + shapeHeight * CGFloat(index))
            shapes[index].frame.size.width = shapeWidth
            shapes[index].frame.size.height = shapeHeight
            switch state {
            case .onTable, .flyingOut, .goingToFlyOut:
                shapes[index].isHidden = false
            default:
                shapes[index].isHidden = true
            }
        }
        
        /*label.frame = frame
        label.frame.origin = CGPoint.zero
        label.text = """
        \(isReadyToFlip)
        \(state)
        \(destination)
        \(cardId)
        """
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        label.font = label.font.withSize(18)
        label.textColor = UIColor.black
        self.insertSubview(label, at: self.subviews.count - 1)*/
    }
    
    func animateBeforeOut(afterFlipCompletion: @escaping () -> Void = {}) {
        let oldFrame = frame
        let duration = 1.2
        
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.15, animations: {
                    resizeCard(originalFrame: oldFrame, scale: 1.25)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.15, relativeDuration: 0.15, animations: {
                    resizeCard(originalFrame: oldFrame, scale: 1.1)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2, animations: {
                    resizeCard(originalFrame: oldFrame, scale: 1.15)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.08, animations: {
                    resizeCard(originalFrame: oldFrame, scale: 1.2)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.88, relativeDuration: 0.12, animations: {
                     self.frame = oldFrame
                })
            }, completion: { (position) in
                afterFlipCompletion()
            })
        }
        animator.startAnimation()
        
        func resizeCard(originalFrame: CGRect, scale: CGFloat) {
            let newSize = CGSize(width: oldFrame.width * scale, height: oldFrame.height * scale)
            let newOrigin = CGPoint(x: oldFrame.origin.x - (newSize.width - oldFrame.width) / 2,
                                    y: oldFrame.origin.y - (newSize.height - oldFrame.height) / 2)
            self.frame.size = newSize
            self.frame.origin = newOrigin
        }
    }
    
    func animate(to newFrame: CGRect, delay: TimeInterval = 0, allowFlip: Bool = true, afterFlipCompletion: @escaping () -> Void = {}) {
        setNeedsDisplay()
        if allowFlip {
            unfinishedAnimationsCount += 1
        }
        
        UIView.animate( withDuration: 0.5,
                        delay: delay,
                        options: [],
                        animations: { [unowned self] in
                            self.frame = CGRect(origin: newFrame.origin, size: newFrame.size)
            },
                        completion: { [weak self/*, animationId = targetAnimationId*/, allowFlip] (position) in
                            if self != nil {
                                if allowFlip {
                                    self?.unfinishedAnimationsCount -= 1
                                }
                                if !self!.isReadyToFlip { self!.isReadyToFlip = true; }
                                else if self!.destination != self!.state && (self!.destination == .onTable || self!.destination == .out) && self!.isReadyToFlip &&
                                    self?.unfinishedAnimationsCount == 0{
                                    self!.isReadyToFlip = false
                                    UIView.transition(  with: self!,
                                                        duration: 0.5,
                                                        options: [.transitionFlipFromLeft, .layoutSubviews],
                                                        animations: {[weak self] in
                                                            self?.state = self!.destination
                                                            self?.setNeedsDisplay()
                                        },
                                                        completion: { [afterFlipCompletion] (position) in
                                                            afterFlipCompletion()
                                    })
                                }
                            }
        })
    }
    
    func setType(shape: Card.CardShape, shapesCount: Card.CardShapeCount, color: Card.CardColor, shading: Card.CardShading, id: Int) {
        cardId = id
        shapes = [SingleShape]()
        for _ in 0..<shapesCount.rawValue {
            shapes.append(SingleShape(frame: CGRect.zero, shape: shape, color: color, shading: shading))
        }
        for shape in shapes {
            self.addSubview(shape)
        }
    }
    
    init(shape: Card.CardShape, shapesCount: Card.CardShapeCount, color: Card.CardColor, shading: Card.CardShading, id: Int) {
        label = UILabel(frame: CGRect.zero)
        super.init(frame: CGRect.zero)
        self.addSubview(label)
        setType(shape: shape, shapesCount: shapesCount, color: color, shading: shading, id: id)
        contentMode = UIView.ContentMode.redraw
        backgroundColor = UIColor.clear
    }
    
    init() {
        label = UILabel(frame: CGRect.zero)
        super.init(frame: CGRect.zero)
        self.addSubview(label)
        contentMode = UIView.ContentMode.redraw
        backgroundColor = UIColor.clear
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
        contentMode = UIView.ContentMode.redraw
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinited shape...")
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
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
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
