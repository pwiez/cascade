//
//  SimulationWorkQueueTests.swift
//  CascadeEngineTests
//

import Testing
@testable import CascadeEngine

@Suite("Simulation work ordering")
@MainActor
struct SimulationWorkQueueTests {
    @Test("Reset waits for a cancelled in-flight frame before starting the next frame")
    func resetWaitsForInFlightWork() async {
        let queue = SimulationWorkQueue()
        let (started, signal) = AsyncStream<Void>.makeStream()
        var releaseFrame: CheckedContinuation<Void, Never>?
        var events: [String] = []

        let frame = queue.enqueue {
            events.append("frame started")
            // Model synchronous solver work, which cannot stop merely because
            // its caller was cancelled. The test controls completion explicitly.
            await withCheckedContinuation { releaseFrame = $0; signal.yield(()) }
            events.append("frame finished")
        }
        var starts = started.makeAsyncIterator()
        await starts.next()

        frame.cancel()
        queue.enqueue { events.append("reset") }
        let nextFrame = queue.enqueue { events.append("next frame") }
        releaseFrame?.resume()
        await nextFrame.value
        signal.finish()

        #expect(events == ["frame started", "frame finished", "reset", "next frame"])
    }

    @Test("A cancelled waiting frame is skipped without dropping the commands behind it")
    func cancelledWaitingWorkIsSkipped() async {
        let queue = SimulationWorkQueue()
        let (started, signal) = AsyncStream<Void>.makeStream()
        var releaseCommand: CheckedContinuation<Void, Never>?
        var events: [String] = []

        queue.enqueue {
            await withCheckedContinuation { releaseCommand = $0; signal.yield(()) }
            events.append("settings")
        }
        var starts = started.makeAsyncIterator()
        await starts.next()

        let obsoleteFrame = queue.enqueue { events.append("obsolete frame") }
        obsoleteFrame.cancel()
        let reset = queue.enqueue { events.append("reset") }
        releaseCommand?.resume()
        await reset.value
        signal.finish()

        #expect(events == ["settings", "reset"])
    }
}
