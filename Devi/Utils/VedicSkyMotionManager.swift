import Foundation
import CoreMotion
import Combine
import UIKit

@MainActor
final class VedicSkyMotionManager: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    @Published private(set) var isActive: Bool = false

    private var motionManager: CMMotionManager?
    private let motionQueue = OperationQueue()
    private var referenceYaw: Double?
    private var observers: [NSObjectProtocol] = []

    // Sensitivity: degrees of yaw -> points of scroll
    private let sensitivity: CGFloat = 800

    init() {
        motionQueue.name = "com.devi.vedicsky.motion"
        motionQueue.maxConcurrentOperationCount = 1

        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager = manager

        let resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.stopUpdates()
            }
        }
        observers.append(resignObserver)

        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.startUpdates()
            }
        }
        observers.append(activeObserver)
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        motionManager?.stopDeviceMotionUpdates()
    }

    func startUpdates() {
        guard let motionManager, motionManager.isDeviceMotionAvailable else { return }

        referenceYaw = nil

        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let currentYaw = motion.attitude.yaw

            Task { @MainActor in
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
        motionManager?.stopDeviceMotionUpdates()
        isActive = false
        referenceYaw = nil
    }
}
