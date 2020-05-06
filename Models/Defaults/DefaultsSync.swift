import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil, using: updateUserDefaultsFromCloud(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		guard let newKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
			return print("No new keys")
		}
		let cloudDefaults = NSUbiquitousKeyValueStore.default
		let userDefaults = UserDefaults.standard
		for key in newKeys {
			let newValue = cloudDefaults.object(forKey: key)
			userDefaults.set(newValue, forKey: key)
		}
		userDefaults.synchronize()
	}
}
