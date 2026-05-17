import Flutter
import UIKit

/// TomatoDeeplioPlugin (iOS / Swift)
///
/// Handles:
/// - Universal Links (HTTPS — requires apple-app-site-association)
/// - Custom URI scheme deep links
/// - Initial link extraction (cold start)
/// - Foreground link stream (EventChannel)
/// - Deferred link token persistence (UserDefaults)
public class TomatoDeeplioPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - Constants

    private static let methodChannelName = "tomato_deeplio"
    private static let eventChannelName  = "tomato_deeplio/events"
    private static let deferredTokenKey  = "tomato_deeplio_deferred_token"

    // MARK: - State

    private var eventSink: FlutterEventSink?
    private var initialLink: String?
    private var pendingLink: String?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TomatoDeeplioPlugin()

        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)

        registrar.addApplicationDelegate(instance)
    }

    // MARK: - FlutterMethodCallDelegate

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInitialLink":
            result(initialLink)
            initialLink = nil

        case "storeDeferredToken":
            if let args = call.arguments as? [String: Any],
               let token = args["token"] as? String {
                UserDefaults.standard.set(token, forKey: Self.deferredTokenKey)
            }
            result(nil)

        case "getDeferredToken":
            result(UserDefaults.standard.string(forKey: Self.deferredTokenKey))

        case "clearDeferredToken":
            UserDefaults.standard.removeObject(forKey: Self.deferredTokenKey)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        if let pending = pendingLink {
            events(pending)
            pendingLink = nil
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - UIApplicationDelegate hooks

    /// Cold-start via custom URI scheme (e.g. myapp://product/123)
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleIncomingUrl(url.absoluteString)
        return true
    }

    /// Cold-start via Universal Link (HTTPS)
    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        handleIncomingUrl(url.absoluteString)
        return true
    }

    // MARK: - Private helpers

    private func handleIncomingUrl(_ urlString: String) {
        if eventSink != nil {
            eventSink?(urlString)
        } else if initialLink == nil {
            initialLink = urlString
        } else {
            pendingLink = urlString
        }
    }
}
