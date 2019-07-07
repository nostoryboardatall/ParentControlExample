//
//  TimerNode.swift
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
import UIKit
import AVFoundation

public typealias TimerEndAction = ((_ timer: TimerNode) -> Void)

public class TimerNode: SKNode {
    public var action: TimerEndAction?
    
    public var start: Int
    
    public var interval: TimeInterval
    
    public var isSoundEnabled: Bool = true
    
    public var color: SKColor = .red {
        didSet {
            label.fontColor = color
        }
    }
    
    public var size: CGFloat = 37.0 {
        didSet {
            label.fontSize = size
        }
    }
    
    public var font: UIFont = UIFont.boldSystemFont(ofSize: 77.0) {
        didSet {
            label.fontName = font.fontName
        }
    }
    
    fileprivate var currentValue: Int
    
    fileprivate var label: SKLabelNode = SKLabelNode()
    
    fileprivate let ticSoundID: SystemSoundID = 1103
    
    init(start: Int = 5, interval: TimeInterval = 1.0, completion: TimerEndAction? = nil) {
        self.start = start
        self.currentValue = start
        self.interval = interval
        self.action = completion
        super.init()
        
        setupNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func fire() {
        invalidate()
        timer()
    }
    
    public func invalidate() {
        removeAllActions()
        label.setScale(0.0)
        label.text = "\(start)"
        currentValue = start
    }
    
    fileprivate func setupNode() {
        label.text = "\(start)"
        label.fontName = font.fontName
        label.fontSize = font.pointSize
        label.fontColor = color
        label.setScale(0.0)

        addChild(label)
    }
    
    fileprivate func timer() {
        if currentValue == 0 {
            action?(self)
        } else {
            currentValue = currentValue - 1
            if isSoundEnabled { AudioServicesPlaySystemSound( ticSoundID ) }
            tic(duration: interval) { [weak self] in
                self?.label.text = "\(self?.currentValue ?? -1)"
                self?.timer()
            }
        }
    }
    
    fileprivate func tic(duration: TimeInterval, completion: @escaping (() -> Void)) {
        label.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.13).easeInEaseOut(),
            SKAction.wait(forDuration: duration)
        ])  ) { [weak self] in
            self?.label.setScale(0.0)
            completion()
        }
    }
}

extension SKAction {
    public func easeIn() -> SKAction {
        self.timingMode = .easeIn
        return self
    }
    
    public func easeOut() -> SKAction {
        self.timingMode = .easeOut
        return self
    }
    
    public func easeInEaseOut() -> SKAction {
        self.timingMode = .easeInEaseOut
        return self
    }
}
