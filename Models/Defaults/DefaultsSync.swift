import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil, using: updateUserDefaultsFromCloud(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		guard let newKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
			return print(NSUbiquitousKeyValueStoreChangedKeysKey, "Invalid userInfo", notification.userInfo ?? "nil")
		}
		let cloudDefaults = NSUbiquitousKeyValueStore.default
		for key in newKeys {
			if let worksProgress = DataModel.shared.worksProgress {
				let split = key.split(separator: "｜")
				if split.count == 2 {
					let workName = split[0], workKey = split[1]
					for workProgress in worksProgress {
						if workProgress.work.name == workName {
							switch workKey {
							case "page":
								workProgress.page = cloudDefaults.integer(forKey: key)
							case "rating":
								workProgress.rating = cloudDefaults.integer(forKey: key)
							case "volume":
								workProgress.volume = cloudDefaults.integer(forKey: key)
							default:
								print("Unknown key", workKey)
							}
							break
						}
					}

				}
			}
		}
	}

	static func synchronize() {
		NSUbiquitousKeyValueStore.default.synchronize()
	}
}
