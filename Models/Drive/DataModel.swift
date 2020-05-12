import SwiftUI

extension NSUbiquitousKeyValueStore {
	static let savedWorkIDKey = "savedWorkID"
}

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var worksProgress: [WorkProgress]? = []

	@Published var reading: WorkProgress? = nil {
		didSet {
			if reading != oldValue {
				NSUbiquitousKeyValueStore.default.set(reading?.work.id, forKey: NSUbiquitousKeyValueStore.savedWorkIDKey)
				objectWillChange.send()
			}
		}
	}

	func getWorkProgress(by id: String?) -> WorkProgress? {
		if let id = id, let worksProgress = worksProgress {
			for progress in worksProgress {
				if progress.work.id == id {
					return progress
				}
			}
		}
		return nil
	}

	func update() {
		worksProgress = CloudContainer.contents?
			.compactMap { Work($0) }
			.map { WorkProgress($0) }
		if let worksProgress = worksProgress, let savedWorkID = NSUbiquitousKeyValueStore.default.string(forKey: NSUbiquitousKeyValueStore.savedWorkIDKey) {
			reading = worksProgress.first { $0.work.id == savedWorkID }
		}
	}

	func markAsUpdated() {
		objectWillChange.send()
	}
}
