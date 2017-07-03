//==============================
// LinearAlgebra
//------------------------------
// Matrix.swift
//==============================

import Foundation
import Accelerate


struct BMM {
    
    var rows:Int
    var cols:Int
    var cells:[Float]
    
    init(rows: Int, cols: Int, repeats: Float) {
        self.rows = rows
        self.cols = cols
        self.cells = [Float](repeating: repeats, count: rows * cols)
    }
    
    init(rows: Int, cols: Int, cells: [Float]) {
        self.rows = rows
        self.cols = cols
        self.cells = cells
    }
    
    func toDict() -> Dictionary<String, Any> {
        return [
            "rows" : rows,
            "cols" : cols,
            "cells": cells
        ]
    }
    
    func transpose() -> BMM {
        var cells = [Float](repeating: 0, count: rows * cols)
        vDSP_mtrans(self.cells, 1, &cells, 1, vDSP_Length(cols), vDSP_Length(rows))
        return BMM(rows: cols, cols: rows, cells: cells)
    }
    
    static func copy(from:BMM, to:inout BMM) {
        let mincols = min(from.cols, to.cols)
        vDSP_mmov(from.cells, &to.cells, vDSP_Length(mincols), 1, vDSP_Length(mincols), vDSP_Length(to.cols))
        //        cblas_scopy(Int32(from.rows * from.cols),
        //                         from.cells,1,
        //                         &to.cells,1)
    }
    
    func add_row() -> BMM {
        var copy = self
        copy.cells.append(contentsOf: [Float](repeating:1.0, count:self.cols))
        copy.rows += 1
        return copy
    }
    
    func add_col() -> BMM {
        var copy = self
        let startCount = self.cells.count
        stride(from:startCount, to: 0, by: -self.cols).forEach { n in
            copy.cells.insert(1.0, at: n)
        }
        copy.cols += 1
        return copy
//        let tran = self.transpose()
//        return tran.add_row().transpose()
    }
    
    func remove_row() -> BMM {
        var copy = self
        copy.cells.removeSubrange(copy.cells.count - self.cols ... copy.cells.count - 1)
        copy.rows -= 1
        return copy
    }
    
    func remove_col() -> BMM {
        let tran = self.transpose()
        return tran.remove_row().transpose()
    }
    
    static func mul(_ x: BMM, _ y: BMM) -> BMM {
        
        guard x.cols == y.rows else {
            precondition(y.cells.count == 1, "Matrix dimensions not compatible with multiplication")
            
            // this is scalar multiplication
            return BMM.scale(x, y.cells[0])
        }
        
        var result:[Float] = [Float](repeating: 0.0, count:x.rows * y.cols)
//                        vDSP_mmul(x.cells, 1,
//                                  y.cells, 1,
//                                  &result, 1,
//                                  vDSP_Length(x.rows), vDSP_Length(y.cols), vDSP_Length(x.cols))
        cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, Int32(x.rows), Int32(y.cols), Int32(x.cols), 1.0, x.cells, Int32(x.cols), y.cells, Int32(y.cols), 0.0, &result, Int32(y.cols))
        
        return BMM(rows: x.rows, cols: y.cols, cells: result)
    }
    
    static func mul_t(_ x: BMM, _ y: BMM) -> BMM {
        
        guard x.cols == y.cols else {
            precondition(y.cells.count == 1, "Matrix dimensions not compatible with multiplication")
            
            // this is scalar multiplication
            return BMM.scale(x, y.cells[0])
        }
        
        var result:[Float] = [Float](repeating: 0.0, count:x.rows * y.rows)

        cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasTrans, Int32(x.rows), Int32(y.rows), Int32(x.cols), 1.0, x.cells, Int32(x.cols), y.cells, Int32(y.cols), 0.0, &result, Int32(y.rows))
        
        return BMM(rows: x.rows, cols: y.rows, cells: result)
    }
    
    static func scale(_ x: BMM, _ y: Float) -> BMM {
        let cellsNum = x.cells.count
        
        var yy = [Float](repeating: y, count: cellsNum)
        
        cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                    Int32(cellsNum), Int32(1), Int32(1), 1.0,
                    x.cells, Int32(1), yy, Int32(cellsNum),
                    0.0, &yy, Int32(1))
        return BMM(rows: x.rows, cols: x.cols, cells: yy)
        
        //                var results = [Float](repeating: y, count: cellsNum)
        //                vDSP_vmul(x.cells, 1, x.cells, 1, &results, 1, vDSP_Length(cellsNum))
        //                return BMM(rows: x.rows, cols: x.cols, cells:results)
    }
    
    static func mul_elementwise(_ x: BMM, _ y: BMM) -> BMM {
        let cellsNum = x.cells.count
        var results = [Float](repeating: 0.0, count: cellsNum)
        
        // implementation 1
        vDSP_vmul(x.cells, 1, y.cells, 1, &results, 1, vDSP_Length(cellsNum))
        return BMM(rows: x.rows, cols: y.cols, cells:results)
        
        // implementation 2
        //        return BMM(rows: x.rows, cols: y.cols,
        //                   cells:zip(x.cells, y.cells).map { $0 * $1 })
    }
    
    static func add(_ x: BMM, _ y: BMM) -> BMM {
        
        precondition(x.rows * x.cols == y.rows * y.cols, "Matrix dimensions not compatible with multiplication")
        
        var result:[Float] = y.cells
        catlas_saxpby(Int32(x.rows * x.cols), 1, x.cells, 1, 1, &result, 1)
        return BMM(rows: x.rows, cols: y.cols, cells: result)
    }
    
    static func sub(_ x: BMM, _ y: BMM) -> BMM {
        
        precondition(x.rows * x.cols == y.rows * y.cols, "Matrix dimensions not compatible with multiplication")
        
        var result:[Float] = y.cells
        catlas_saxpby(Int32(x.rows * x.cols), 1, x.cells, 1, -1, &result, 1)
        return BMM(rows: x.rows, cols: y.cols, cells: result)
    }
    
    func map(_ transform: (Float) throws -> Float) -> BMM {
        
        return BMM(rows: self.rows, cols: self.cols,
                   cells: try! self.cells.map(transform))
    }
    
}

infix operator <- : AssignmentPrecedence
func <- (left:inout BMM, right: BMM) {
    return BMM.copy(from:right, to:&left)
}

func +(left: BMM, right: BMM) -> BMM {
    return BMM.add(left, right)
}

func -(left: BMM, right: BMM) -> BMM {
    return BMM.sub(left, right)
}

func *(left: BMM, right: BMM) -> BMM {
    return BMM.mul(left, right)
}

func *(left: BMM, right: Float) -> BMM {
    return BMM.scale(left, right)
}

func *(left: Float, right: BMM) -> BMM {
    return BMM.scale(right, left)
}

infix operator ** : MultiplicationPrecedence
func **(left: BMM, right: BMM) -> BMM {
    return BMM.mul_elementwise(left, right)
}
