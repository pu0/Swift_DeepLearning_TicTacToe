//
//  Board.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation


protocol GameState: class {
    
    var board:Array<Int> { get set }
    var winner : Int { get set }
    var turn   : Int { get set }
    
    init()

    init(board:Array<Int>)
    
    // 可能な手を取得
    func possible_pos(player:Int) -> Array<Int>
    // 表示
    func print_board()

    func check_winner(board:Array<Int>) -> Int
    func result() -> Int
    
    func move(pos:Int, player:Int)

    // 複製
    func copy() -> GameState
    // 石を足した盤を返す
    func temp_board(pos:Int, player:Int) -> Array<Int>
    
    func switch_turn()
}


