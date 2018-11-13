//
//  BalloonView.swift
//  BalloonView
//
//  Created by teddy on 11/12/18.
//  Copyright © 2018 merpay, Inc. All rights reserved.
//

import UIKit

final class BalloonView: UIView {
    enum ArrowPosition {
        case any
        case top
        case bottom
        case right
        case left
        case bottomRight
        case bottomLeft
        case topRight
        case topLeft
        static let allValues = [top, bottom, right, left, bottomRight, bottomLeft, topRight, topLeft]
        func isAlongBottom() -> Bool {
            return self == .bottom || self == .bottomLeft || self == .bottomRight
        }
    }

    struct Constants {
        var cornerRadius = CGFloat(5)
        var arrowHeight = CGFloat(10)
        var arrowWidth = CGFloat(10)
        ///  e.g. 0.5 positions the arrow centered horizontally
        ///  0.25 positions the arrow at a quarter of the target width
        var arrowXPositionOffset = CGFloat(0.5)
        var backgroundColor = UIColor.white
        var arrowPosition = ArrowPosition.any
        var horizontalInset = CGFloat(12)

        var dismissTransform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        var initialTransform = CGAffineTransform(scaleX: 0, y: 0)
        var endTransform = CGAffineTransform.identity
        var springDamping = CGFloat(0.8)
        var springVelocity = CGFloat(0.7)
        var initialAlpha = CGFloat(0)
        var dismissAlpha = CGFloat(0)
        var animateDuration = 0.4
        var dismissDuration = 0.7
    }

    override var backgroundColor: UIColor? {
        didSet {
            guard let color = backgroundColor, color != UIColor.clear else { return }
            constants.backgroundColor = color
            backgroundColor = UIColor.clear
        }
    }

    private var _onTapped: OnTappedStep = { _ in return nil }
    fileprivate var _onTappedNext: OnTappedStep = { _ in return nil }
    private var arrowTip = CGPoint.zero
    var constants: Constants
    private let contentView: UIView
    private var contentViewSize: CGSize {
        return contentView.frame.size
    }

    private lazy var contentSize: CGSize = {
        var contentSize = CGSize(width: contentViewSize.width + 2 * constants.horizontalInset, height: contentViewSize.height + self.constants.arrowHeight)
        return contentSize
    }()

    init(contentView: UIView, constants: Constants = Constants()) {
        self.contentView = contentView
        self.constants = constants
        super.init(frame: CGRect.zero)
        self.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTappedHandler))
        addGestureRecognizer(tap)
    }

    @objc private func onTappedHandler(_ sender: Any) {
        weak var weakSelf = self
        let outputBalloonView = _onTapped(weakSelf)
        outputBalloonView?.show(onTapped: _onTappedNext)
    }

    convenience init(contentView: UIView,
                     forView view: UIView,
                     withinSuperview superview: UIView = UIApplication.shared.keyWindow!,
                     constants: Constants = Constants()) {
        contentView.adjustWidthForScreen(horizontalInset: constants.horizontalInset)
        self.init(contentView: contentView, constants: constants)
        let arrowTargetFrame = view.convert(view.bounds, to: superview)
        arrange(arrowTargetFrame: arrowTargetFrame, withinSuperview: superview)
        superview.addSubview(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("use provided initializer")
    }

    func onTapped(_ closure: @escaping OnTappedStep) -> OnTappedStep {
        return {(inputBalloonView: BalloonView?) -> BalloonView? in
            let outputBalloonView = closure(inputBalloonView)
            return outputBalloonView
        }
    }

    // MARK: - Private

    private func computeFrame(arrowPosition position: ArrowPosition, arrowTargetFrame: CGRect, superviewFrame: CGRect) -> CGRect {
        var xOrigin: CGFloat = 0
        var yOrigin: CGFloat = 0

        switch position {
        case .top, .topLeft, .topRight, .any:
            xOrigin = arrowTargetFrame.center.x - contentSize.width / 2
            yOrigin = arrowTargetFrame.origin.y + arrowTargetFrame.height
        case .bottom, .bottomLeft, .bottomRight:
            xOrigin = arrowTargetFrame.center.x - contentSize.width / 2
            yOrigin = arrowTargetFrame.origin.y - contentSize.height
        case .right:
            xOrigin = arrowTargetFrame.origin.x - contentSize.width
            yOrigin = arrowTargetFrame.center.y - contentSize.height / 2
        case .left:
            xOrigin = arrowTargetFrame.origin.x + arrowTargetFrame.width
            yOrigin = arrowTargetFrame.origin.y - contentSize.height / 2
        }

        var frame = CGRect(x: xOrigin, y: yOrigin, width: contentSize.width, height: contentSize.height)
        adjustFrame(&frame, forSuperviewFrame: superviewFrame)
        return frame
    }

    private func adjustFrame(_ frame: inout CGRect, forSuperviewFrame superviewFrame: CGRect) {
        if frame.origin.x < 0 {
            frame.origin.x = 0
        } else if frame.maxX > superviewFrame.width {
            frame.origin.x = superviewFrame.width - frame.width
        }

        if frame.origin.y < 0 {
            frame.origin.y = 0
        } else if frame.maxY > superviewFrame.maxY {
            frame.origin.y = superviewFrame.height - frame.height
        }
    }

    private func isFrameValid(_ frame: CGRect, forRefViewFrame: CGRect, withinSuperviewFrame: CGRect) -> Bool {
        return !frame.intersects(forRefViewFrame)
    }

    private func arrange(arrowTargetFrame: CGRect, withinSuperview superview: UIView) {
        var position = constants.arrowPosition
        let superviewFrame: CGRect
        if let scrollview = superview as? UIScrollView {
            superviewFrame = CGRect(origin: scrollview.frame.origin, size: scrollview.contentSize)
        } else {
            superviewFrame = superview.frame
        }

        var frame = computeFrame(arrowPosition: position, arrowTargetFrame: arrowTargetFrame, superviewFrame: superviewFrame)
        if !isFrameValid(frame, forRefViewFrame: arrowTargetFrame, withinSuperviewFrame: superviewFrame) {
            for value in ArrowPosition.allValues where value != position {
                let newFrame = computeFrame(arrowPosition: value, arrowTargetFrame: arrowTargetFrame, superviewFrame: superviewFrame)
                if isFrameValid(newFrame, forRefViewFrame: arrowTargetFrame, withinSuperviewFrame: superviewFrame) {
                    if position != .any { print("Used position '\(value)' instead of '\(position)'") }
                    frame = newFrame
                    position = value
                    constants.arrowPosition = value
                    break
                }
            }
        }

        var arrowTipXOrigin: CGFloat

        switch position {
        case .bottom, .top, .any:
            if frame.width < arrowTargetFrame.width {
                arrowTipXOrigin = contentSize.width * constants.arrowXPositionOffset
            } else {
                arrowTipXOrigin = abs(frame.origin.x - arrowTargetFrame.origin.x) + arrowTargetFrame.width * constants.arrowXPositionOffset
            }
            arrowTip = CGPoint(x: arrowTipXOrigin, y: position == .bottom ? contentSize.height : 0)
        case .bottomLeft, .bottomRight, .topLeft, .topRight:
            arrowTipXOrigin = abs(frame.origin.x - arrowTargetFrame.origin.x) + arrowTargetFrame.width * constants.arrowXPositionOffset
            arrowTip = CGPoint(x: arrowTipXOrigin, y: position.isAlongBottom() ? contentSize.height : 0)
        case .right, .left:
            if frame.height < arrowTargetFrame.height {
                arrowTipXOrigin = contentSize.height / 2
            } else {
                arrowTipXOrigin = abs(frame.origin.y - arrowTargetFrame.origin.y) + arrowTargetFrame.height / 2
            }
            arrowTip = CGPoint(x: constants.arrowPosition == .left ? 0 : contentSize.width, y: arrowTipXOrigin)
        }
        self.frame = frame
    }

    private func drawBubble(_ bubbleFrame: CGRect, arrowPosition: ArrowPosition, context: CGContext) {
        let arrowWidth = constants.arrowWidth
        let arrowHeight = constants.arrowHeight
        let cornerRadius = constants.cornerRadius
        let contourPath = CGMutablePath()

        contourPath.move(to: CGPoint(x: arrowTip.x, y: arrowTip.y))

        switch arrowPosition {
        case .bottom, .top, .any:
            contourPath.addLine(to: CGPoint(x: arrowTip.x - arrowWidth / 2, y: arrowTip.y + (arrowPosition == .bottom ? -1 : 1) * arrowHeight))
            if arrowPosition == .bottom {
                drawBubbleBottomShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            } else {
                drawBubbleTopShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            }
            contourPath.addLine(to: CGPoint(x: arrowTip.x + arrowWidth / 2, y: arrowTip.y + (arrowPosition == .bottom ? -1 : 1) * arrowHeight))
        case .topRight, .topLeft, .bottomRight, .bottomLeft:
            contourPath.addLine(to: CGPoint(x: arrowTip.x - arrowWidth / 2, y: arrowTip.y + (arrowPosition.isAlongBottom() ? -1 : 1) * arrowHeight))
            if arrowPosition.isAlongBottom() {
                drawBubbleBottomShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            } else {
                drawBubbleTopShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            }
            contourPath.addLine(to: CGPoint(x: arrowTip.x + arrowWidth / 2, y: arrowTip.y + (arrowPosition.isAlongBottom() ? -1 : 1) * arrowHeight))
        case .right, .left:
            contourPath.addLine(to: CGPoint(x: arrowTip.x + (arrowPosition == .right ? -1 : 1) * arrowHeight, y: arrowTip.y - arrowWidth / 2))
            if arrowPosition == .right {
                drawBubbleRightShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            } else {
                drawBubbleLeftShape(bubbleFrame, cornerRadius: cornerRadius, path: contourPath)
            }
            contourPath.addLine(to: CGPoint(x: arrowTip.x + (arrowPosition == .right ? -1 : 1) * arrowHeight, y: arrowTip.y + arrowWidth / 2))
        }

        contourPath.closeSubpath()
        context.addPath(contourPath)
        context.clip()

        paintBubble(context)
    }

    private func drawBubbleBottomShape(_ frame: CGRect, cornerRadius: CGFloat, path: CGMutablePath) {
        path.addArc(tangent1End: frame.bottomLeft, tangent2End: frame.topLeft, radius: cornerRadius)
        path.addArc(tangent1End: frame.topLeft, tangent2End: frame.topRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.topRight, tangent2End: frame.bottomRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomRight, tangent2End: frame.bottomLeft, radius: cornerRadius)
    }

    private func drawBubbleTopShape(_ frame: CGRect, cornerRadius: CGFloat, path: CGMutablePath) {
        path.addArc(tangent1End: frame.topLeft, tangent2End: frame.bottomLeft, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomLeft, tangent2End: frame.bottomRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomRight, tangent2End: frame.topRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.topRight, tangent2End: frame.topLeft, radius: cornerRadius)
    }

    private func drawBubbleRightShape(_ frame: CGRect, cornerRadius: CGFloat, path: CGMutablePath) {
        path.addArc(tangent1End: frame.topRight, tangent2End: frame.topLeft, radius: cornerRadius)
        path.addArc(tangent1End: frame.topLeft, tangent2End: frame.bottomLeft, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomLeft, tangent2End: frame.bottomRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomRight, tangent2End: frame.topRight, radius: cornerRadius)
    }

    private func drawBubbleLeftShape(_ frame: CGRect, cornerRadius: CGFloat, path: CGMutablePath) {
        path.addArc(tangent1End: frame.topLeft, tangent2End: frame.topRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.topRight, tangent2End: frame.bottomRight, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomRight, tangent2End: frame.bottomLeft, radius: cornerRadius)
        path.addArc(tangent1End: frame.bottomLeft, tangent2End: frame.topLeft, radius: cornerRadius)
    }

    private func paintBubble(_ context: CGContext) {
        context.setFillColor(constants.backgroundColor.cgColor)
        context.fill(bounds)
    }

    private func addContentView(_ bubbleFrame: CGRect, context: CGContext) {
        let contentViewRect = CGRect(x: bubbleFrame.origin.x + (bubbleFrame.size.width - contentViewSize.width) / 2,
                                     y: bubbleFrame.origin.y + (bubbleFrame.size.height - contentViewSize.height) / 2,
                                     width: contentViewSize.width,
                                     height: contentViewSize.height)
        addSubview(contentView)
        contentView.frame = contentViewRect
    }

    override func draw(_ rect: CGRect) {
        let arrowPosition = constants.arrowPosition
        let bubbleWidth: CGFloat
        let bubbleHeight: CGFloat
        let bubbleXOrigin: CGFloat
        let bubbleYOrigin: CGFloat
        switch arrowPosition {
        case .bottom, .top, .any, .topRight, .topLeft, .bottomRight, .bottomLeft:
            bubbleWidth = contentSize.width - 2 * constants.horizontalInset
            bubbleHeight = contentSize.height - constants.arrowHeight
            bubbleXOrigin = constants.horizontalInset
            bubbleYOrigin = arrowPosition.isAlongBottom() ? 0 : constants.arrowHeight
        case .left, .right:
            bubbleWidth = contentSize.width - 2 * constants.horizontalInset - constants.arrowHeight
            bubbleHeight = contentSize.height
            bubbleXOrigin = arrowPosition == .right ? constants.horizontalInset : constants.horizontalInset + constants.arrowHeight
            bubbleYOrigin = 0
        }
        let bubbleFrame = CGRect(x: bubbleXOrigin, y: bubbleYOrigin, width: bubbleWidth, height: bubbleHeight)

        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()

        drawBubble(bubbleFrame, arrowPosition: constants.arrowPosition, context: context)
        addContentView(bubbleFrame, context: context)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowRadius = 10

        context.restoreGState()
    }
}

// MARK: - convenience methods
extension BalloonView {
    func show(onTapped: @escaping OnTappedStep = { _ in return nil }) {
        _onTapped = onTapped
        transform = constants.initialTransform
        alpha = constants.initialAlpha
        UIView.animate(withDuration: constants.animateDuration,
                       delay: 0,
                       usingSpringWithDamping: constants.springDamping,
                       initialSpringVelocity: constants.springVelocity,
                       options: [.curveEaseInOut],
                       animations: {
                        self.transform = self.constants.endTransform
                        self.alpha = 1 },
                       completion: nil)
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: constants.dismissDuration,
                       delay: 0,
                       usingSpringWithDamping: constants.springDamping,
                       initialSpringVelocity: constants.springVelocity,
                       options: [.curveEaseInOut],
                       animations: {
                        self.transform = self.constants.dismissTransform
                        self.alpha = self.constants.dismissAlpha },
                       completion: { _ in
                        completion?()
                        self.removeFromSuperview()
                        self.transform = CGAffineTransform.identity
        }
    )
    }
}

// MARK: - Chain onTapped
typealias OnTappedStep = (BalloonView?) -> BalloonView?
infix operator >>>: FunctionArrowPrecedence
func >>> (onTappedOne: @escaping OnTappedStep, onTappedTwo: @escaping OnTappedStep) -> OnTappedStep {
    return { balloonView in
        balloonView?._onTappedNext = onTappedTwo
        return onTappedOne(balloonView)
    }
}

// MARK: - private extensions
private extension UIView {
    func adjustWidthForScreen(horizontalInset: CGFloat) {
        let deviceScreenWidth = UIScreen.main.bounds.width
        let totalHorizontalInset = 2 * horizontalInset
        let maxContentViewWidth = deviceScreenWidth - totalHorizontalInset
        let widthAdjustment = max(0, frame.width - maxContentViewWidth)
        frame.size = CGSize(width: frame.width - widthAdjustment, height: frame.height)
    }
}

private extension CGRect {
    var center: CGPoint { return CGPoint(x: origin.x + width / 2, y: origin.y + height / 2) }
    var bottomLeft: CGPoint { return CGPoint(x: origin.x, y: origin.y + height) }
    var topLeft: CGPoint { return CGPoint(x: origin.x, y: origin.y) }
    var topRight: CGPoint { return CGPoint(x: origin.x + width, y: origin.y) }
    var bottomRight: CGPoint { return CGPoint(x: origin.x + width, y: origin.y + height) }
}
