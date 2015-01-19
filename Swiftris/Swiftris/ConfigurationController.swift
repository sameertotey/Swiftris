//
//  ConfigurationController.swift
//  Swiftris
//
//  Created by Sameer Totey on 1/18/15.
//  Copyright (c) 2015 Sameer Totey. All rights reserved.
//

import UIKit

class ConfigurationController: UIViewController, UITextFieldDelegate, GameViewControllerDelegate {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var gameModeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var timeLengthTextField: UITextField!
    @IBOutlet weak var leaderBoardButton: UIButton!
    
    var gameViewController: GameViewController?
    var gameMode = GameMode.classic
    var maxTime = 60.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func gameModeChanged(sender: UISegmentedControl) {
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
        
    }
    
    func gameDidEnd(#score: Int?, level: Int?) {
        println("Scored \(score) at level \(level)")
    }
    
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