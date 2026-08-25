import Foundation
import ServiceManagement

/// "Start at login", backed by `SMAppService`.
///
/// Deliberately not mirrored into `UserDefaults`: the system owns this state,
/// and a copy of it would go stale the moment the user changes it in System
/// Settings.
enum LoginItem {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns the error instead of swallowing it - registration fails for an
    /// app that is only ad-hoc signed or runs from a build folder, and the user
    /// deserves to know why the switch bounced back.
    static func setEnabled(_ enabled: Bool) -> Error? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error
        }
    }
}
