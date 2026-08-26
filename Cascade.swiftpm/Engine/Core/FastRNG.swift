//
//  FastRNG.swift
//  Cascade
//

struct FastRNG {
    private var state: UInt32

    init(seed: UInt32) {
        self.state = seed == 0 ? 0xdead_beef : seed
    }

    mutating func nextU32() -> UInt32 {
        var x = state
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        state = x
        return x
    }

    mutating func nextSym() -> Float {
        Float(nextU32() >> 8) * (1.0 / 8_388_608.0) - 1.0
    }

    mutating func next(in range: ClosedRange<Float>) -> Float {
        let unit = Float(nextU32() >> 8) * (1.0 / 16_777_216.0)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}
