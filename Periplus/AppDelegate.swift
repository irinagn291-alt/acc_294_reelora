import UIKit
import Alamofire
import AppsFlyerLib
import AppTrackingTransparency

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.periplus.route"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        AppsFlyerLib.shared().appsFlyerDevKey = "sdpSZL9sHj6C89QonKusET"
        AppsFlyerLib.shared().appleAppID = "6817396869"
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        return true
    }

    @objc private func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            TrackingPrompt.present()
        }
    }

    @MainActor
    private enum TrackingPrompt {
        private static var asking = false
        private static let opened = Date()

        static func present() {
            if ATTrackingManager.trackingAuthorizationStatus == .denied {
                guard Date().timeIntervalSince(opened) < 8 else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    present()
                }
                return
            }
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            guard UIApplication.shared.applicationState == .active else {
                guard UIApplication.shared.applicationState != .background else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    present()
                }
                return
            }
            guard !asking else { return }
            asking = true
            ATTrackingManager.requestTrackingAuthorization { @Sendable status in
                Task { @MainActor in
                    TrackingPrompt.finish(status)
                }
            }
        }

        private static func finish(_ status: ATTrackingManager.AuthorizationStatus) {
            asking = false
            guard status == .notDetermined else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                present()
            }
        }
    }
}
