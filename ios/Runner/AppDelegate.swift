import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register the SmartLinks plugin
        FlutterSmartLinksPlugin.register(
            with: registrar(forPlugin: "FlutterSmartLinksPlugin")!
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ── Universal Links (HTTPS) ────────────────────────────────────────────

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Forward to the plugin first
        let handled = FlutterSmartLinksPlugin().application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
        if handled { return true }
        return super.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
    }

    // ── Custom URI Scheme ──────────────────────────────────────────────────

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let handled = FlutterSmartLinksPlugin().application(app, open: url, options: options)
        if handled { return true }
        return super.application(app, open: url, options: options)
    }
}
