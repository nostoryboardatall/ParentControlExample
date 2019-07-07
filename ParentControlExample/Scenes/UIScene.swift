//
//  SKLayoutScene.swift
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
import SpriteKit


class UIScene: SKScene {
    var rootController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    /** is safe area hidden */
    public var isSafeAreaHidden: Bool = true {
        didSet {
            safeArea.isHidden = isSafeAreaHidden
        }
    }

    /** safe area insets. normally sets on updateSafeAreaConstraints */
    public var safeAreaInsets: UIEdgeInsets? {
        didSet {
            if let _ = safeAreaInsets {
                updateSafeAreaConstraints()
            }
        }
    }
    
    /** safe area of the device */
    private(set) var safeArea: SKShapeNode = {
        let node = SKShapeNode()
        
        node.name = "_safearea"
        
        node.fillColor = SKColor.green
        node.strokeColor = SKColor.green
        node.lineWidth = 7.0
        
        node.alpha = 0.25
        node.zPosition = 0
        
        node.isHidden = true
        
        return node
    }()
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        addChild(safeArea)
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.setNeedsLayout()
    }

    public func updateSafeAreaConstraints() {
        if let safeAreaInsets = safeAreaInsets, let screenSize = view?.bounds.size {
            
            let leftTopPoint = CGPoint(x: safeAreaInsets.left,
                                       y: screenSize.height - safeAreaInsets.top)
            let rightBottomPoint = CGPoint(x: screenSize.width - safeAreaInsets.right,
                                           y: safeAreaInsets.bottom)
            let safeAreaFrame = CGRect(origin: CGPoint(x: leftTopPoint.x, y: rightBottomPoint.y),
                                       size: CGSize(width: rightBottomPoint.x - leftTopPoint.x,
                                                    height: leftTopPoint.y - rightBottomPoint.y))
            
            safeArea.path = UIBezierPath(roundedRect: safeAreaFrame, cornerRadius: 7.0).cgPath
        }
    }
}
