import UIKit
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		if let windowScene = scene as? UIWindowScene {
			let window = UIWindow(windowScene: windowScene)
			self.window = window
			let hostingController = HomeUIHostingController(rootView: ContentView())
			window.rootViewController = hostingController
			window.makeKeyAndVisible()
		}
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		DataModel.shared.update()
	}

	func sceneWillResignActive(_ scene: UIScene) {
		DefaultsSync.synchronize()
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		DefaultsSync.synchronize()
	}
}
