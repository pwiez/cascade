//
//  SpatialGrid.swift
//  Cascade
//
//  Created by Pedro Wiezel on 14/02/26.
//

import simd

/// A uniform grid that turns collision detection from O(n²) into O(n).
///
/// Rather than testing every object against every other, each object is filed
/// into the cell containing it, and only the 27 cells around a candidate are
/// searched. Occupancy is stored as an intrusive linked list — `headCell` holds
/// the first object in each cell and `nextParticle` chains the rest — so
/// inserting is two writes and no allocation.
///
/// Clearing is O(occupied cells) rather than O(all cells), which matters: there
/// are two million cells and only a few thousand objects.
struct SpatialGrid {

    /// Cells per axis. A power of two so a coordinate maps to a cell index with
    /// shifts and masks instead of multiplies.
    static let gridSize = 128
    private static let shiftY = 7
    private static let shiftZ = 14
    private static let mask = gridSize - 1

    /// The 27 cells around and including a given cell.
    ///
    /// Static because it never varies, and because rebuilding it per grid was
    /// pointless allocation.
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

    /// Shifts world space so the grid is centred on Earth rather than starting at
    /// the origin, since orbits are symmetric about it.
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
        // Cheap insurance: `Capacity` is supposed to guarantee this, but an
        // out-of-range index here would be a silent out-of-bounds write rather
        // than a dropped object.
        guard objectIndex >= 0, objectIndex < maxObjects else { return }

        let cellID = cellIndex(for: position)
        guard cellID != -1 else { return }

        if headCell[cellID] == -1 {
            usedCells.append(cellID)
        }
        nextParticle[objectIndex] = headCell[cellID]
        headCell[cellID] = Int32(objectIndex)
    }

    /// The cell containing `position`, or -1 if it falls outside the grid.
    ///
    /// The bounds are checked in floating point, *before* the conversion to
    /// `Int`, and that ordering is the whole point: converting a `Float` to `Int`
    /// traps at runtime if the value is NaN, infinite, or simply larger than
    /// `Int.max`. Checking afterwards would already have crashed. Comparisons
    /// against NaN are always false, so the same guard covers all three cases.
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
