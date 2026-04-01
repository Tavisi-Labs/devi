import Foundation
import CoreMotion
import Combine
import UIKit

@MainActor
final class VedicSkyMotionManager: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    @Published private(set) var isActive: Bool = false

    // nonisolated(unsafe) so deinit can safely access from any isolation context (#3)
    private nonisolated(unsafe) var motionManager: CMMotionManager?
    private let motionQueue = OperationQueue()
    private var referenceYaw: Double?
    private nonisolated(unsafe) var observers: [NSObjectProtocol] = []

    /// Whether the view has explicitly requested updates.
    /// Prevents didBecomeActive from restarting motion when VedicSkyView is not visible. (#2)
    private var shouldBeActive: Bool = false

    /// Generation counter — incremented on stopUpdates to discard in-flight callbacks. (#8)
    private var generation: Int = 0

    // Sensitivity: degrees of yaw -> points of scroll
    private let sensitivity: CGFloat = 800

    init() {
        motionQueue.name = "com.devi.vedicsky.motion"
        motionQueue.maxConcurrentOperationCount = 1

        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager = manager

        // (#4) Wrap @MainActor method calls in Task for proper concurrency isolation
        let resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopUpdates()
            }
        }
        observers.append(resignObserver)

        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // (#2) Only restart if the view had explicitly requested motion updates
                if self.shouldBeActive {
                    self.startUpdates()
                }
            }
        }
        observers.append(activeObserver)
    }

    deinit {
        // (#3) observers and motionManager are nonisolated(unsafe) — safe to access here
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        motionManager?.stopDeviceMotionUpdates()
    }

    func startUpdates() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard let motionManager, motionManager.isDeviceMotionAvailable else { return }

        shouldBeActive = true
        referenceYaw = nil
        generation += 1
        let currentGen = generation

        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let currentYaw = motion.attitude.yaw

            Task { @MainActor in
                // (#8) Discard stale callbacks from a previous start/stop cycle
                guard self.generation == currentGen else { return }

                if self.referenceYaw == nil {
                    self.referenceYaw = currentYaw
                }

                guard let referenceYaw = self.referenceYaw else { return }

                let delta = (currentYaw - referenceYaw) * Double(self.sensitivity)
                self.scrollOffset = CGFloat(delta)
                self.isActive = true
            }
        }
    }

    func stopUpdates() {
        shouldBeActive = false
        generation += 1
        motionManager?.stopDeviceMotionUpdates()
        isActive = false
        referenceYaw = nil
    }
}
