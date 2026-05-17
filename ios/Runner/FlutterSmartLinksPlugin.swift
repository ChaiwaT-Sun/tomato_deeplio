import Flutter
import UIKit

/**
 FlutterSmartLinksPlugin (iOS / Swift)

 Handles:
 - Universal Links (HTTPS — requires apple-app-site-association)
 - Custom URI scheme deep links
 - Initial link extraction (cold start)
 - Foreground link stream (EventChannel)
 - Deferred link token persistence (UserDefaults)
 */
public class FlutterSmartLinksPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - Constants

    private static let methodChannelName = "flutter_smart_links"
    private static let eventChannelName  = "flutter_smart_links/events"
    private static let deferredTokenKey  = "flutter_smart_links_deferred_token"

    // MARK: - State

    private var eventSink: FlutterEventSink?
    private var initialLink: String?
    private var pendingLink: String?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterSmartLinksPlugin()

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
            initialLink = nil // consume once

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
        // Flush any link that arrived before the stream was ready
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
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            handleIncomingUrl(url.absoluteString)
            return true
        }
        return false
    }

    // MARK: - Private helpers

    private func handleIncomingUrl(_ urlString: String) {
        if eventSink != nil {
            eventSink?(urlString)
        } else if initialLink == nil {
            // First link before stream is ready → treat as initial link
            initialLink = urlString
        } else {
            pendingLink = urlString
        }
    }
}
