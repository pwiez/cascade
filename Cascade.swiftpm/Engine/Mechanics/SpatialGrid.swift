//
//  SpatialGrid.swift
//  Cascade
//
//  Created by Pedro Wiezel on 14/02/26.
//

import simd

struct SpatialGrid {

    static let gridSize = 128
    private static let shiftY = 7
    private static let shiftZ = 14
    private static let mask = gridSize - 1

    static let neighborOffsets: [SIMD3<Int32>] = {
        var offsets: [SIMD3<Int32>] = []
        offsets.reserveCapacity(27)
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    offsets.append(SIMD3(Int32(x), Int32(y), Int32(z)))
                }
            }
        }
        return offsets
    }()

    private var headCell: ContiguousArray<Int32>
    private var nextParticle: ContiguousArray<Int32>
    private var usedCells: ContiguousArray<Int>

    let cellSize: Float
    private let inverseCellSize: Float

    private let offset: Float

    private let cellCount: Int
    private let maxObjects: Int

    init(maxObjects: Int, cellSize: Float) {
        self.cellSize = cellSize
        self.inverseCellSize = 1.0 / cellSize
        self.offset = (Float(Self.gridSize) * cellSize) / 2.0
        self.cellCount = Self.gridSize * Self.gridSize * Self.gridSize
        self.maxObjects = maxObjects

        self.headCell = ContiguousArray(repeating: -1, count: cellCount)
        self.nextParticle = ContiguousArray(repeating: -1, count: maxObjects)
        self.usedCells = ContiguousArray()
        self.usedCells.reserveCapacity(maxObjects)
    }

    mutating func clear() {
        headCell.withUnsafeMutableBufferPointer { head in
            usedCells.withUnsafeBufferPointer { used in
                for cell in used { head[cell] = -1 }
            }
        }
        usedCells.removeAll(keepingCapacity: true)
    }

    mutating func add(objectIndex: Int, position: SIMD3<Float>) {
        guard objectIndex >= 0, objectIndex < maxObjects else { return }

        let cellID = cellIndex(for: position)
        guard cellID != -1 else { return }

        if headCell[cellID] == -1 {
            usedCells.append(cellID)
        }
        nextParticle[objectIndex] = headCell[cellID]
        headCell[cellID] = Int32(objectIndex)
    }

    @inline(__always)
    func cellIndex(for position: SIMD3<Float>) -> Int {
        let scaled = (position + offset) * inverseCellSize
        let limit = Float(Self.gridSize)

        guard scaled.x >= 0, scaled.x < limit,
              scaled.y >= 0, scaled.y < limit,
              scaled.z >= 0, scaled.z < limit else { return -1 }

        return Int(scaled.x) | (Int(scaled.y) << Self.shiftY) | (Int(scaled.z) << Self.shiftZ)
    }

    @inline(__always)
    func neighborCell(of cellID: Int, offset: SIMD3<Int32>) -> Int {
        let x = (cellID & Self.mask) + Int(offset.x)
        let y = ((cellID >> Self.shiftY) & Self.mask) + Int(offset.y)
        let z = ((cellID >> Self.shiftZ) & Self.mask) + Int(offset.z)

        guard x >= 0, x < Self.gridSize,
              y >= 0, y < Self.gridSize,
              z >= 0, z < Self.gridSize else { return -1 }

        return x | (y << Self.shiftY) | (z << Self.shiftZ)
    }

    @inline(__always)
    func firstObject(inCell cellIndex: Int) -> Int {
        guard cellIndex >= 0, cellIndex < cellCount else { return -1 }
        return Int(headCell[cellIndex])
    }

    @inline(__always)
    func nextObject(after objectIndex: Int) -> Int {
        Int(nextParticle[objectIndex])
    }
}
