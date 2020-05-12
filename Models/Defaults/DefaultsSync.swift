import Foundation

final class DefaultsSync: NSObject {
	static func observe() {
		NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: OperationQueue(), using: updateUserDefaultsFromCloud(notification:))
	}

	static func updateUserDefaultsFromCloud(notification: Notification) {
		guard let newKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
			return print(NSUbiquitousKeyValueStoreChangedKeysKey, "Invalid userInfo", notification.userInfo ?? "nil")
		}
		if let worksProgress = DataModel.shared.worksProgress {
			let cloudDefaults = NSUbiquitousKeyValueStore.default
			for key in newKeys {
				let split = key.split(separator: "｜")
				if split.count == 2 {
					let workID = split[0], progressKey = split[1]
					for workProgress in worksProgress {
						if workProgress.work.id == workID {
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
								default:
									print("Unknown key", progressKey)
								}
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
