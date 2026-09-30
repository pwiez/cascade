//
//  SimulationWorkQueue.swift
//  Cascade
//

/// Orders solver commands and frame delivery across actor suspension points.
@MainActor
final class SimulationWorkQueue {
    private var tail: Task<Void, Never>?

    @discardableResult
    func enqueue(_ work: @escaping @MainActor @Sendable () async -> Void) -> Task<Void, Never> {
        let previous = tail
        let task = Task {
            // Cancellation does not release our place in the queue: a reset must
            // still wait for an in-flight solver step to finish.
            await previous?.value
            guard !Task.isCancelled else { return }
            await work()
        }
        tail = task
        return task
    }
}
