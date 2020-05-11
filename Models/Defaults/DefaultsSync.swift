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
					let workName = split[0], progressKey = split[1]
					for workProgress in worksProgress {
						if workProgress.work.name == workName {
							switch progressKey {
							case "p":
								workProgress.page = cloudDefaults.integer(forKey: key)
							case "r":
								workProgress.rating = cloudDefaults.integer(forKey: key)
							case "v":
								workProgress.volume = cloudDefaults.integer(forKey: key)
							case "c":
								workProgress.contiguous = cloudDefaults.bool(forKey: key)
							default:
								print("Unknown key", progressKey)
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
