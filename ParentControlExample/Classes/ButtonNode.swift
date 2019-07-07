//
//  ButtonNode.swift
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

import SpriteKit

public typealias ButtonAction = ((_ sender: ButtonNode) -> Void)

enum ButtonError: Error {
    case nullableTexture, indexOutOfRange, unknown
}

extension ButtonError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nullableTexture:
            return "Texture is not set"
        case .indexOutOfRange:
            return "Index out of range"
        default:
            return "Unknown Error"
        }
    }
}

public protocol ButtonNodeDelegate: class {
    func canPlaySound(_ button: ButtonNode) -> Bool
    func normalSoundFor(_ button: ButtonNode?) -> String?
    func disabledSoundFor(_ button: ButtonNode?) -> String?
}

extension ButtonNodeDelegate {
    public func canPlaySound(_ button: ButtonNode) -> Bool { return true }
    public func normalSoundFor(_ button: ButtonNode?) -> String? { return nil }
    public func disabledSoundFor(_ button: ButtonNode?) -> String? { return nil }
}

public class ButtonNode: SKSpriteNode {
    enum State: Int {
        case normal, highlighted, disabled
    }
    
    public weak var delegate: ButtonNodeDelegate?
    
    public var isDisabled: Bool = false {
        didSet {
            guard isDisabled != oldValue else { return }
            set(state: isDisabled ? .disabled : .normal)
        }
    }
    
    public var canPlaySounds: Bool = true
    
    public var normalSound: String?
    
    public var disabledSound: String?
    
    public var action: ButtonAction?
    
    public var tag: Int = -1
    
    fileprivate var globalCanPlaySound: Bool {
        if let delegate = delegate { return delegate.canPlaySound(self) }
        else { return canPlaySounds }
    }
    
    fileprivate(set) var state: State = .normal {
        didSet {
            guard state != oldValue else { return }
            set(state: state)
        }
    }
    
    private var stateNormalTexture: SKTexture?
    private var stateHighlightedTexture: SKTexture?
    private var stateDisabledTexture: SKTexture?

    init() {
        super.init(texture: nil, color: UIColor.clear, size: .zero)
        setupView()
    }
    
    init(texture: SKTexture, action: ButtonAction? = nil) {
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.action = action
        setupView()
    }
    
    convenience init(textureNamed: String, action: ButtonAction? = nil) {
        let texture = SKTexture(imageNamed: textureNamed)
        self.init(texture: texture, action: action)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupView() {
        isUserInteractionEnabled = true
        updateTextures()
    }
    
    fileprivate func playSound() {
        if let externalSound = state == .disabled ?
            delegate?.disabledSoundFor(self) : delegate?.normalSoundFor(self) {
            if ( !externalSound.isEmpty ) {
                run(SKAction.playSoundFileNamed(externalSound, waitForCompletion: false))
            }
        }
        guard let sound = state == .disabled ? disabledSound : normalSound else { return }
        if ( !sound.isEmpty ) {
            run(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
        }
    }
    
    fileprivate func updateTextures() {
        if let _ = texture {
            run(SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.stateNormalTexture = strongSelf.texture?.scaled()
                }, SKAction.run { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.stateHighlightedTexture = strongSelf.texture?.scaled(to: 1.1)
                }, SKAction.run { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.stateDisabledTexture = strongSelf.texture?.grayscale()
                }, SKAction.run { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.set(state: strongSelf.state == .disabled ? .disabled : .normal)
                }
            ]))
        }
    }
    
    fileprivate func setTexture(_ newTexture: SKTexture) {
        run(SKAction.setTexture(newTexture, resize: true)) {
            self.texture = newTexture
            self.updateTextures()
        }
    }

    fileprivate func set(state: State) {
        switch state {
        case .normal:
            if let _ = stateNormalTexture {
                run( SKAction.setTexture(stateNormalTexture!, resize: true) )
            }
        case .highlighted:
            if let _ = stateHighlightedTexture {
                run( SKAction.setTexture(stateHighlightedTexture!, resize: true) )
            }
        case .disabled:
            if let _ = stateDisabledTexture {
                run( SKAction.setTexture(stateDisabledTexture!, resize: true) )
            }
        }
    }
    
    fileprivate func tap() {
        if let action = action { action(self) }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDisabled else { return }
        state = .highlighted
        if ( globalCanPlaySound ) { playSound() }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDisabled else { return }
        state = .highlighted
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: parent!)
        guard !contains(touchLocation) else { return }
        state = .normal
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDisabled, state == .highlighted else { return }
        state = .normal
        tap()
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        guard !isDisabled else { return }
        state = .normal
    }
}

public class CheckmarkButtonNode: ButtonNode {
    var value: Bool {
        return isChecked
    }
    
    var isChecked: Bool = true {
        didSet {
            guard isChecked != oldValue else { return }
            guard let _ = textures[isChecked] else { return }
            setTexture(textures[isChecked]!)
        }
    }
    
    private(set) var textures: [Bool:SKTexture] = [:]
    
    init(on onTexture: SKTexture, off offTexture: SKTexture, action: ButtonAction? = nil) {
        super.init(texture: onTexture, action: action)
        textures[true] = onTexture
        textures[false] = offTexture
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tap() {
        isChecked = !isChecked
        super.tap()
    }
}

public protocol ButtonNodeDataSource: class {
    func collectionButtonNode(_ button: CollectionButtonNode, valueFor index: Int) -> Any?
    
    func collectionButtonNode(_ button: CollectionButtonNode, didChangeIndexTo index: Int)
}

extension ButtonNodeDataSource {
    func collectionButtonNode(_ button: CollectionButtonNode, valueFor index: Int) -> Any? { return nil }
    func collectionButtonNode(_ button: CollectionButtonNode, didChangeIndexTo index: Int) {}
}

public class CollectionButtonNode: ButtonNode {
    public enum ToggleDirection: Int {
        case up, down
    }
    
    public weak var dataSource: ButtonNodeDataSource?
    
    public var value: Any? {
        return dataSource?.collectionButtonNode(self, valueFor: index)
    }
    
    public var index: Int {
        return textureIndex
    }
    
    public var isToggleIndexOnTap: Bool = true
    public var toggleDirection: ToggleDirection = .up
    
    private(set) var textures: [SKTexture] = []
    
    private var textureIndex: Int = 0 {
        didSet {
            guard textureIndex != oldValue else { return }
            dataSource?.collectionButtonNode(self, didChangeIndexTo: textureIndex)
        }
    }
    
    init?(with textures: [SKTexture], action: ButtonAction? = nil) throws {
        guard let texture = textures.first else { throw ButtonError.nullableTexture }
        super.init(texture: texture, action: action)
        self.textures.append(contentsOf: textures)
    }
    
    init?(_ textures: SKTexture..., action: ButtonAction? = nil) throws {
        guard let texture = textures.first else { throw ButtonError.nullableTexture }
        super.init(texture: texture, action: action)
        self.textures.append(contentsOf: textures)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tap() {
        if ( isToggleIndexOnTap ) {
            if ( toggleDirection == .up ) { next() }
            else { prev() }
        }
        super.tap()
    }
    
    public func setTexture(at index: Int) throws {
        guard (0..<textures.count).contains(index) else { throw ButtonError.nullableTexture }
        textureIndex = index
        setTexture(textures[textureIndex])
    }
    
    public func next() {
        textureIndex = textureIndex < textures.count - 1 ? textureIndex + 1 : 0
        setTexture(textures[textureIndex])
    }
    
    public func prev() {
        textureIndex = textureIndex > 0 ? textureIndex - 1 : textures.count - 1
        setTexture(textures[textureIndex])
    }
}

extension SKTexture {
    func grayscale() -> SKTexture? {
        guard let filter = CIFilter(name: "CIColorControls", parameters: ["inputSaturation": 0.0]) else { return nil }
        return applying(filter)
    }
    
    func scaled(to scale: CGFloat = 1.0) -> SKTexture {
        let realScaleFactor = 1.0 / scale
        let uiImage = UIImage(cgImage: cgImage(),
                              scale: (CGFloat(cgImage().width) / size().width) * realScaleFactor,
                              orientation: .up)
        return SKTexture(image: uiImage)
    }
}
