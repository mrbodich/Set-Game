//
//  ViewController.swift
//  Set Game
//
//  Created by bodich on 25.06.2018.
//  Copyright © 2018 bodich. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import MapKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    private lazy var game = TheSetGame()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultButtonsStyles()
        updateViewController()
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.touchMyCard))
//        //            tap.delegate = gameBoardView
//        self.addGestureRecognizer(tap)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func dealMoreCards(_ sender: UIView) {
        if game.cardsInDeck.count != 0 {
            game.dealMoreCards()
            updateViewController()
        }
    }
    
    /*@objc func shuffleCardsOnScreen(sender: UIRotationGestureRecognizer) {
        if sender.state == .ended {
            gameBoardView.shuffleCards()
            printFoundSetsInConsole()
        }
    }*/
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            gameBoardView.shuffleCards()
            printFoundSets()
        }
    }
    
    @IBOutlet weak var gameBoardView: GameBoardView! {
        didSet {
            gameBoardView.dealMoreCardsFunc = dealMoreCards(_:)
            /*let gameBoardSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dealMoreCards(_:)))
            gameBoardSwipe.direction = .down
            gameBoardView.addGestureRecognizer(gameBoardSwipe)*/
            
//            let gameBoardRotate = UIRotationGestureRecognizer(target: self, action: #selector(shuffleCardsOnScreen(sender:)))
//            gameBoardView.addGestureRecognizer(gameBoardRotate)
        }
    }
    
    @IBOutlet private  var CardButtons: [UIButton]!
    
    @IBOutlet private weak var setsFoundLabel: UILabel!
    @IBOutlet private weak var DealMoreCardsButton: UIButton!
    
    @objc func touchDownCard(sender: TouchDownGestureRecognizer) {
        if sender.state == .began {
            sender.parentView = sender.view as? CardView
            if let view = sender.parentView as? CardView {
                sender.wasSelected = view.isSelected
                view.isSelected = !sender.wasSelected
                sender.state = .changed
            }
        }
        else if let view = sender.parentView as? CardView {
            if sender.state == .changed {
                if !sender.outOfRange {
                    view.isSelected = !sender.wasSelected
                }
                else {
                    view.isSelected = sender.wasSelected
                }
            }
            else if sender.state == .recognized {
                view.isSelected = sender.wasSelected
                game.touchCard(cardId: view.cardId)
                updateViewController()
            }
            else {
                view.isSelected = sender.wasSelected
            }
        }
    }
    
    private func updateViewController() {
        let cardsCount = gameBoardView.cards.count
        for card in game.cardsOnTable {
            if let cardView = gameBoardView.addCardToTheDeck(card: card) {
                let touch = TouchDownGestureRecognizer(target: self, action: #selector(touchDownCard(sender:)))
                cardView.addGestureRecognizer(touch)
            }
            gameBoardView[cardById: card.id]?.isSelected = card.isSelected
        }
        for card in game.cardsOut {
            gameBoardView.removeCard(card)
        }
        
        if cardsCount != (gameBoardView.cards.filter{ $0.card.destination != .out }.count) {
            if game.possibleSets != nil {
                printFoundSets()
            }
            else {
                game.whenPossibleSetsCalculated = { [weak game, weak self] in
                    if game?.possibleSets != nil {
                        DispatchQueue.main.async {
                            self?.printFoundSets()
                        }
                    }
                }
                setsFoundLabel.text = "..."
            }
        }
        
        /*if cardsCount != (gameBoardView.cards.filter{ $0.card.destination != .out }.count) {
            printFoundSetsInConsole()
        }*/
        
        if game.cardsInDeck.count == 0 {
            DealMoreCardsButton.isEnabled = false
            DealMoreCardsButton.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            DealMoreCardsButton.setTitle("No more cards", for: .normal)
            gameBoardView.isDeckEmpty = true
        } else {
            DealMoreCardsButton.isEnabled = true
            DealMoreCardsButton.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            DealMoreCardsButton.setTitle("Deal 3 More Cards", for: .normal)
            gameBoardView.isDeckEmpty = false
        }
    }
    
    func printFoundSets() {
        setsFoundLabel.text = "\(String(game.possibleSets ?? 0)) sets"
        //Print found sets in console
        if game.foundSets.count == 0 {
            print("\nNo new sets, deal more cards...")
        }
        else {
            print("\n" + (setsFoundLabel.text ?? ""))
            for set in game.foundSets {
                print([gameBoardView[cardIndexById: set[0]] + 1, gameBoardView[cardIndexById: set[1]] + 1, gameBoardView[cardIndexById: set[2]] + 1].sorted(by: <))
            }
        }
        print("\(game.cardsInDeck.count) cards left in deck")
    }
    
    func setDefaultButtonsStyles() {
        DealMoreCardsButton.layer.cornerRadius = 5
    }
    
}

class TouchDownGestureRecognizer: UIGestureRecognizer
{
    weak var parentView: UIView?
    var wasSelected: Bool = false
    var outOfRange = true
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//        super.touchesBegan(touches, with: event)
        if touches.first?.tapCount != 1 || touches.count != 1 {
            self.state = .cancelled
        }
        else if self.state == .possible {
            self.state = .began
            outOfRange = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let view = parentView, let touch = touches.first {
            if view.frame.contains(touch.location(in: view.superview))  {
                self.state = .changed
                outOfRange = false
            }
            else {
                self.state = .changed
                outOfRange = true
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if (self.state == .began || self.state == .changed) && !outOfRange {
            self.state = .recognized
        }
        else {
            self.state = .cancelled
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        print("cancelled")
    }
    
    
}



