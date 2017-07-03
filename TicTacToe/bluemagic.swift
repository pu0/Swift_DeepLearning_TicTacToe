//
//  t2.swift
//  DeepLearning
//
//  Created by Mudita on 2017/02/05.
//  Copyright © 2017 Mudita. All rights reserved.
//

import Foundation
import Accelerate

enum BMError: Error {
    case InvalidInput(String)
    case IllegalFormat(String)
}

public enum Activatior {
    case ReLU
    case Sigmoid
    case Tanh
    case SoftSign
    
    // 非線形化
    func delinearize(_ x:inout BMM) -> BMM {
        switch self {
        case .ReLU:
            var layerValue:BMM = x
            vvtanhf(&layerValue.cells, x.cells, [Int32(x.cells.count)])
            return layerValue
        //return max(0, x)
        case .Tanh:
            //var layerValue:BMM = x
            vvtanhf(&x.cells, x.cells, [Int32(x.cells.count)])
            return x
        case .Sigmoid:
            //            let ans = calculate(inputData: x.cells)
            //            let layerValue:BMM = BMM(rows: x.rows, cols: x.cols, cells: ans)
            let layerValue:BMM = x.map { s in
                return 1 / (1 + exp(-s))
            }
            return layerValue
        case .SoftSign:
            let layerValue:BMM = x.map { s in
                return s / (1 + abs(s))
            }
            return layerValue
        }
    }
    
    func derivative(_ y: Float) -> Float {
        switch self {
        case .ReLU:
            return (y < 0) ? 0 : 1
        case .Tanh:
            return 1 - (y * y)
        case .Sigmoid:
            return y * (1 - y)
        case .SoftSign:
            return 1 / ((1 + abs(y)) * (1 + abs(y)))
        }
    }
}



public class layer{
    var activator:Activatior = .Tanh
    fileprivate var syn:BMM
    fileprivate var isOut = false
    fileprivate var learningRate:Float
    //キャッシュ用変数
    fileprivate var val:BMM
    //    var loss:BMM //誤差 errorともいう
    fileprivate var delta:BMM
    //キャッシュ用変数2(バッチ用)
    fileprivate var val_batch:BMM!
    fileprivate var delta_batch:BMM!
    
    fileprivate init(_ input:Int, _ output:Int, isOut:Bool) {
        
        var layer:[Float] = []
        
        for _ in 0..<input {
            for _ in 0..<output {
                layer.append(getRandomNumber(Min: -1, Max: 1))
            }
        }
        
        syn = BMM(rows: input, cols: output, cells: layer)
        self.isOut = isOut
        if isOut {
            val = BMM(rows: 1, cols: output, repeats: 1)
        } else {
            val = BMM(rows: 1, cols: output + 1, repeats: 1)
        }
        delta = BMM(rows: 1, cols: output, repeats: 0)
        learningRate = 0.1
    }
    
    fileprivate init(syn:BMM, isOut:Bool){
        let output = syn.cols
        self.syn = syn
        self.isOut = isOut
        if isOut {
            val = BMM(rows: 1, cols: output, repeats: 1)
        } else {
            val = BMM(rows: 1, cols: output + 1, repeats: 1)
        }
        delta = BMM(rows: 1, cols: output, repeats: 0)
        learningRate = 0.1
    }
    
    fileprivate func out(input:BMM) {
        
        cblas_sgemm(
            CblasRowMajor, CblasNoTrans, CblasNoTrans,
            Int32(input.rows), Int32(syn.cols), Int32(input.cols), 1.0,
            input.cells, Int32(input.cols), syn.cells, Int32(syn.cols), 0.0,
            &val.cells, Int32(syn.cols))
        
        switch self.activator {
        case .ReLU:
            val <- val.map { s in
                return max(0, s)
            }
        case .Tanh:
            vvtanhf(&val.cells, val.cells, [Int32(val.cells.count)])
        case .Sigmoid:
            //            let ans = calculate(inputData: x.cells)
            //            let layerValue:BMM = BMM(rows: x.rows, cols: x.cols, cells: ans)
            val <- val.map { s in
                return 1 / (1 + exp(-s))
            }
        case .SoftSign:
            val <- val.map { s in
                return s / (1 + abs(s))
            }
        default: break
        }
//        self.val <- input * syn
        // 後ろの1が残る
//        self.val <- self.activator.delinearize(&self.val)
    }
    
    
    fileprivate func out_g2(input:BMM) {
        var tryal:BMM = input * syn
        if self.isOut {
            self.val_batch = self.activator.delinearize(&tryal)
        } else {
            //後ろの1がないのでたす
            self.val_batch = self.activator.delinearize(&tryal).add_col()
        }
    }
    
//    fileprivate mutating func out_g(input:BMM) {
//        let tryal:BMM = BMM.mul_g(input,syn)
//        if self.isOut {
//            self.val_batch = tryal
//        } else {
//            //後ろの1がないのでたす
//            self.val_batch = tryal.add_col()
//        }
//    }
    
    fileprivate func toDict() -> Dictionary<String, Any> {
        let dictionary = [
            "activator"   : activator,
            "learningRate": learningRate,
            "syn"         : syn.toDict()
            ] as [String : Any]
        
        return dictionary
    }
}

fileprivate func getRandomNumber(Min _Min : Float, Max _Max : Float)->Float {
    return ( Float(arc4random_uniform(UINT32_MAX)) / Float(UINT32_MAX) ) * (_Max - _Min) + _Min
}

public final class BlueMagic {
    
    fileprivate var layers:[layer] = []
    fileprivate var inputLayer:layer {
        get{
            return layers.first!
        }
        set(l){
            layers[0] = l
        }
    }
    
    fileprivate var hiddenLayers:[layer] {
        return Array(layers.dropFirst().dropLast())
    }
    
    fileprivate var outputLayer:layer {
        get{
            return layers.last!
        }
        set(l){
            layers[layers.count - 1] = l
        }
    }
    
    public init(layerSizes:[Int], learningRate:Float) throws {
        
        guard layerSizes.count >= 2 else {
            throw BMError.InvalidInput("BlueMagic needs at least 2 layers.")
        }
        
        self.layers.append(layer(1, layerSizes[0], isOut: false))
        
        for i in 0..<(layerSizes.count - 2) {
            let inputSize = layerSizes[i] + 1
            let outputSize = layerSizes[i + 1]
            self.layers.append(layer(inputSize, outputSize, isOut: false))
        }
        
        let inputSize = layerSizes[layerSizes.count - 2] + 1
        let outputSize = layerSizes[layerSizes.count - 1]
        let outLayer = layer(inputSize, outputSize, isOut: true)
        outLayer.activator = .Tanh
        self.layers.append(outLayer)
    }
    
    // ロード用
    private init() {}
    
    // 予測-------------
    public func predict(input:[Float]) -> [Float] {
        //バイアス項を一つ追加
        self.inputLayer.val.cells = input
        self.inputLayer.val.cells.append(1.0)
        
        //入力にそれぞれ重みを掛けて足し、活性化関数に入れる
        for i in 1 ... (self.layers.count - 1) {
            
            layers[i].out(input: layers[i-1].val)
        }
        
        return outputLayer.val.cells
    }
    
    fileprivate func dropout(_ val:BMM) -> BMM {
        return val.map{ s in
            if (arc4random() % 2 == 0){
                return 0
            }
            return s
        }
    }
    
    public func train(input:[Float], answer:[Float]) {
        
        self.inputLayer.val.cells = input
        self.inputLayer.val.cells.append(1.0)
        
        //入力にそれぞれ重みを掛けて足し、活性化関数に入れる
        for i in 1 ... (self.layers.count - 1) {
//            layers[i-1].val = dropout(layers[i-1].val)
            layers[i].out(input: layers[i-1].val)
        }
        
        // 答えとの誤差を調べる
        // 今の場所での傾きと、誤差を掛けると、δというのが分かるらしい
        outputLayer.delta.cells = zip(answer, outputLayer.val.cells).map { answer, val in
            return (answer - val) * outputLayer.activator.derivative(val)
        }

        
        // hidden layersに伝播していく
        for i in (0..<(layers.count - 1)).reversed() {
            let currentLayer = layers[i]
            let nextLayer = layers[i + 1]
            
            let input_derivative = currentLayer.val.map{ (a:Float) -> Float in
                currentLayer.activator.derivative(a)
            }
            //deltaは傾き×誤差
            //deltaのほうがサイズがひとつ小さいので、最後の1が外れる
            currentLayer.delta <- input_derivative ** BMM.mul_t(nextLayer.delta,nextLayer.syn)
            
            // 重みの修正量 = 入力 * δ だそうです
            let up3 = currentLayer.val.transpose() * nextLayer.delta
            
            nextLayer.syn = nextLayer.syn + up3 * nextLayer.learningRate
        }
        
        // 最初のlayerの学習は、要らんのです。
    }
    
    
    public func batch(input:[[Float]], answer:[[Float]]) {
        
        var inputCells = input
        //1をたす
        let inputMatrix = BMM(rows: input.count, cols: inputCells[0].count, cells: Array(inputCells.joined())).add_col()
        self.inputLayer.val_batch = inputMatrix
        
        //入力にそれぞれ重みを掛けて足し、活性化関数に入れる
        for i in 1 ... (self.layers.count - 1) {
            layers[i].out_g2(input: layers[i-1].val_batch)
        }
        
        //# 答えとの誤差を調べる
        let answerMatrix = BMM(
            rows: answer.count, cols: answer[0].count,
            cells: Array(answer.joined()))
        
        let outputLayer_loss = answerMatrix - outputLayer.val_batch
        
        // 今の場所での傾きと、誤差を掛けると、δというのが分かるらしい
        let slope :BMM = outputLayer.val_batch.map { s in
            outputLayer.activator.derivative(s)
        }
        
        outputLayer.delta_batch = outputLayer_loss ** slope
        
        // hidden layersに伝播していく
        for i in (0 ... (layers.count - 2)).reversed() {
            let currentLayer = layers[i]
            let nextLayer = layers[i + 1]
            
            //TODO mul動くの？
            let currentLayer_loss =
                BMM.mul_t(nextLayer.delta_batch, nextLayer.syn)
            
            let input_derivative = currentLayer.val_batch.map{ (a:Float) -> Float in
                currentLayer.activator.derivative(a)
            }
            
            //deltaは傾き×誤差
            //TODO deltaのほうがサイズがひとつ小さいので、最後の1が外れる
            currentLayer.delta_batch = input_derivative ** currentLayer_loss
            currentLayer.delta_batch = currentLayer.delta_batch.remove_col()
            let input = currentLayer.val_batch!
            // 重みの修正量 = 入力 * δ だそうです
            let up3 = input.transpose() * nextLayer.delta_batch
            
            nextLayer.syn = nextLayer.syn + up3 * nextLayer.learningRate
        }
        
        // 最初のlayerの学習は、要らんのです。
    }
    //------------
    
    public func write(_ url: URL) {
        var storage:Dictionary<String,Any> = [:]
        storage["layernum"] = self.layers.count
        var layerData:Array<Dictionary<String,Any>> = []
        for layer in self.layers {
            layerData.append(layer.toDict())
        }
        storage["layers"] = layerData
        
        let data: Data = try! wrap(storage)
        
        //        let data: Data = NSKeyedArchiver.archivedData(withRootObject: storage)
        
        try? data.write(to: url, options:[.atomic])
    }
    
    public static func read(_ url: URL) throws -> BlueMagic {
        let bm = BlueMagic()
        guard let data = try? Data(contentsOf: url) else {
            throw BMError.InvalidInput("BlueMagic could not find data file.")
        }
        
        // Perform unboxing
        let store = try! Unboxer.init(data: data)
        let layerListData:[Dictionary<String,Any>] = try! store.unbox(key: "layers")
        //        guard let storage = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String : AnyObject] else {
        //            throw BMError.InvalidInput("The data file is broken.")
        //        }
        
        // Read dictionary from file
        //        guard let layerListData = storage["layers"] as? [Dictionary<String,Any>]
        //            else {
        //                throw BMError.InvalidInput("The data file is broken.")
        //        }
        
        for layerData in layerListData.dropLast() {
            let synData:[String:Any] = layerData["syn"] as! [String : Any]
            let l = layer(syn: BMM(
                rows: synData["rows"] as! Int,
                cols: synData["cols"] as! Int,
                cells: synData["cells"] as! [Float]),
                          isOut:false)
            bm.layers.append(l)
        }
        let layerData = layerListData.last!
        let synData:[String:Any] = layerData["syn"] as! [String : Any]
        let l = layer(syn: BMM(
            rows: synData["rows"] as! Int,
            cols: synData["cols"] as! Int,
            cells: synData["cells"] as! [Float]),
                      isOut:true)
        bm.layers.append(l)
        
        return bm
    }
}
