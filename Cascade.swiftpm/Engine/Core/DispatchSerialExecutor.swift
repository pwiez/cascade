//
//  DispatchSerialExecutor.swift
//  Cascade
//

import Foundation

/// A serial executor backed by a private Dispatch queue.
///
/// ``PhysicsSolver`` parallelises its inner loops with
/// `DispatchQueue.concurrentPerform`, which *blocks* its caller until every
/// iteration finishes. That is still the right tool for CPU-bound data
/// parallelism — structured concurrency has no synchronous equivalent — but a
/// default actor runs on Swift's cooperative thread pool, whose whole contract
/// is that its threads never block. Blocking one there starves the pool the
/// solver is itself competing with.
///
/// Adopting this executor moves the solver's jobs onto a thread that is allowed
/// to block, without changing a single call site: `await solver.step(…)` still
/// reads exactly the same.
final class DispatchSerialExecutor: SerialExecutor {
    private let queue: DispatchQueue

    init(label: String) {
        queue = DispatchQueue(label: label, qos: .userInitiated)
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        queue.async { job.runSynchronously(on: executor) }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
