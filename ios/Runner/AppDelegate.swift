import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      // Check whether it's iOS 15.0 or above (since this API is only available there)
      if #available(iOS 15.0, *) {
          // Instance of CADisplayLink which exposes several frame rate related options
          let displayLink = CADisplayLink(target: self, selector: #selector(step))
          // Set the preferred range of frames (in this case "High-impact animations" based on the documentation)
          displayLink.preferredFrameRateRange = CAFrameRateRange(minimum:80, maximum:120, preferred:120)
          // Enable it by adding it to the main runloop
          displayLink.add(to: .current, forMode: .default)
      }
      
      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    @objc func step(displaylink: CADisplayLink) {
        // Will be called once a frame has been built while matching desired frame rate
    }
}
