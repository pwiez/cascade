//
//  SpatialGrid.swift
//  Cascade
//
//  Created by Pedro Wiezel on 14/02/26.
//

import Foundation
import simd

struct SpatialGrid {

    private var headCell:     ContiguousArray<Int32>
    private var nextParticle: ContiguousArray<Int32>
    private var usedCells:    ContiguousArray<Int>

    let gridSize: Int = 128
    let shiftY:   Int = 7
    let shiftZ:   Int = 14
    let mask:     Int = 127

    let offset: Float
    let cellSize: Float
    let inverseCellSize: Float
    let cellCount: Int

    let neighborOffsets: [(dx: Int, dy: Int, dz: Int)]

    init(maxObjects: Int, cellSize: Float = 10.0) {
        self.cellSize = cellSize
        self.inverseCellSize = 1.0 / cellSize
        self.offset = (Float(128) * cellSize) / 2.0
        self.cellCount = 128 * 128 * 128

        self.headCell = ContiguousArray(repeating: -1, count: cellCount)
        self.nextParticle = ContiguousArray(repeating: -1, count: maxObjects)

        self.usedCells = ContiguousArray()
        self.usedCells.reserveCapacity(maxObjects)

        var offsets: [(dx: Int, dy: Int, dz: Int)] = []
        offsets.reserveCapacity(27)
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    offsets.append((dx: x, dy: y, dz: z))
                }
            }
        }
        self.neighborOffsets = offsets
    }

    @inline(__always)
    func neighborCell(of cellID: Int, offset: (dx: Int, dy: Int, dz: Int)) -> Int {
        let cx = (cellID & mask) + offset.dx
        let cy = ((cellID >> shiftY) & mask) + offset.dy
        let cz = ((cellID >> shiftZ) & mask) + offset.dz
        guard cx >= 0 && cx < gridSize && cy >= 0 && cy < gridSize && cz >= 0 && cz < gridSize else { return -1 }
        return cx | (cy << shiftY) | (cz << shiftZ)
    }

    mutating func clear() {
        headCell.withUnsafeMutableBufferPointer { headPtr in
            usedCells.withUnsafeBufferPointer { usedPtr in
                for cellIndex in usedPtr {
                    headPtr[cellIndex] = -1
                }
            }
        }
        usedCells.removeAll(keepingCapacity: true)
    }

    mutating func add(objectIndex: Int, position: SIMD3<Float>) {
        let cellID = getCellIndex(for: position)
        guard cellID != -1 else { return }
        
        if headCell[cellID] == -1 {
            usedCells.append(cellID)
        }
        
        nextParticle[objectIndex] = headCell[cellID]
        headCell[cellID] = Int32(objectIndex)
    }

    @inline(__always)
    func getCellIndex(for position: SIMD3<Float>) -> Int {
        let x = Int((position.x + offset) * inverseCellSize)
        let y = Int((position.y + offset) * inverseCellSize)
        let z = Int((position.z + offset) * inverseCellSize)
        guard x & ~mask == 0 && y & ~mask == 0 && z & ~mask == 0 else { return -1 }
        return x | (y << shiftY) | (z << shiftZ)
    }

    @inline(__always)
    func firstObject(inCell cellIndex: Int) -> Int {
        guard cellIndex >= 0 && cellIndex < cellCount else { return -1 }
        return Int(headCell[cellIndex])
    }

    @inline(__always)
    func nextObject(after objectIndex: Int) -> Int {
        return Int(nextParticle[objectIndex])
    }
}
