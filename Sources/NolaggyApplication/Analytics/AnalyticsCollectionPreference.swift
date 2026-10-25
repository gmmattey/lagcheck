import Foundation

/// Controle local da coleta analítica. A exclusão vale somente nesta instalação
/// e impede tanto os eventos automáticos quanto os eventos de produto.
public final class AnalyticsCollectionPreference: @unchecked Sendable {
    public static let ownerExcludedDefaultsKey = "lagcheck.analytics.owner_excluded"
    public static let disableLaunchArgument = "-lagcheck-analytics-disabled"
    public static let firebaseDebugLaunchArgument = "-lagcheck-firebase-debug"

    private let userDefaults: UserDefaults
    private let arguments: [String]
    private let environment: [String: String]
    private let defaultCollectionEnabled: Bool

    public init(
        userDefaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        defaultCollectionEnabled: Bool? = nil
    ) {
        self.userDefaults = userDefaults
        self.arguments = arguments
        self.environment = environment
        self.defaultCollectionEnabled = defaultCollectionEnabled ?? Self.defaultCollectionEnabled
    }

    public var isCollectionEnabled: Bool {
        defaultCollectionEnabled
            && !isAutomatedTest
            && !arguments.contains(Self.disableLaunchArgument)
            && !userDefaults.bool(forKey: Self.ownerExcludedDefaultsKey)
    }

    public func setOwnerExcluded(_ excluded: Bool) {
        userDefaults.set(excluded, forKey: Self.ownerExcludedDefaultsKey)
    }

    private var isAutomatedTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || arguments.contains(where: { $0.hasPrefix("-ui-fixture") })
    }

    private static var defaultCollectionEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(firebaseDebugLaunchArgument)
        #else
        true
        #endif
    }
}

/// Compõe os destinos de analytics sem permitir que um deles fure a exclusão
/// persistente da instalação ou os testes automatizados.
public struct CollectionGatedAnalyticsTracker: AnalyticsTracker {
    private let preference: AnalyticsCollectionPreference
    private let tracker: any AnalyticsTracker

    public init(preference: AnalyticsCollectionPreference, tracker: any AnalyticsTracker) {
        self.preference = preference
        self.tracker = tracker
    }

    public func track(_ event: AnalyticsEvent) {
        guard preference.isCollectionEnabled else { return }
        tracker.track(event)
    }
}

public struct CompositeAnalyticsTracker: AnalyticsTracker {
    private let trackers: [any AnalyticsTracker]

    public init(trackers: [any AnalyticsTracker]) {
        self.trackers = trackers
    }

    public func track(_ event: AnalyticsEvent) {
        trackers.forEach { $0.track(event) }
    }
}
