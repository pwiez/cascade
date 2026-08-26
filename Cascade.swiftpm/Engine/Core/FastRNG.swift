//
//  FastRNG.swift
//  Cascade
//

/// A xorshift32 generator, seeded once and threaded through the solver.
///
/// `SystemRandomNumberGenerator` is fine anywhere else, but debris spawning calls
/// this dozens of times per collision inside the physics step, where the syscall
/// cost shows up. Being explicitly seeded also makes the solver reproducible,
/// which is what lets it be tested at all.
struct FastRNG {
    private var state: UInt32

    init(seed: UInt32) {
        // Zero is xorshift's fixed point: it would emit zero forever.
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

    /// A value in -1...1. Takes the top 24 bits, which are the well-mixed ones.
    mutating func nextSym() -> Float {
        Float(nextU32() >> 8) * (1.0 / 8_388_608.0) - 1.0
    }

    mutating func next(in range: ClosedRange<Float>) -> Float {
        let unit = Float(nextU32() >> 8) * (1.0 / 16_777_216.0)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}
