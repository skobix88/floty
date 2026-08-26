import Foundation

/// The version as it should be shown and tagged.
///
/// `CFBundleShortVersionString` has to stay purely numeric - Apple's tooling
/// rejects `1.0.0-rc.1` there once notarisation is involved. The pre-release
/// part therefore lives in its own key and is only glued on for display.
enum AppVersion {

    static var marketing: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static var preRelease: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "FlotyPreRelease") as? String
        return (value?.isEmpty ?? true) ? nil : value
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// `1.0.0` or `1.0.0-rc.1`
    static func semantic(marketing: String, preRelease: String?) -> String {
        guard let preRelease, !preRelease.isEmpty else { return marketing }
        return "\(marketing)-\(preRelease)"
    }

    static var semantic: String { semantic(marketing: marketing, preRelease: preRelease) }

    /// What the settings window shows: `Floty 1.0.0-rc.1 (12)`
    static var display: String { "Floty \(semantic) (\(build))" }
}
