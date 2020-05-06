import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil, using: updateUserDefaultsFromCloud(notification:))
		NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil, using: updateCloudFromUserDefaults(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
		defer {
			NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil, using: updateCloudFromUserDefaults(notification:))
		}

		let cloudDictionary = NSUbiquitousKeyValueStore.default.dictionaryRepresentation
		let userDefaults = UserDefaults.standard
		for (key, obj) in cloudDictionary {
			userDefaults.set(obj, forKey: key)
		}
		userDefaults.synchronize()
	}

	static func updateCloudFromUserDefaults(notification: Notification) {
		let defaultsDictionary = UserDefaults.standard.dictionaryRepresentation()
		let cloudStore = NSUbiquitousKeyValueStore.default
		for (key, obj) in defaultsDictionary {
			cloudStore.set(obj, forKey: key)
		}
		cloudStore.synchronize()
	}
}
