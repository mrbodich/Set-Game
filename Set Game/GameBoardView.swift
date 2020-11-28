//
//  GameBoardView.swift
//  Set Game
//
//  Created by bodich on 27.07.2018.
//  Copyright © 2018 bodich. All rights reserved.
//

import UIKit
//import QuartzCore

class GameBoardView: UIView
{
    var cards: [(id: Int, card: CardView)] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    lazy var animator = UIDynamicAnimator(referenceView: self)
    
    lazy var collisionBehavior: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(behavior)
        return behavior
    }()
    
    @objc var dealMoreCardsFunc: (_ sender: UIView) -> Void = {sender in}
    @objc func dealMoreCards(_ sender: UIView) {
        dealMoreCardsFunc(sender)
    }
    
    lazy var itemBehavior: UIDynamicItemBehavior = {
       var behavior = UIDynamicItemBehavior()
        behavior.allowsRotation = false
        behavior.elasticity = 1.0
        behavior.resistance = 0.0
        animator.addBehavior(behavior)
        return behavior
    }()
    
    var isDeckEmpty: Bool = false
    var isOutEmpty: Bool = true
    var lastCardFlewFromDeck: Bool = false
    var deckCard: CardView? {
        didSet {
            if let card = deckCard, card.gestureRecognizers == nil {
                let tap = UITapGestureRecognizer(target: self, action: #selector(dealMoreCards(_:)))
                card.addGestureRecognizer(tap)
            }
        }
    }
    var outCard: CardView?
    var grid = Grid(layout: Grid.Layout.aspectRatio(3/4), frame: CGRect.zero)
    var lastDealedCardDate = RegularDelay()
    var lastCardOutDate = RegularDelay()
    
    
    private func initDeckCard( card: inout CardView?, cardExists: Bool, targetFrame: CGRect ) {
        if cardExists && card == nil {
            card = CardView()
            card?.contentMode = UIView.ContentMode.redraw
            self.addSubview(card!)
            self.insertSubview(card!, at: 0)
            card?.frame = targetFrame
        }
        card?.animate(to: targetFrame)
    }
    
    let notOnDeck: [CardView.CardViewState] = [.flyingOut, .out]
    
    override func draw(_ rect: CGRect) {
        let cardsLeftCount = cards.filter { /*$0.card.state != .flyingOut && $0.card.state != .out*/ !notOnDeck.contains($0.card.state) }.count
        grid.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        grid.cellCount = cardsLeftCount + 2
        while grid.dimensions.columnCount * (grid.dimensions.rowCount - 1) < cardsLeftCount {
            grid.cellCount += 1
        }
        grid.cellCount = grid.dimensions.columnCount * grid.dimensions.rowCount
        grid.margin = 0.05
        
        let deckCardFrame = grid[grid.cellCount - grid.dimensions.columnCount] ?? CGRect.zero
        let outCardFrame = grid[grid.cellCount - 1] ?? CGRect.zero
        initDeckCard(card: &deckCard, cardExists: !isDeckEmpty, targetFrame: deckCardFrame)
        initDeckCard(card: &outCard, cardExists: true, targetFrame: outCardFrame)
        outCard?.alpha = isOutEmpty ? 0.0 : 1.0
        
        var gridIndex = 0
        for index in 0..<cards.count {
            let cardView = cards[index].card
            let targetFrame = grid[gridIndex] ?? CGRect.zero
            let outFrame: CGRect = outCard?.frame ?? CGRect.zero
            let removeCardView: () -> Void = { [weak cardView, unowned self] in
                self.isOutEmpty = false
                cardView?.removeFromSuperview()
                for index in stride(from: self.cards.count - 1, through: 0, by: -1) where self.cards[index].card.state == .out {
                    self.cards.remove(at: index)
                }
            }
            switch cardView.state {
            case .inDeck:
                cardView.state = .goingToFly
                Timer.scheduledTimer(withTimeInterval: lastDealedCardDate.next(withDelay: 0.1).delay, repeats: false) { [unowned self] (timer) in
                    cardView.alpha = 1.0
                    cardView.state = .flying
                    if self.isDeckEmpty && ( self.cards.filter { $0.card.state == .goingToFly }.count == 0 ) {
                        self.deckCard?.removeFromSuperview()
                        self.deckCard = nil
                        self.setNeedsDisplay()
                    }
                    cardView.frame = self.deckCard?.layer.presentation()?.frame ?? self.deckCard?.frame ?? self.grid[self.grid.cellCount - self.grid.dimensions.columnCount] ?? CGRect.zero
                    cardView.isReadyToFlip = true
                    var updatedIndex = gridIndex
                    let cardsLeft = self.cards.filter { /*$0.card.state != .flyingOut && $0.card.state != .out*/ !self.notOnDeck.contains($0.card.state) }
                    for index in 0..<cardsLeft.count {
                        if cardsLeft[index].id == cardView.cardId { updatedIndex = index }
                    }
                    cardView.animate(to: self.grid[updatedIndex] ?? CGRect.zero)
                }
            case  .flying:
                cardView.isReadyToFlip = true
                cardView.animate(to: targetFrame)
            case .flyingOut:
                cardView.isReadyToFlip = true
                cardView.animate(to: outFrame, afterFlipCompletion: removeCardView)
            case .goingToFly, .goingToFlyOut:
                break
            case .onTable where cardView.destination != .out:
                cardView.animate(to: targetFrame)
            case .onTable where cardView.destination == .out:
                cardView.state = .goingToFlyOut
                insertSubview(cardView, at: subviews.count - 1)
                Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { [unowned self] (timer) in self.setNeedsDisplay() }
                cardView.animateBeforeOut { [unowned self] in
                    cardView.isReadyToFlip = false
//                    cardView.animate(to: targetFrame, allowFlip: false)
                    if cardView.timerAdded == false {
                        Timer.scheduledTimer(withTimeInterval: self.lastCardOutDate.next(withDelay: 0.1).delay, repeats: false) { [unowned self, weak cardView] (timer) in
                            if let cardView = cardView {
                                cardView.state = .flyingOut
                                cardView.isReadyToFlip = true
                                self.insertSubview(cardView, at: self.subviews.count - 1)
                                self.setNeedsDisplay()
                                cardView.animate(to: outFrame, afterFlipCompletion: removeCardView)
                            }
                        }
                        cardView.timerAdded = true
                    }
                }
                
            case .out:
                cardView.animate(to: outFrame)
            default:
                break
            }
            
            switch cardView.state {
            case let state where notOnDeck.contains(state):
                break
            default:
                gridIndex += 1
            }
        }
        
        func animateCard(to target: CGRect) {
            
        }
    }
    
    func removeCard(_ card: Card) {
        for index in stride(from: cards.count - 1, through: 0, by: -1) {
            if cards[index].id == card.id {
                cards[index].card.destination = .out
                setNeedsDisplay()
            }
        }
    }
    
    subscript(cardById id: Int) -> CardView? {
        return cards.first(where: { $0.id == id })?.card
    }
    
    subscript(cardIndexById id: Int) -> Int {
        let validCards = cards.filter { $0.card.destination != .out }
        for index in 0..<validCards.count {
            if validCards[index].id == id { return index }
        }
        return 0
    }
    
    func addCardToTheDeck(card: Card) -> CardView? {
        if let _ = cards.first(where: { $0.card.cardId == card.id }) { return nil }
        let cardView = CardView(shape: card.shape, shapesCount: card.shapeCount, color: card.color, shading: card.shading, id: card.id)
        cards.append((id: card.id, card: cardView))
        cardView.contentMode = UIView.ContentMode.redraw
        self.addSubview(cardView)
        let cardsFlyingOnTable = cards.filter { $0.card.destination == .onTable }
        if cardsFlyingOnTable.count != 0 {
            self.insertSubview(cardView, belowSubview: cardsFlyingOnTable.last!.card)
        }
        cardView.alpha = 0.0
        cardView.destination = .onTable
        return cardView
    }

    func shuffleCards() {
        cards.randomize()
    }
}

struct RegularDelay {
    private var lastDate: Date!
    
    mutating func next(withDelay delay: Double) -> (delay: TimeInterval, date: Date) {
        if lastDate != nil {
            lastDate = -lastDate.timeIntervalSinceNow > delay ? Date() : lastDate + delay
        } else {
            lastDate = Date()
        }
        return (lastDate.timeIntervalSinceNow, lastDate)
    }
}

