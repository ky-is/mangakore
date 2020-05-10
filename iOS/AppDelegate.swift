import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		DefaultsSync.observe()
		UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .label
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		return [.portrait, .portraitUpsideDown]
	}

	func applicationWillTerminate(_ application: UIApplication) {
		DefaultsSync.synchronize()
	}
}
