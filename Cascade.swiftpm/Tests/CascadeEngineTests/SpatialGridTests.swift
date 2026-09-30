//
//  SpatialGridTests.swift
//  CascadeEngineTests
//

import Testing
import simd
@testable import CascadeEngine

@Suite("SpatialGrid")
struct SpatialGridTests {

    private func makeGrid() -> SpatialGrid {
        SpatialGrid(maxObjects: Capacity.gridObjects, cellSize: 11.72)
    }

    @Test("Non-finite coordinates are rejected instead of trapping",
          arguments: [Float.nan, .infinity, -.infinity, .signalingNaN])
    func nonFiniteCoordinatesReturnNoCell(bad: Float) {
        let grid = makeGrid()

        #expect(grid.cellIndex(for: SIMD3(bad, 0, 0)) == -1)
        #expect(grid.cellIndex(for: SIMD3(0, bad, 0)) == -1)
        #expect(grid.cellIndex(for: SIMD3(0, 0, bad)) == -1)
        #expect(grid.cellIndex(for: SIMD3(bad, bad, bad)) == -1)
    }

    @Test("Coordinates far outside the grid are rejected instead of wrapping")
    func farOutOfBoundsReturnsNoCell() {
        let grid = makeGrid()

        #expect(grid.cellIndex(for: SIMD3(1e9, 0, 0)) == -1)
        #expect(grid.cellIndex(for: SIMD3(-1e9, 0, 0)) == -1)
        #expect(grid.cellIndex(for: SIMD3(0, 1e30, 0)) == -1)
    }

    @Test("The origin maps to a real cell")
    func originIsInsideTheGrid() {
        #expect(makeGrid().cellIndex(for: .zero) != -1)
    }

    @Test("Objects in the same cell are chained together")
    func objectsInOneCellFormAChain() {
        var grid = makeGrid()
        let position = SIMD3<Float>(100, 100, 100)
        let cell = grid.cellIndex(for: position)

        grid.add(objectIndex: 0, position: position)
        grid.add(objectIndex: 1, position: position)

        var found: Set<Int> = []
        var object = grid.firstObject(inCell: cell)
        while object != -1 {
            found.insert(object)
            object = grid.nextObject(after: object)
        }

        #expect(found == [0, 1])
    }

    @Test("An out-of-range object index is dropped, not written out of bounds")
    func rejectsOutOfRangeObjectIndex() {
        var grid = SpatialGrid(maxObjects: 4, cellSize: 11.72)
        let position = SIMD3<Float>(0, 0, 0)

        grid.add(objectIndex: 99, position: position)

        #expect(grid.firstObject(inCell: grid.cellIndex(for: position)) == -1)
    }

    @Test("Clearing empties every occupied cell")
    func clearEmptiesOccupiedCells() {
        var grid = makeGrid()
        let position = SIMD3<Float>(50, -50, 25)
        let cell = grid.cellIndex(for: position)

        grid.add(objectIndex: 0, position: position)
        #expect(grid.firstObject(inCell: cell) == 0)

        grid.clear()
        #expect(grid.firstObject(inCell: cell) == -1)
    }

    @Test("A cell's own offset resolves back to itself")
    func neighborOfZeroOffsetIsTheSameCell() {
        let grid = makeGrid()
        let cell = grid.cellIndex(for: SIMD3(30, 60, 90))

        #expect(grid.neighborCell(of: cell, offset: SIMD3(0, 0, 0)) == cell)
    }

    @Test("Every offset is covered exactly once")
    func neighborOffsetsCoverTheFullBlock() {
        #expect(SpatialGrid.neighborOffsets.count == 27)
        #expect(Set(SpatialGrid.neighborOffsets.map { [$0.x, $0.y, $0.z] }).count == 27)
    }

    @Test("Grid boundaries are half-open and neighboring cells never wrap across a face")
    func boundariesDoNotWrap() {
        let grid = SpatialGrid(maxObjects: 1, cellSize: 8)
        let extent = Float(SpatialGrid.gridSize) * grid.cellSize / 2

        for axis in 0..<3 {
            var position = SIMD3<Float>.zero
            position[axis] = -extent
            #expect(grid.cellIndex(for: position) != -1)
            position[axis] = -extent - 0.25
            #expect(grid.cellIndex(for: position) == -1)
            position[axis] = extent - 0.25
            #expect(grid.cellIndex(for: position) != -1)
            position[axis] = extent
            #expect(grid.cellIndex(for: position) == -1)

            for direction in [Int32(-1), 1] {
                position[axis] = Float(direction) * (extent - grid.cellSize / 2)
                let cell = grid.cellIndex(for: position)
                var offset = SIMD3<Int32>.zero
                offset[axis] = direction
                #expect(grid.neighborCell(of: cell, offset: offset) == -1)

                offset[axis] = -direction
                position[axis] -= Float(direction) * grid.cellSize
                #expect(grid.neighborCell(of: cell, offset: offset) == grid.cellIndex(for: position))
            }
        }
    }

    @Test("Clearing a dense cell removes old links before reusing object slots elsewhere")
    func clearAndReinsertObjects() {
        var grid = SpatialGrid(maxObjects: 16, cellSize: 8)
        let oldCell = grid.cellIndex(for: .zero)
        for index in 0..<16 {
            grid.add(objectIndex: index, position: .zero)
        }
        grid.clear()

        let indices = [3, 7, 15]
        let positions: [SIMD3<Float>] = [SIMD3(100, 0, 0), SIMD3(0, 100, 0), SIMD3(0, 0, 100)]
        for (index, position) in zip(indices, positions) {
            grid.add(objectIndex: index, position: position)
        }

        #expect(grid.firstObject(inCell: oldCell) == -1)
        for (index, position) in zip(indices, positions) {
            #expect(grid.firstObject(inCell: grid.cellIndex(for: position)) == index)
            #expect(grid.nextObject(after: index) == -1)
        }
        grid.clear()
        grid.clear()
        for position in positions {
            #expect(grid.firstObject(inCell: grid.cellIndex(for: position)) == -1)
        }
    }

    @Test("Neighbor queries find every nearby object from a brute-force reference")
    func neighborsMatchPairwiseReference() {
        let coordinates: [Float] = [-11, -0.25, 0.25, 11]
        var positions: [SIMD3<Float>] = []
        for x in coordinates {
            for y in coordinates {
                for z in coordinates {
                    positions.append(SIMD3(x, y, z))
                }
            }
        }
        var grid = SpatialGrid(maxObjects: positions.count, cellSize: 8)
        for (index, position) in positions.enumerated() {
            grid.add(objectIndex: index, position: position)
        }

        for position in positions {
            let cell = grid.cellIndex(for: position)
            var candidates: Set<Int> = []
            for offset in SpatialGrid.neighborOffsets {
                let neighbor = grid.neighborCell(of: cell, offset: offset)
                var object = grid.firstObject(inCell: neighbor)
                for _ in 0..<positions.count {
                    guard object != -1 else { break }
                    candidates.insert(object)
                    object = grid.nextObject(after: object)
                }
                #expect(object == -1, "Every cell chain must terminate")
            }
            let expected = Set(positions.indices.filter { distance(positions[$0], position) < 8 })
            let actual = Set(candidates.filter { distance(positions[$0], position) < 8 })
            #expect(actual == expected)
        }
    }

    @Test("A grid snapshot remains valid after its source is cleared and rebuilt")
    func copiedGridKeepsItsObjects() {
        var grid = SpatialGrid(maxObjects: 2, cellSize: 8)
        grid.add(objectIndex: 0, position: .zero)
        grid.add(objectIndex: 1, position: .zero)
        let snapshot = grid

        grid.clear()
        grid.add(objectIndex: 0, position: SIMD3(100, 0, 0))

        let originalCell = snapshot.cellIndex(for: .zero)
        #expect(snapshot.firstObject(inCell: originalCell) == 1)
        #expect(snapshot.nextObject(after: 1) == 0)
        #expect(snapshot.nextObject(after: 0) == -1)
        #expect(grid.firstObject(inCell: originalCell) == -1)
        #expect(grid.firstObject(inCell: grid.cellIndex(for: SIMD3(100, 0, 0))) == 0)
    }
}
