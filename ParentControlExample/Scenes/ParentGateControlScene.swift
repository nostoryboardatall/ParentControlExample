//
//  GameScene.swift
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
import GameplayKit

class ParentGateControlScene: UIScene {
    let background = SKSpriteNode(imageNamed: "checkerboard")
    
    let purchaseButton = ButtonNode(textureNamed: "purchase-button")
    let timerButton = ButtonNode(textureNamed: "timer-button")
    
    var timer = TimerNode()
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        background.zPosition = 0
        purchaseButton.zPosition = 10
        timerButton.zPosition = 10
        
        timer.zPosition = 20
        
        addChild(background)
        addChild(purchaseButton)
        addChild(timerButton)
        
        addChild(timer)
        
        purchaseButton.action = handler(_:)
        timerButton.action = timer(_:)
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        background.size = view.bounds.size
        background.position = view.bounds.midPoint
        
        let buttonSize = purchaseButton.size
        
        purchaseButton.position = CGPoint(x: view.bounds.midX - buttonSize.width, y: buttonSize.height)
        timerButton.position = CGPoint(x: view.bounds.midX + buttonSize.width, y: buttonSize.height)
        
        timer.position = view.bounds.midPoint
        timer.action = timerEndsUp(_:)
    }
    
    fileprivate func handler(_ sender: ButtonNode) {
        let gate = ParentGateNode()
        gate.zPosition = 20
        
        gate.present(on: self) { [weak self] in
            let alert = UIAlertController(title: "Parent Gate Control", message: "Succsess", preferredStyle: .alert)
            alert.addAction( UIAlertAction(title: "Close", style: .destructive) )
            self?.rootController?.present(alert, animated: true)
        }
    }

    fileprivate func timer(_ sender: ButtonNode) {
        timer.fire()
    }
    
    fileprivate func timerEndsUp(_ timer: TimerNode) {
        let alert = UIAlertController(title: "Timer", message: "Time is Up", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "OK", style: .default) )
        rootController?.present(alert, animated: true)
    }
}
