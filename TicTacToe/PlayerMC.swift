//
//  PlayerHuman.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation

class PlayerMC : Player {
    internal func moveFinished(state: GameState) {
    }

    
    let tryal = 10
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
    
    init(turn:Int, name:String = "MC") {
        _turn = turn
        _name = name
    }
    
    func act(state: GameState) -> Int {
        
        let moves = state.possible_pos(player:self.turn)

        var scores:Dictionary<Int, Int> = [:]

        // 考えられる手全てについて
        for move in moves {
            // 50回ずつランダムで最後まで対戦してみる
            var score = 0
            for _ in 1 ... tryal {
                score += mctry(state: state, move: move)
            }
            scores[move] = (scores[move] ?? 0) + score
//            scores[act]/=n
        }

        let max = scores.max(by: {
            pair1, pair2 in
            pair1.value < pair2.value
        })

        return max!.key
    }
    
    // 検証用ランダム手生成
    func random(state: GameState, turn: Int) -> Int {
        
        let moves = state.possible_pos(player:turn)
        if moves.count == 0 {
            //合法手なし = パス
            return -1
        }
        
        // see only next winnable act
        for move in moves {
            // 動かしてみる
            let tempboard = state.temp_board(pos: move, player: turn)
            //win?
            if state.check_winner(board: tempboard) == self.turn {
                return move
            }
        }
        
        // 勝てる手はないのでランダムです
        let i:Int = Int(arc4random()) % moves.count
        return moves[i]
    }
    
    // この手を指してからランダムに最後までやって勝つかどうか
    func mctry(state: GameState, move:Int) -> Int {
        // 検証用環境
        let temp_state = state.copy()
        // 動かしてみる
        temp_state.move(pos: move, player: self.turn)
        // 検証用ターン
        var temp_turn = self.turn
        // 先に向かってランダムな手を繰り返す
        while temp_state.winner == EMPTY {
            temp_turn = temp_turn * -1
            let move = self.random(state: temp_state, turn:temp_turn)
            temp_state.move(pos: move,player: temp_turn)
        }
        
        if temp_state.winner == self.turn {
            return 1
        } else if temp_state.winner==DRAW {
            return 0
        } else {
            return -1
        }
    }
    
    func gameFinished(state: GameState) {
        // do nothing
    }
}






