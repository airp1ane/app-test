import Foundation

/// Restarts the toast's timeout when a new one appears or it's let go.
struct ToastTimer: Equatable {
    let celebration: Celebration?
    let isHeld: Bool
}
