//
//  main.swift
//  TicTacToe
//
//  Created by Mudita on 2016/12/30.
//  Copyright © 2016 Mudita. All rights reserved.
//

import Foundation

print("Hello!")

let start = Date()

let p1 = PlayerBM(turn: PLAYER_X)
p1.epsilon = 0.01

let p2   = PlayerRandom(turn: PLAYER_O)

// Deep Learning 対 ランダム、100000回戦
let game = GameOrganizer(x: p1, o: p2, games_to_play: 100000, showBoard: false, showResult: false, stat: 1000)
game.progress()
// 学習結果を保存したい場合
//p1.save(to:"/Users/xxxx/Documents/tictactoe.save")

// 学習結果を使いたい場合
//p1.load(from:"/Users/xxxx/Documents/tictactoe.save")
//p1.epsilon = 0

let elapsed = Date().timeIntervalSince(start as Date)
print("learning finished:", elapsed)

// 人間と対戦してみる
// 遊び方: 自分の番では1~9の数字を入力
let p3   = PlayerHuman(turn: PLAYER_O)
let game2 = GameOrganizer(x: p1, o: p3, games_to_play: 1, showBoard: true, showResult: true, stat: 1)
game2.progress()
