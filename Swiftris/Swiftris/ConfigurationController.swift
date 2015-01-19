//
//  ConfigurationController.swift
//  Swiftris
//
//  Created by Sameer Totey on 1/18/15.
//  Copyright (c) 2015 Sameer Totey. All rights reserved.
//

import UIKit
import GameKit

class ConfigurationController: UIViewController, UITextFieldDelegate, GameViewControllerDelegate, GKGameCenterControllerDelegate {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var gameModeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var timeLengthTextField: UITextField!
    @IBOutlet weak var leaderBoardButton: UIButton!
    
    var gameViewController: GameViewController?
    var gameMode = GameMode.classic
    var maxTime = 60.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // listen to Game Center authentication requests
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showAuthenticationViewController:", name: presentGameCenterAuthenticationVeiwController, object: nil)

        setupGameFields()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Play Game" {
            if segue.destinationViewController is GameViewController {
                // save a reference to the game view controller
                gameViewController = segue.destinationViewController as? GameViewController
                gameViewController?.delegate = self
                gameViewController?.maxTime = maxTime
                gameViewController?.gameMode = gameMode
            }
        }
    }
    
    func showAuthenticationViewController(notification: NSNotification) {
        println("Show Authentication Notification")
        if let presentedVC = self.presentedViewController {
            dismissViewControllerAnimated(true, completion: nil)
        }
        // if there is a gameViewController pushed on top, ask it to pause the game
        gameViewController?.changeGameStateTo(paused: true)
        presentViewController(notification.object as UIViewController, animated: true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func gameModeChanged(sender: UISegmentedControl) {
        setupGameFields()
    }
    
    func setupGameFields() {
        switch (gameModeSegmentedControl.selectedSegmentIndex) {
        case 0:
            println("Classic mode selected")
            gameMode = .classic
            timeLengthTextField.hidden = true
        case 1:
            println("Timed mode selected")
            gameMode = .timed
            timeLengthTextField.hidden = false
        default:
            println("Error: invalid index for segment control")
        }
    }
    
    @IBAction func showLeaderBoard(sender: UIButton) {
        displayLeaderBoard("SwiftrisHighScore")
    }
    
    func gameDidEnd(#score: Int?, level: Int?) {
        println("Scored \(score) at level \(level)")
        if let reportingScore = score {
            var myScore: Int64
            myScore = Int64(reportingScore)
            reportScore(myScore, leaderBoardID: "SwiftrisHighScore")
        }
        displayLeaderBoard("SwiftrisHighScore")
    }
    
    func reportScore(score:Int64, leaderBoardID:String) {
        var scoreReporter = GKScore(leaderboardIdentifier: "SwiftrisHighScore")
        scoreReporter.value = score
        scoreReporter.context = 0
        GKScore.reportScores([scoreReporter], withCompletionHandler: { (error) -> Void in
            println("Completed Sending Score with Error: \(error)")
        })
    }
    
    func displayLeaderBoard(leaderBoardID:String) {
        var gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.gameCenterDelegate = self
        gameCenterViewController.viewState = .Leaderboards
        gameCenterViewController.leaderboardIdentifier = "SwiftrisHighScore"
        presentViewController(gameCenterViewController, animated: true, completion: nil)
    }
    
    // GKGameCenterDelegate
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        println("Game Center View Controller Did Finish")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        if let number = numberFormatter.numberFromString(textField.text) {
            self.maxTime = number as Double
        }
        return true
    }

    
}