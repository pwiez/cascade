//
//  FastRNGTests.swift
//  CascadeEngineTests
//

import Testing
@testable import CascadeEngine

@Suite("FastRNG")
struct FastRNGTests {

    @Test("Symmetric draws stay inside -1...1")
    func symmetricDrawsAreInRange() {
        var rng = FastRNG(seed: 0xC0FF_EE17)
        for _ in 0..<1_000_000 {
            let value = rng.nextSym()
            #expect(value >= -1 && value <= 1)
        }
    }

    @Test("Ranged draws stay inside their bounds")
    func rangedDrawsAreInRange() {
        var rng = FastRNG(seed: 12345)
        for _ in 0..<1_000_000 {
            let value = rng.next(in: 0.8...1.4)
            #expect(value >= 0.8 && value <= 1.4)
        }
    }

    @Test("Symmetric draws are centred on zero")
    func symmetricDrawsAreCentred() {
        var rng = FastRNG(seed: 99)
        var total = 0.0
        let samples = 1_000_000
        for _ in 0..<samples { total += Double(rng.nextSym()) }

        #expect(abs(total / Double(samples)) < 0.01)
    }

    @Test("A seed of zero doesn't collapse the generator")
    func zeroSeedIsRemapped() {
        // Zero is xorshift's fixed point; the initialiser has to substitute for it
        // or every draw comes back identical.
        var rng = FastRNG(seed: 0)
        let draws = (0..<10).map { _ in rng.nextU32() }

        #expect(Set(draws).count == 10)
    }

    @Test("The same seed replays the same sequence")
    func isDeterministic() {
        var a = FastRNG(seed: 4242)
        var b = FastRNG(seed: 4242)

        #expect((0..<100).allSatisfy { _ in a.nextU32() == b.nextU32() })
    }
}
