import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil, using: updateUserDefaultsFromCloud(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		let cloudDictionary = NSUbiquitousKeyValueStore.default.dictionaryRepresentation
		let userDefaults = UserDefaults.standard
		for (key, obj) in cloudDictionary {
			userDefaults.set(obj, forKey: key)
		}
		userDefaults.synchronize()
	}
}
