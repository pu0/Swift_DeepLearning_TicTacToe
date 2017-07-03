//
//  GameOrganizer.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation



class GameOrganizer {

    //act_turn=0
    //winner=None
    
    var player_x : Player
    var player_o : Player
    var turn : Int
    var turn_player : Player { get{
        return turn == 1 ? player_x : player_o
    } }
    
    var nwon : Dictionary<Int, Int>
    var games_to_play : Int
    var games_played  : Int = 0

    var state : GameState!
    var showBoard, showResult : Bool
    var passed = false


    var stat : Int
    
    init(x:Player, o:Player,
         games_to_play:Int=1, showBoard:Bool=true, showResult:Bool=true, stat:Int=100) {
        
        player_x = x
        player_o = o
        turn = Int(arc4random() % 2) == 0 ? PLAYER_X : PLAYER_O
        
        self.nwon = [
            PLAYER_X:0,
            PLAYER_O:0,
            DRAW:0
        ]
        
        self.games_to_play = games_to_play
        self.games_played = 0
        
        self.showBoard = showBoard
        self.showResult = showResult

        self.stat=stat
    }
    
    
    func progress() {
        
        while games_played < games_to_play {
            
            state = TTTGameState()
            
            turn = Int(arc4random() % 2) == 0 ? PLAYER_X : PLAYER_O
            state.turn = turn

            // 勝者が出るまで続ける
            while state.winner == EMPTY {
                if self.showBoard { print(turn_player.name+"'s turn") }
                
                // 手を決めて
                let act = turn_player.act(state: state)
                // passでなければ
                if act != -1 {
                    passed = false
                    // 書き込む
                    state.move(pos: act, player: turn)
                    if self.showBoard { state.print_board() }
                } else {
                    if passed == true {
                        // 連続パス、試合終了
                        state.winner = DRAW
                        break
                    } else {
                        passed = true
                    }
                }
                
                // ゲーム続行
                if state.winner == EMPTY {
                    switch_player()
                    state.switch_turn()
                    turn_player.moveFinished(state:state)
                }
            }
            
            player_x.gameFinished(state:state)
            player_o.gameFinished(state:state)
            
            switch state.winner {
            case DRAW:
                if self.showResult { print ("Draw Game") }
            case turn:
                let out = "Winner : " + turn_player.name
                if self.showResult { print(out) }
            case -turn:
                //打った人が負けるのは、反則の場合である(五目の場合)
//                if self.showResult { print (turn_player.name + ":Invalid Move!") }
//                break
                let out = "Winner : " + turn_player.name
                if self.showResult { print(out) }
            default:
                break
            }
            
            // ゲーム終了
            self.nwon[state.winner] = self.nwon[state.winner]! + 1
            games_played += 1
            
            if games_played % stat==0 || games_played == games_to_play {
                let message1 = "\(player_x.name):\(nwon[player_x.turn]!),"
                let message2 = "\(player_o.name):\(nwon[player_o.turn]!),"
                let message3 = "DRAW:\(nwon[DRAW]!)"
                print (message1 + message2 + message3)
            }
        }
    }
    

    func switch_player() {
        turn = -turn
    }

}




