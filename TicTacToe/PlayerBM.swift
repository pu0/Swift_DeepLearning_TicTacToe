//
//  PlayerBM.swift
//  TicTacToe
//
//  Created by Mudita on 2017/02/09.
//  Copyright © 2017 Mudita. All rights reserved.
//

import Foundation

class PlayerBM : Player {
    
    let step_size:Float = 0.1
    
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
    
    var epsilon = 0.0
    var previous_after_state:Array<Int>? = nil
    
//    func doubleBoard(_ board:[Int]) -> [Double] {
//        var array:[Double] = []
//        for i in board {
//            array.append(Double(i))
//        }
//        return array
//    }

    func floatBoard(_ board:[Int]) -> [Float] {
        return board.map({ s in
            Float(s)
        })
    }
    
    var blueMagic:BlueMagic = try! BlueMagic(layerSizes: [9,48,1], learningRate:0.9)
    fileprivate let networkQueue = DispatchQueue(label: "BlueMagic.networkQueue", attributes: [])
    
    func get_value(board:Array<Int>) -> Float {
        return self.blueMagic.predict(input: floatBoard(board))[0]
    }
    
    init(turn:Int, name:String = "BlueMagic") {
        _turn = turn
        _name = name
//        self.blueMagic = try! BlueMagic(layerSizes: [9,18,1])
    }
    
    
    func get_max_action(state:GameState) -> Int {
        
        let moves = state.possible_pos(player:self.turn)
        if moves.count == 0 {
            //合法手なし = パス
            return -1
        }
        
        var points:Array<(Int, Float)>! = nil

        // 手のポイントの最高値を得る
        points = moves.map({ move in
            let temp_board = state.temp_board(pos: move, player: self.turn)
            
            let point = get_value(board:temp_board)
            return (move, point)
        })

        let max_point = points.max(by: { pair0, pair1 in
            return pair0.1 < pair1.1}
        )!
        return max_point.0
    }
    
    func act(state: GameState) -> Int {
        
        let selected_action:Int
        let random = Double(arc4random() % 10000) / 10000
        if random < epsilon {
            // ランダムな手を試行
            let moves = state.possible_pos(player:self.turn)
            if moves.count == 0 {
                //合法手なし = パス
                return -1
            }
            let i:Int = Int(arc4random()) % moves.count
            selected_action = moves[i]
            
        } else {
            selected_action = get_max_action(state:state)
            if selected_action == -1 {
                //合法手なし = パス
                return -1
            }
        }
        
        // 事後状態が確定するので、このタイミングで学習を行う
        let after_board = state.temp_board(pos: selected_action, player: self.turn)
        
        if let previous_after_state = self.previous_after_state {
            learn(state: previous_after_state,reward:0, next_state: after_board)
        }
        
        previous_after_state = after_board
        
        return selected_action
    }
    
    
    internal func moveFinished(state: GameState) {
    }
    
    func gameFinished(state: GameState) {
        if state.turn == self.turn {
            if state.winner == self.turn {
                self.learn(state: state.board, reward: 1, next_state: nil)
            } else if state.winner == DRAW {
                self.learn(state: state.board, reward: 0.5, next_state: nil)
            } else {
                self.learn(state: state.board, reward: 0, next_state: nil)
            }
        } else {
            if state.winner == self.turn {
                self.learn(state: previous_after_state!, reward: 1, next_state: nil)
            } else if state.winner == DRAW {
                self.learn(state: previous_after_state!, reward: 0.7, next_state: nil)
            } else {
                self.learn(state: previous_after_state!, reward: 0, next_state: nil)
            }
        }
        
        previous_after_state = nil
    }
    
    
    func save(to:String){
        let dataURL = URL(fileURLWithPath: to)
        self.blueMagic.write(dataURL)
    }
    
    func load(from:String){
        let dataURL = URL(fileURLWithPath: from)
        self.blueMagic = try! BlueMagic.read(dataURL)
    }
    
    //
    //# 事後状態stateに対する価値を更新する
    //# 終端状態で行動することが出来ない場合、
    //# 次の事後状態next_stateとしてnilを指定すること
    func learn(state:Array<Int>, reward:Float, next_state:Array<Int>?) {

        let current_state_value:Float = self.get_value(board: state)
        
        let next_state_value:Float
        if next_state == nil {
            next_state_value = 0.0
        } else {
            next_state_value = self.get_value(board: next_state!)
        }
        
        let value:Float = current_state_value
            + self.step_size * (reward + next_state_value - current_state_value)
        
        self.blueMagic.train(input: self.floatBoard(state), answer: [value])

    }

    
}


