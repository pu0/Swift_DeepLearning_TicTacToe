//
//  Board.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation


class TTTGameState : GameState {
    
    var board:Array<Int> = []
    var winner = EMPTY
    var turn = EMPTY

    required init() {
        for _ in 0...8 {
            board.append(EMPTY)
        }
    }

    required init(board:Array<Int>) {
        self.board = board
    }
    
    // 可能な手を取得
    func possible_pos(player:Int) -> Array<Int> {
        var poss:Array<Int> = []
        
        for (index, value) in board.enumerated() {
            if value == EMPTY {
                poss.append(index)
            }
        }
        
        return poss
    }
    
    func print_board() {
        print(" {\(MARKS[board[0]]!)} | {\(MARKS[board[1]]!)} | {\(MARKS[board[2]]!)} ")
        print("-----------")
        print(" {\(MARKS[board[3]]!)} | {\(MARKS[board[4]]!)} | {\(MARKS[board[5]]!)} ")
        print("-----------")
        print(" {\(MARKS[board[6]]!)} | {\(MARKS[board[7]]!)} | {\(MARKS[board[8]]!)} ")
        print("-----------")
    }
    
    let lines = [(0,1,2),(3,4,5),(6,7,8),(1,4,7),(2,5,8),(0,3,6),(0,4,8),(2,4,6)]

    func check_winner(board:Array<Int>) -> Int {
        
        for line in lines {
            if board[line.0] != EMPTY && board[line.0] == board[line.1] && board[line.0] == board[line.2] {
                return board[line.0]
            }
        }
        
        //勝者なし
        if board.filter({ cell in
            cell == EMPTY
        }).count == 0 {
            // 置く場所ないので引き分け
            return DRAW
        }
        return EMPTY
    }
    
    
    func result() -> Int {
        return check_winner(board: self.board)
    }
    
    
    func move(pos:Int, player:Int) {
        if board[pos] == EMPTY {
            board[pos] = player
            winner = result()
        } else {
            // もう石があるので反則
            winner = -player
        }
    }

    // おそいので注意
    func copy() -> GameState {
        // 配列はこれでコピーされるんだって
        let newBoard = board
        return TTTGameState(board: newBoard)
    }
    
    
    // 石を足した盤を返す
    func temp_board(pos:Int, player:Int) -> Array<Int> {
        // 複製
        var t_board = board
        t_board[pos] = player
        return t_board
    }
    
    
    func switch_turn(){
        turn = -turn
    }
}


