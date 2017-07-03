//
//  PlayerHuman.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation

class PlayerHuman : Player {
    internal func moveFinished(state: GameState) {
    }


    var name:String {
        set {}
        get { return "human"}
    }
    
    var _turn:Int
    var turn:Int {
        set(value) { _turn = value}
        get { return _turn }
    }
    
    init(turn:Int) {
        _turn = turn
    }
    
    func act(state: GameState) -> Int {
        
        while true {
            print ("Please input:")
            let move = Int(readLine(strippingNewline: true)!)! - 1

            if state.possible_pos(player:self.turn).contains(move) {
                return move
            } else {
                print ("That is not a valid move! Please try again.")
            }
        }
    }
    
    func gameFinished(state: GameState) {
        if state.winner != DRAW && state.winner != turn {
            print("You lost...")
        }
    }
}
