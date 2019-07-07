//
//  ParentGateNode.swift
//
//  Created by Home on 2019.
//  Copyright 2017-2018 NoStoryboardsAtAll Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import AVFoundation
import SpriteKit

public typealias ParentCompletion = (() -> Void)

public protocol UniqueNode: class {
    static func isUnique(on scene: SKScene?) -> Bool
}

public protocol ParentGateNodeDelegate: class {
    func onAccept(_ gate: ParentGateNode)
    func onDecline(_ gate: ParentGateNode)
}

public class ParentGateNode: SKNode, UniqueNode {
    public enum ButtonType {
        case cross, arrow, image(UIImage)
    }
    
    public var completion: ParentCompletion?
    
    public var buttonType: ButtonType = .arrow {
        didSet {
            closeButton.texture = textureForButton(buttonType)
        }
    }
    
    public var title: String = "Ask Your Parents" {
        didSet {
            setTitles()
        }
    }
    
    public var message: String = "Drag the %@ inside the %@." {
        didSet {
            setTitles()
        }
    }
    
    public var fillColor: SKColor = .gray {
        didSet {
            setColors()
        }
    }
    
    public var strokeColor: SKColor = .white {
        didSet {
            setColors()
        }
    }
    
    fileprivate let errorSoundID: SystemSoundID = 1102
    
    fileprivate let succsessSoundID: SystemSoundID = 1101
    
    fileprivate let vibrateSoundID: SystemSoundID = 4095
    
    fileprivate weak var selectedNode: SKNode?
    
    fileprivate var savedPosition: CGPoint = .zero
    
    fileprivate var items: [ParentGateNodeItem] = []
    
    fileprivate var sourceIndex: Int = 0
    
    fileprivate var destinationIndex: Int = 0
    
    fileprivate lazy var background: SKSpriteNode = {
        let node = SKSpriteNode(color: .black, size: .zero)
        node.name = "parentgate_background"
        node.alpha = 0.80
        node.zPosition = 0

        return node
    }()
    
    fileprivate lazy var closeButton: ButtonNode = {
        let node = ButtonNode(texture: textureForButton(buttonType)!, action: closeAction(_:))
        node.zPosition = 1
        
        return node
    }()
    
    fileprivate lazy var titleLabel: SKLabelNode = {
        let node = SKLabelNode()
        node.zPosition = 1
        node.fontName = UIFont.boldSystemFont(ofSize: 21.0).fontName
        node.fontSize = 21.0
        node.fontColor = .white
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.text = title

        return node
    }()

    fileprivate lazy var messageLabel: SKLabelNode = {
        let node = SKLabelNode()
        node.zPosition = 1
        node.fontName = UIFont.systemFont(ofSize: 19.0).fontName
        node.fontSize = 19.0
        node.fontColor = .white
        node.numberOfLines = 0
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.text = String(format: message, "_", "_")

        return node
    }()
    
    /** gesture recogniser */
    private lazy var panGestureRecognizer: UIPanGestureRecognizer! =
        UIPanGestureRecognizer(target: self, action: #selector(_handlePan))
    
    override init() {
        super.init()
        setupNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static public func isUnique(on scene: SKScene?) -> Bool {
        guard let _ = scene?.children.filter({ $0 is ParentGateNode }).first else { return true }
        return false
    }
    
    public func present(on scene: SKScene?, handler: @escaping ParentCompletion) {
        guard ParentGateNode.isUnique(on: scene) else { return }
        guard let view = scene?.view else { return }
        
        completion = handler
        setPositions(on: view)
        
        scene?.view?.addGestureRecognizer(panGestureRecognizer)
        scene?.addChild(self)
    }
    
    @objc fileprivate func _handlePan() {
        guard let scene = scene else { return }
        guard scene.isUserInteractionEnabled else { return }
        
        let location = scene.convertPoint(fromView: panGestureRecognizer.location(in: scene.view))
        switch panGestureRecognizer.state {
        case .began:
            select(at: location)
        case .changed:
            drag(to: location)
        case .ended:
            drop()
        case .cancelled:
            cancel()
        default:
            break
        }
    }

    fileprivate func select(at location: CGPoint) {
        guard let item = itemAt(location) else { return }
        selectedNode = item
        savedPosition = item.position
        selectedNode?.run(SKAction.scale(to: 1.2, duration: 0.13))
    }
    
    fileprivate func drop() {
        guard let source = selectedNode as? ParentGateNodeItem else { return }
        
        if let destination = destination() {
            control(source, with: destination)
        } else {
            source.run(SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.13),
                SKAction.move(to: savedPosition, duration: 0.13)
            ]))
        }
        selectedNode = nil
    }
    
    fileprivate func drag(to location: CGPoint) {
        selectedNode?.run(SKAction.move(to: location, duration: 0.0))
    }
    
    fileprivate func cancel() {
        guard let item = selectedNode as? ParentGateNodeItem else { return }
        item.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.13),
            SKAction.move(to: savedPosition, duration: 0.13)
            ]))
        selectedNode = nil
    }
    
    fileprivate func itemAt(_ location: CGPoint) -> ParentGateNodeItem? {
        let nodesAtLocation = nodes(at: location)
        return nodesAtLocation.filter({ return $0 is ParentGateNodeItem }).first as? ParentGateNodeItem
    }
    
    fileprivate func destination() -> ParentGateNodeItem? {
        guard let item = selectedNode else { return nil }
        return items.filter({ return $0 != item && item.intersects($0) }).first
    }
    
    fileprivate func setupNode() {
        isUserInteractionEnabled = true
        setupItems()
        
        addChild(background)
        addChild(closeButton)
        addChild(titleLabel)
        addChild(messageLabel)
        items.forEach({ addChild($0) })
        
        setTitles()
        setColors()
    }
    
    fileprivate func setupItems() {
        let styles: [ParentGateNodeItem.Style] = [.triangle, .square, .circle]
        styles.forEach({
            let item = ParentGateNodeItem(style: $0)
            item.zPosition = 2
            items.append(item)
        })
        items.shuffle()
        
        while sourceIndex == destinationIndex {
            sourceIndex = Int.random(in: items.indices)
            destinationIndex = Int.random(in: items.indices)
        }
    }
    
    fileprivate func setTitles() {
        titleLabel.text = title
        messageLabel.text = String(format: message, items[sourceIndex].title, items[destinationIndex].title)
    }
    
    fileprivate func setColors() {
        items.forEach({ $0.strokeColor = strokeColor })
        titleLabel.fontColor = strokeColor as UIColor
        messageLabel.fontColor = strokeColor as UIColor
        if let buttonTexture = textureForButton(buttonType) { closeButton.texture = buttonTexture }
        background.color = fillColor
    }
    
    fileprivate func setPositions(on view: SKView) {
        background.size = view.bounds.size
        background.position = view.frame.midPoint
        
        closeButton.position = CGPoint(x: view.safeAreaInsets.left + (closeButton.size.width + 4.0),
                                       y: view.bounds.size.height - (closeButton.size.height + view.safeAreaInsets.top + 4.0))
        
        titleLabel.position = CGPoint(x: view.frame.midX, y: closeButton.position.y)
        messageLabel.preferredMaxLayoutWidth = view.frame.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        messageLabel.position = CGPoint(x: view.frame.midX, y: closeButton.position.y - (messageLabel.frame.size.height + 24.0))
        
        if view.bounds.width > view.bounds.height {
            placeHorizontally(on: view)
        } else {
            placeVertically(on: view)
        }
    }
    
    fileprivate func placeHorizontally(on view: SKView) {
        let itemSize = min(view.bounds.size.width, view.bounds.size.height) / 5
        items.forEach({
            $0.lineWidth = 4.0
            $0.size = itemSize
            $0.position = view.bounds.midPoint
        })
        
        items.first?.position.x -= itemSize * 1.7
        items.first?.position.y -= itemSize * 0.3
        items.first?.zRotation = .pi * 0.1
        
        items.last?.position.x  += itemSize * 1.7
        items.last?.position.y  -= itemSize * 0.3
        items.last?.zRotation = .pi * -0.1
    }
    
    fileprivate func placeVertically(on view: SKView) {
        let itemSize = min(view.bounds.size.width, view.bounds.size.height) / 5
        items.forEach({
            $0.lineWidth = 4.0
            $0.size = itemSize
            $0.position = view.bounds.midPoint
            $0.position.x += itemSize * 0.15
        })
        
        items.first?.position.y += itemSize * 1.7
        items.first?.position.x -= itemSize * 0.15
        items.first?.zRotation = .pi * 0.1
        
        items.last?.position.y  -= itemSize * 1.7
        items.last?.position.x  -= itemSize * 0.15
        items.last?.zRotation = .pi * -0.1
    }
    
    fileprivate func control(_ source: ParentGateNodeItem, with destination: ParentGateNodeItem) {
        var sequence: [SKAction] = []
        
        if (items.firstIndex(of: source) ?? -1 == sourceIndex) &&
            (items.firstIndex(of: destination) ?? -1 == destinationIndex) {
            sequence = [
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    AudioServicesPlaySystemSound(self.succsessSoundID)
                },
                SKAction.run { [weak self] in self?.completion?() },
                SKAction.run { [weak self] in self?.removeFromParent() }
            ]
        } else {
            sequence = [
                SKAction.run { [weak self] in self?.error() },
                SKAction.run { [weak self] in self?.removeFromParent() }
            ]
        }
        
        scene?.view?.removeGestureRecognizer(panGestureRecognizer)
        run(SKAction.sequence(sequence))
    }
    
    fileprivate func error() {
        AudioServicesPlaySystemSound(vibrateSoundID)
        AudioServicesPlaySystemSound(errorSoundID)
    }
    
    fileprivate func closeAction(_ sender: ButtonNode) {
        scene?.view?.removeGestureRecognizer(panGestureRecognizer)
        removeFromParent()
    }
    
    fileprivate func textureForButton(_ type: ButtonType) -> SKTexture? {
        switch type {
        case .arrow:
            let shape = SKShapeNode()
            shape.lineWidth = 3.0
            shape.strokeColor = strokeColor
            shape.path = UIBezierPath.arrow(distance: 24.0, cornerRadius: 7.0, direction: .left)
            
            let view = SKView(frame: UIScreen.main.bounds)
            return view.texture(from: shape)
        case .cross:
            let shape = SKShapeNode()
            shape.lineWidth = 3.0
            shape.strokeColor = strokeColor
            shape.path = UIBezierPath.cross(distance: 24.0, cornerRadius: 7.0)
            
            let view = SKView(frame: UIScreen.main.bounds)
            return view.texture(from: shape)
        case let .image(customImage):
            return SKTexture(image: customImage)
        }
    }
}

public class ParentGateNodeItem: SKShapeNode {
    public enum Style {
        case square, triangle, circle, custom(CGPath)
    }
    
    public var style: Style {
        didSet {
            drawShape()
        }
    }
    
    public var size: CGFloat {
        didSet {
            drawShape()
        }
    }
    
    public override var lineWidth: CGFloat {
        didSet {
            drawShape()
        }
    }
    
    public override var strokeColor: SKColor {
        didSet {
            drawShape()
        }
    }
    
    public var title: String {
        switch style {
            case .circle: return "Circle"
            case .square: return "Square"
            case .triangle: return "Triangle"
            default: return "Custom Shape"
        }
    }
    
    init(style: Style, size: CGFloat = 0.0) {
        self.style = style
        self.size = size
        super.init()
        drawShape()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func drawShape() {
        switch style {
        case .square:
            let bounds = CGRect(origin: CGPoint(x: -size * 0.5, y: -size * 0.5), size: CGSize(width: size, height: size))
            path = UIBezierPath(roundedRect: bounds, cornerRadius: 7.0).cgPath
        case .circle:
            let bounds = CGRect(origin: CGPoint(x: -size * 0.5, y: -size * 0.5), size: CGSize(width: size, height: size))
            path = UIBezierPath(ovalIn: bounds).cgPath
        case .triangle:
            let cgTriangle = UIBezierPath.triangle(width: size, height: size, cornerRadius: 7.0)
            path = UIBezierPath(cgPath: cgTriangle).cgPath
        case let .custom(customPath):
            path = customPath
        }
    }
}

extension UIBezierPath {
    public enum ArrowDirection: Int {
        case left, right
    }
    
    public class func triangle(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> CGPath {
        let point1 = CGPoint(x: -width * 0.5, y: -height * 0.5)
        let point2 = CGPoint(x: 0.0, y: height * 0.5)
        let point3 = CGPoint(x: width * 0.5, y: -height * 0.5)


        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.0, y: -height * 0.5))
            path.addArc(tangent1End: point1, tangent2End: point2, radius: cornerRadius)
            path.addArc(tangent1End: point2, tangent2End: point3, radius: cornerRadius)
            path.addArc(tangent1End: point3, tangent2End: point1, radius: cornerRadius)
        path.closeSubpath()
        
        return path
    }
    
    public class func cross(distance: CGFloat, cornerRadius: CGFloat) -> CGPath {
        let points: [CGPoint] = [
            CGPoint(x: -distance * 0.5, y:  distance * 0.5),
            CGPoint(x:  distance * 0.5, y:  distance * 0.5),
            CGPoint(x: -distance * 0.5, y: -distance * 0.5),
            CGPoint(x:  distance * 0.5, y: -distance * 0.5),
        ]
        
        let path = CGMutablePath()
        
        points.forEach({
            path.move(to: .zero)
            path.addArc(tangent1End: $0, tangent2End: .zero, radius: cornerRadius)
        })
        
        return path
    }
    
    public class func arrow(distance: CGFloat, cornerRadius: CGFloat, direction: ArrowDirection) -> CGPath {
        let point1 = direction == .left ? CGPoint(x: -distance * 0.5, y: 0.0) : CGPoint(x: distance * 0.5, y: 0.0)
        let point2 = CGPoint(x: 0.0, y: distance * 0.5)
        let point3 = CGPoint(x: 0.0, y: -distance * 0.5)
        
        let path = CGMutablePath()
        path.move(to: point1)
            path.addArc(tangent1End: point2, tangent2End: point1, radius: cornerRadius)
            path.addArc(tangent1End: point1, tangent2End: point2, radius: cornerRadius)
            path.addArc(tangent1End: point3, tangent2End: point1, radius: cornerRadius)
        path.closeSubpath()
        
        return path
    }
}

extension CGRect {
    public var midPoint: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}
