//
//  GameViewController.swift
//  Swiftris
//
//  Created by Sameer Totey on 1/14/15.
//  Copyright (c) 2015 Sameer Totey. All rights reserved.
//

import UIKit
import SpriteKit

enum GameMode {
    case classic
    case timed
}

protocol GameViewControllerDelegate {
    func gameDidEnd(#score:Int?, level:Int?)
}

class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate {

    var scene: GameScene!
    var swiftris:Swiftris!
    
    var panPointReference:CGPoint?
    
    var delegate: GameViewControllerDelegate?
    
    var gameMode: GameMode = .classic{
        didSet {
            if gameMode == .classic{
                self.timeRemainingLabel?.hidden = true
            } else {
                self.timeRemainingLabel?.hidden = false
            }
        }
    }
    
    var gameStartTime = NSDate()
    var gameElapsedTime = NSTimeInterval()
    var maxTime = 60.0
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    @IBOutlet weak var pausedLabel: UILabel!
    
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listen to Game Center authentication requests
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showAuthenticationViewController:", name: presentGameCenterAuthenticationVeiwController, object: nil)

        // Configure the view.
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        
        swiftris = Swiftris()
        swiftris.delegate = self
        swiftris.beginGame()
        
        // Present the scene.
        skView.presentScene(scene)
        
        // This is required because the view outlets are not set in the prepare for Segue in the previous controller
        if gameMode == .classic{
            self.timeRemainingLabel?.hidden = true
        } else {
            self.timeRemainingLabel?.hidden = false
        }

        
    }

    func showAuthenticationViewController(notification: NSNotification) {
        println("Show Notification")
        if let presentedVC = self.presentedViewController {
            dismissViewControllerAnimated(true, completion: nil)
        }
        changeGameStateTo(paused: true)
        presentViewController(notification.object as UIViewController, animated: true, completion: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        swiftris.rotateShape()
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    swiftris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    swiftris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        swiftris.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        if let swipeRec = gestureRecognizer as? UISwipeGestureRecognizer {
            if let panRec = otherGestureRecognizer as? UIPanGestureRecognizer {
                return true
            }
        } else if let panRec = gestureRecognizer as? UIPanGestureRecognizer {
            if let tapRec = otherGestureRecognizer as? UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
    func didTick() {
        swiftris.letShapeFall()
        if gameMode == .timed {
            gameElapsedTime = gameStartTime.timeIntervalSinceNow
            println("TimeInterval \(gameElapsedTime * -1)")
            if  (maxTime + gameElapsedTime) > 0 {
                timeRemainingLabel.text = "\(maxTime + gameElapsedTime)"
            } else {
                changeGameStateTo(paused: true)
            }
        }
    }
    
    func nextShape() {
        let newShapes = swiftris.newShape()
        if let fallingShape = newShapes.fallingShape {
            self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
            self.scene.movePreviewShape(fallingShape) {
                self.view.userInteractionEnabled = true
                self.scene.startTicking()
            }
        }
    }
    @IBAction func didLongPress(sender: UILongPressGestureRecognizer) {
        // pause sprite kit
        if sender.state == .Began {
            let skView = view as SKView
            // toggle the paused state of the game
            changeGameStateTo(paused: !skView.paused)
        }
     }
    
    func changeGameStateTo(#paused:Bool) {
        let skView = view as SKView
        skView.paused = paused
        pausedLabel.hidden = !paused
        if skView.paused {
            scene.backgroundAudioPlayer.pause()
        } else {
            scene.backgroundAudioPlayer.play()
        }

    }
    
     
    func gameDidBegin(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        gameStartTime = NSDate()

        // The following is false when restarting a new game
        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(swiftris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(swiftris: Swiftris) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            // report the score to game center
            println("Game ended")
            self.scene.backgroundAudioPlayer.stop()
            self.delegate?.gameDidEnd(score: self.swiftris.score, level: self.swiftris.level)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    func gameDidLevelUp(swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(swiftris: Swiftris) {
        scene.stopTicking()
        scene.redrawShape(swiftris.fallingShape!) {
            swiftris.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(swiftris: Swiftris) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        // #1
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(swiftris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                // #2
                self.gameShapeDidLand(swiftris)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(swiftris: Swiftris) {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
    
}
