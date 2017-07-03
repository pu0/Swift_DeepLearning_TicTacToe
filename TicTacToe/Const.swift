//
//  Const.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation

let EMPTY=0
let PLAYER_X = 1
let PLAYER_O = -1
let MARKS = [
    PLAYER_X : "X",
    PLAYER_O:"O",
    EMPTY:" "
]
let DRAW=2


protocol Player {
    var turn:Int { get set }
    var name:String { get set }
    
    func act(state:GameState) -> Int

    func moveFinished(state:GameState)
    func gameFinished(state:GameState)
}


infix operator ^^
func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

struct Two: Hashable {
    let board : Array<Int>
    let move : Int
    
    var hashValue : Int {
        get {
            var hash = 0
            for i in 0...8 {
                let k:Int = 3 ^^ i
                hash = hash + board[i] * (k + 1)
            }
            hash += move * (3 ^^ 9)

            return hash
        }
    }
}

// comparison function for conforming to Equatable protocol
func == (lhs: Two, rhs: Two) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


struct One: Hashable {
    let board : Array<Int>
    
    var hashValue : Int {
        get {
            var hash = 0
            for i in 0...8 {
                let k:Int = 3 ^^ i
                hash = hash + board[i] * (k + 1)
            }
            
            return hash
        }
    }
}

// comparison function for conforming to Equatable protocol
func == (lhs: One, rhs: One) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


enum Direction {
    case left,right,up,down,
        upper_left,upper_right,lower_left,lower_right,
        none
    
    static var eight:Array<Direction> { get {
        return [.left, .right, .up, .down,
                .upper_left, .upper_right, .lower_left, .lower_right]
    }}
    
    var x:Int {get {
        switch(self) {
            case .up:
                return 0
            case .down:
                return 0
            case .left:
                return -1
            case .right:
                return 1
            case .upper_left:
                return -1
            case .upper_right:
                return 1
            case .lower_left:
                return -1
            case .lower_right:
                return 1
            case .none:
                return 0
        }
    }}
    
    var y:Int {get {
        switch(self) {
        case .up:
            return -1
        case .down:
            return 1
        case .left:
            return 0
        case .right:
            return 0
        case .upper_left:
            return -1
        case .upper_right:
            return -1
        case .lower_left:
            return 1
        case .lower_right:
            return 1
        case .none:
            return 0
        }
    }}
}
