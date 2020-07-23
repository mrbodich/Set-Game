//
//  Card.swift
//  Set Game
//
//  Created by Bogdan Chernobrivec on 25.06.2018.
//  Copyright © 2018 Bogdan Chornobryvets. All rights reserved.
//

import Foundation
import UIKit

struct Card: Equatable, Hashable, CustomStringConvertible {
    var description: String {
        return String("\(id) \(isSelected)")
    }
    
    enum CardColor: CaseIterable { case red, green, purple }
    enum CardShape: CaseIterable { case oval, diamond, squiggle }
    enum CardShading: CaseIterable { case solid, empty, striped }
    enum CardShapeCount: Int, CaseIterable { case one = 1, two = 2, three = 3 }
    
    let color: CardColor
    let shape: CardShape
    let shading: CardShading
    let shapeCount: CardShapeCount
    let id: Int
//    var hashValue: Int { return id }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var isSelected: Bool = false
    static var lastUniqueID = 0
    
    init?() {
        let cases = 3
        if Card.lastUniqueID >= Int(pow(Double(cases), 4)) {
            Card.lastUniqueID = 0
            return nil
        }
        func getBit(_ value: Int, bitFloor: Int, floor: Int) -> Int {
            return value / Int(pow(Double(floor), Double(bitFloor)) ) % floor
        }
        
        //Getting bits in ID converted to ternary number system
        id = Card.lastUniqueID
        color = CardColor.allCases[getBit(id, bitFloor: 0, floor: cases)]
        shape = CardShape.allCases[getBit(id, bitFloor: 1, floor: cases)]
        shading = CardShading.allCases[getBit(id, bitFloor: 2, floor: cases)]
        shapeCount = CardShapeCount.allCases[getBit(id, bitFloor: 3, floor: cases)]
        Card.lastUniqueID += 1
        
    }
    
    mutating func touch() {
        isSelected = !isSelected
    }
    
    static func ==(lhs: Card, rhs: Card) -> Bool {
        var isEqual = lhs.color == rhs.color
        isEqual = (lhs.shading == rhs.shading) && isEqual
        isEqual = (lhs.shape == rhs.shape) && isEqual
        isEqual = (lhs.shapeCount == rhs.shapeCount) && isEqual
        return isEqual
    }
    
    static func isSet(cards: [Card]) -> Bool {
        var matched = Array<Bool>()
        matched.append(cards.map { $0.color }.isMatchForSet())
        matched.append(cards.map { $0.shape }.isMatchForSet())
        matched.append(cards.map { $0.shading }.isMatchForSet())
        matched.append(cards.map { $0.shapeCount }.isMatchForSet())
        return matched.isAllTheSame() && matched.first!
    }
    
    func isSet(with cards: Card...) -> Bool {
        var cards = cards
        cards.append(self)
        return Card.isSet(cards: cards)
    }
}

extension Collection where Element: Equatable {
    func isAllTheSame() -> Bool {
        for index in self.indices {
            if self.startIndex == index { continue }
            if self[index] != self.first {
                return false
            }
        }
        return true
    }
    func isAllDifferent() -> Bool {
        for firstIndex in self.indices {
            for index in self.indices where index > firstIndex{
                if self[firstIndex] == self[index] { return false }
            }
        }
        return true
    }
    func isMatchForSet() -> Bool {
        return isAllDifferent() || isAllTheSame()
    }
}


/*extension Collection where Element: Equatable {
    func isAllTheSame() -> Bool {
        return self.filter { $0 == first! }.count == count
    }
    func isAllDifferent() -> Bool {
        var sameFound = false
        for firstIndex in self.indices {
            for index in self.indices where index > firstIndex && !sameFound {
                sameFound = sameFound || (self[firstIndex] == self[index])
            }
        }
        return !sameFound
    }
    func isMatchForSet() -> Bool {
        return isAllDifferent() || isAllTheSame()
    }
}*/


extension Array where Element == Card {
    mutating func unSelectAll() {
        for index in self.indices {
            self[index].isSelected = false
        }
    }
}

