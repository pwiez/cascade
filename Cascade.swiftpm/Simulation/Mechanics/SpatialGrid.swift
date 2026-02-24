//
//  SpatialGrid.swift
//  Kessler
//
//  Created by Pedro Wiezel on 13/02/26.
//

import Foundation
import simd

struct SpatialGrid {
    private var headCell: ContiguousArray<Int32>
    private var nextParticle: ContiguousArray<Int32>
    private var usedCells: [Int] = []
    
    let neighborOffsets: [Int]
    
    
    let gridSize: Int = 128
    let shiftY: Int = 7
    let shiftZ: Int = 14
    let mask: Int = 127
    
    let offset: Float
    let cellSize: Float
    let inverseCellSize: Float
    let cellCount: Int
    
    init(maxObjects: Int, cellSize: Float = 10.0) {
        self.cellSize = cellSize
        self.inverseCellSize = 1.0 / cellSize
        self.offset = (Float(128) * cellSize) / 2.0
        self.cellCount = 128 * 128 * 128
        
        self.headCell = ContiguousArray(repeating: -1, count: cellCount)
        self.nextParticle = ContiguousArray(repeating: -1, count: maxObjects)
        self.usedCells.reserveCapacity(maxObjects)
        
        
        var offsets: [Int] = []
        offsets.reserveCapacity(27)
        let gs = 128
        let gs2 = 128 * 128
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    offsets.append(x + (y * gs) + (z * gs2))
                }
            }
        }
        self.neighborOffsets = offsets
    }
    
    mutating func clear() {
        for cellIndex in usedCells {
            headCell[cellIndex] = -1
        }
        usedCells.removeAll(keepingCapacity: true)
    }
    
    mutating func add(objectIndex: Int, position: SIMD3<Float>) {
        let cellID = getCellIndex(for: position)
        if cellID != -1 {
            if headCell[cellID] == -1 {
                usedCells.append(cellID)
            }
            nextParticle[objectIndex] = headCell[cellID]
            headCell[cellID] = Int32(objectIndex)
        }
    }
    
    @inline(__always)
    func getCellIndex(for position: SIMD3<Float>) -> Int {
        let x = Int((position.x + offset) * inverseCellSize)
        let y = Int((position.y + offset) * inverseCellSize)
        let z = Int((position.z + offset) * inverseCellSize)
        
        if x & ~mask == 0 && y & ~mask == 0 && z & ~mask == 0 {
            return x | (y << shiftY) | (z << shiftZ)
        }
        return -1
    }
    
    @inline(__always)
    func firstObject(inCell cellIndex: Int) -> Int {
        if cellIndex >= 0 && cellIndex < cellCount { return Int(headCell[cellIndex]) }
        return -1
    }
    
    @inline(__always)
    func nextObject(after objectIndex: Int) -> Int {
        return Int(nextParticle[objectIndex])
    }
}
