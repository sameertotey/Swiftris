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
        var model = Model()
        model.foo()
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
            if let reportingLevel = level {
                var myLevel = reportingLevel - 1
                var myPercent:Double
                myPercent = Double(myScore) % 100.00
                var achievements = [String:Double]()
                switch myLevel {
                case 0:
                    achievements["SwiftrisLevel1"] = myPercent
                    achievements["SwiftrisLevel2"] = 0.00
                case 1:
                    achievements["SwiftrisLevel1"] = 100.0
                    achievements["SwiftrisLevel2"] = myPercent
                case 2:
                    achievements["SwiftrisLevel1"] = 100.0
                    achievements["SwiftrisLevel2"] = 100.00
                default:
                    println("Somebody have moved to higher levels!!!!")
                }
                reportAllAchievements(achievements)
            }
        }
        displayLeaderBoard("SwiftrisHighScore")
    }
    
    func reportScore(score:Int64, leaderBoardID:String) {
        let scoreReporter = GKScore(leaderboardIdentifier: "SwiftrisHighScore")
        scoreReporter.value = score
        println("Reporting Score \(score)")
        scoreReporter.context = 0
        GKScore.reportScores([scoreReporter], withCompletionHandler: { (error) -> Void in
            println("Completed Sending Score with Error: \(error)")
        })
    }
    
    func displayLeaderBoard(leaderBoardID:String) {
        let gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.gameCenterDelegate = self
        gameCenterViewController.viewState = .Leaderboards
        gameCenterViewController.leaderboardIdentifier = leaderBoardID
        presentViewController(gameCenterViewController, animated: true, completion: nil)
    }
    
    func reportAllAchievements(achievements:Dictionary<String, Double>) {
        var myAchievements = [GKAchievement]()
        for (identifier, percent) in achievements {
            let achievement = GKAchievement(identifier: identifier)
            achievement.percentComplete = percent
            println("Reporting achievement \(identifier) for \(percent)")
            myAchievements.append(achievement)
        }
        GKAchievement.reportAchievements(myAchievements, withCompletionHandler: { (error) -> Void in
            println("Completed Sending Achievements with Error: \(error)")
        })

    }
    
    // MARK: - GKGameCenterDelegate
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        println("Game Center View Controller Did Finish")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK:- Textfield Delegate
    
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