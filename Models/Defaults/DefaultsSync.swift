import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: OperationQueue(), using: updateUserDefaultsFromCloud(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		guard let newKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
			return print(NSUbiquitousKeyValueStoreChangedKeysKey, "Invalid userInfo", notification.userInfo ?? "nil")
		}
		let cloudDefaults = NSUbiquitousKeyValueStore.default
		for key in newKeys {
			if key == NSUbiquitousKeyValueStore.savedWorkIDKey {
				DispatchQueue.main.async {
					DataModel.shared.readingID = cloudDefaults.string(forKey: key)
				}
			} else {
				let split = key.split(separator: "｜")
				if split.count == 2 {
					let workID = String(split[0]), progressKey = split[1]
					if let workProgress = DataModel.shared.getWorkProgress(by: workID) {
						DispatchQueue.main.async {
							switch progressKey {
							case "p":
								workProgress.page = cloudDefaults.integer(forKey: key)
							case "r":
								workProgress.rating = cloudDefaults.integer(forKey: key)
							case "v":
								workProgress.volume = cloudDefaults.integer(forKey: key)
							case "c":
								workProgress.contiguous = cloudDefaults.bool(forKey: key)
							case "t":
								workProgress.timeReading = cloudDefaults.double(forKey: key)
							default:
								print("Unknown key", progressKey)
							}
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
