import SwiftUI

struct RitualMotionGate: Equatable {
    let allowsAmbientMotion: Bool
    let prefersReducedMotion: Bool

    static func resolve(scenePhase: ScenePhase, reduceMotion: Bool, isVisible: Bool = true) -> RitualMotionGate {
        let active = scenePhase == .active && isVisible
        return RitualMotionGate(
            allowsAmbientMotion: active && !reduceMotion,
            prefersReducedMotion: reduceMotion || !active
        )
    }
}
