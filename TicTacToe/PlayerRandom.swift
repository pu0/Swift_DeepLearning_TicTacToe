//
//  PlayerHuman.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation

class PlayerRandom : Player {
    internal func moveFinished(state: GameState) {
    }


    var _name:String
    var name:String {
        set(value) { _name = value }
        get { return _name}
    }
    
    var _turn:Int
    var turn:Int {
        set(value) { _turn = value}
        get { return _turn }
    }
    
    init(turn:Int, name:String = "random") {
        _turn = turn
        _name = name
    }
    
    func act(state: GameState) -> Int {
        
        let moves = state.possible_pos(player:self.turn)
        if moves.count == 0 {
            //合法手なし = パス
            return -1
        }

        
        // see only next winnable act
        for move in moves {
            let temp_state = state.temp_board(pos: move, player: self.turn)
            //win?
            if state.check_winner(board: temp_state) == self.turn {
                return move
            }
        }
 

        // 勝てる手はないのでランダムです
        let i:Int = Int(arc4random()) % moves.count
        return moves[i]
    }
    
    func gameFinished(state: GameState) {
        // do nothing
    }
}





