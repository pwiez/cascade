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

    /// Regression test for the crash chain in `spawnExplosion`: a fragment whose
    /// velocity cancelled to zero normalised to NaN, and converting NaN to `Int`
    /// is a hard trap in Swift rather than a wrong answer.
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
}
