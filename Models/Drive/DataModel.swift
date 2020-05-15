import SwiftUI

extension NSUbiquitousKeyValueStore {
	static let savedWorkIDKey = "savedWorkID"
}

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var worksProgress: [WorkProgress]? = []

	@Published var readingID: String? = nil {
		didSet {
			guard readingID != oldValue else {
				return
			}
			NSUbiquitousKeyValueStore.default.set(readingID, forKey: NSUbiquitousKeyValueStore.savedWorkIDKey)
//			objectWillChange.send()
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
		readingID = NSUbiquitousKeyValueStore.default.string(forKey: NSUbiquitousKeyValueStore.savedWorkIDKey)
	}
}
