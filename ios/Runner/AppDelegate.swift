import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let deepLinkChannel = "warp_mobile/deep_link"
  private var deepLinkChannel_method: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup deep link method channel
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    
    deepLinkChannel_method = FlutterMethodChannel(name: deepLinkChannel, binaryMessenger: controller.binaryMessenger)
    
    deepLinkChannel_method?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getInitialLink":
        // Check if app was launched via deep link
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
          print("iOS: Initial deep link found: \(url.absoluteString)")
          result(url.absoluteString)
        } else {
          print("iOS: No initial deep link found")
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    // Check for initial deep link immediately
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      print("iOS: App launched with deep link: \(url.absoluteString)")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.deepLinkChannel_method?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle deep links when app is already running
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("Deep link received: \(url.absoluteString)")
    
    // Send deep link to Flutter
    deepLinkChannel_method?.invokeMethod("onDeepLink", arguments: url.absoluteString)
    
    return true
  }
  
  // Handle universal links (iOS 9+)
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      print("Universal link received: \(url.absoluteString)")
      deepLinkChannel_method?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
