import Foundation

/// Web pages for the app, hosted on the developer's portfolio site.
enum AppLinks {
    static let support = URL(string: "https://geodude117.github.io/Portfolio/salvo-sums/")!
    static let privacyPolicy = URL(string: "https://geodude117.github.io/Portfolio/salvo-sums/privacy/")!
}

#if DEBUG
/// Ready-made game positions used to capture App Store screenshots. Debug builds only.
enum ScreenshotScene: String {
    case battle
    case question

    /// The scene asked for with the `-screenshots <scene>` launch argument, if any.
    static var requested: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-screenshots"), flag + 1 < arguments.count else { return nil }
        return ScreenshotScene(rawValue: arguments[flag + 1])
    }
}
#endif
