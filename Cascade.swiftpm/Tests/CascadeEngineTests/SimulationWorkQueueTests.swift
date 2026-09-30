//
//  SimulationWorkQueueTests.swift
//  CascadeEngineTests
//

import Testing
@testable import CascadeEngine

@Suite("Simulation work ordering")
@MainActor
struct SimulationWorkQueueTests {
    @Test("Suspending commands finish in the order they were enqueued")
    func commandsRemainFIFO() async {
        let queue = SimulationWorkQueue()
        var events: [Int] = []
        var tasks: [Task<Void, Never>] = []
        for index in 0..<100 {
            tasks.append(queue.enqueue {
                events.append(index * 2)
                await Task.yield()
                events.append(index * 2 + 1)
            })
        }

        for task in tasks { await task.value }

        #expect(events == Array(0..<200))
    }

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

    @Test("A command can enqueue follow-up work behind commands already waiting")
    func nestedEnqueuePreservesOrder() async throws {
        let queue = SimulationWorkQueue()
        var events: [String] = []
        var followUp: Task<Void, Never>?
        queue.enqueue {
            events.append("first started")
            followUp = queue.enqueue { events.append("follow-up") }
            await Task.yield()
            events.append("first finished")
        }
        let second = queue.enqueue { events.append("second") }

        await second.value
        let final = try #require(followUp)
        await final.value

        #expect(events == ["first started", "first finished", "second", "follow-up"])
    }

    @Test("Several cancelled frames cannot block a later reset or resumed frame")
    func consecutiveCancellationsPreserveProgress() async {
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

        for _ in 0..<10 {
            let obsolete = queue.enqueue { events.append("obsolete frame") }
            obsolete.cancel()
        }
        queue.enqueue { events.append("reset") }
        let resumed = queue.enqueue { events.append("resumed frame") }
        releaseCommand?.resume()
        await resumed.value
        signal.finish()

        #expect(events == ["settings", "reset", "resumed frame"])
    }
}
