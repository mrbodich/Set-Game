//
//  TheSetGame.swift
//  Set Game
//
//  Created by Bogdan Chernobrivec on 25.06.2018.
//  Copyright © 2018 Bogdan Chornobryvets. All rights reserved.
//

import Foundation
import UIKit

class TheSetGame {
    var cardsInDeck: [Card]
    var cardsOnTable = [Card]()
    var cardsOut = [Card]()
    var selectedCards: [Card] {
        get {
            return cardsOnTable.filter { $0.isSelected }
        }
    }
    
    var foundSets = [[Int]]()
    var currectCalculating = 0
    
    private func getPossibleSets() {
        possibleSets = nil;
        currectCalculating += 1
        DispatchQueue.global(qos: .background).async { [unowned self, currectCalculating] in
            self.foundSets = [[Int]]()
            var sets = 0
            mainLoop: for index1 in 0..<self.cardsOnTable.count {
                for index2 in (index1 + 1)..<self.cardsOnTable.count where self.cardsOnTable.count > index1 {
                    for index3 in (index2 + 1)..<self.cardsOnTable.count where self.cardsOnTable.count > index2 {
                        if self.currectCalculating != currectCalculating { return }
                        if Card.isSet(cards: [self.cardsOnTable[index1],
                                              self.cardsOnTable[index2],
                                              self.cardsOnTable[index3]]) {
                            sets += 1
                            if(sets < 10){
                                self.foundSets.append([self.cardsOnTable[index1].id, self.cardsOnTable[index2].id, self.cardsOnTable[index3].id])
                            }
                        }
                    }
                }
            }
            self.possibleSets = sets
        }
    }
    var possibleSets: Int? {
        didSet {
            if possibleSets != nil && whenPossibleSetsCalculated != nil {
                whenPossibleSetsCalculated?();
                whenPossibleSetsCalculated = nil;
            }
        }
    }
    public var whenPossibleSetsCalculated: (() -> Void)?;
    
    init() {
        cardsInDeck = [Card]()
        while let card = Card() {
            cardsInDeck.append(card)
        }
        cardsInDeck.randomize()
        for _ in 0..<12 {
            cardsOnTable.append(cardsInDeck[0])
            cardsInDeck.remove(at: 0)
        }
        getPossibleSets()
    }
    
    subscript(cardById: Int) -> Card? {
        return cardsOnTable.first(where: { $0.id == cardById })
    }
    
    func touchCard(cardId: Int) {
        for index in 0..<cardsOnTable.count {
            if cardsOnTable[index].id == cardId {
                touchCard(index: index)
                return
            }
        }
    }
    
    func touchCard(index: Int) {
        cardsOnTable[index].touch()
        if selectedCards.count >= 3 {
            if Card.isSet(cards: selectedCards) {
                cardsOut.append(contentsOf: selectedCards)
                cardsOnTable = cardsOnTable.filter { !$0.isSelected }
//                dealMoreCards()
                getPossibleSets()
            }
            cardsOnTable.unSelectAll()
        }
    }
    
    func dealMoreCards() {
        if cardsInDeck.count >= 3 {
            if cardsInDeck.count >= 3 {
                cardsOnTable.append(contentsOf: cardsInDeck[0..<3])
                cardsInDeck.removeSubrange(0..<3)
            }
            getPossibleSets()
//            print("\(cardsInDeck.count) cards left in deck")
        }
    }
}


/*public protocol EnumCollection: Hashable {
    static func cases() -> AnySequence<Self>
    static var allValues: [Self] { get }
}

public extension EnumCollection {
    public static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else {
                    return nil
                }
                raw += 1
                return current
            }
        }
    }
    
    public static var allValues: [Self] {
        return Array(self.cases())
    }
}*/

public extension Int {
    var arc4random: Int {
        if self > 0 {
            return Int(arc4random_uniform(UInt32(self)))
        } else if self < 0 {
            return -Int(arc4random_uniform(UInt32(-self)))
        }else {
            return 0
        }
    }
}

extension CGFloat {
    var arc4random: CGFloat {
        let digits = 1000000000
        return ( 1.0 / CGFloat(digits) * CGFloat(arc4random_uniform(UInt32(digits))) ) * self
    }
}

public extension Array {
    var oneAndOnly: Element? {
        return count == 1 ? first : nil
    }
    
    mutating func randomize() {
        var oldCards = self
        var newCards = [Element]()
        for _ in 0..<oldCards.count {
            let randomIndex = oldCards.count.arc4random
            newCards.append(oldCards[randomIndex])
            oldCards.remove(at: randomIndex)
        }
        self = newCards
    }
}




