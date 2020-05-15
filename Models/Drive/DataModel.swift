import SwiftUI

extension NSUbiquitousKeyValueStore {
	static let savedWorkIDKey = "savedWorkID"
}

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var works: [Work]? = []

	@Published var readingID: String? = nil {
		didSet {
			guard readingID != oldValue else {
				return
			}
			NSUbiquitousKeyValueStore.default.set(readingID, forKey: NSUbiquitousKeyValueStore.savedWorkIDKey)
//			objectWillChange.send()
		}
	}

	func getWork(by id: String?) -> Work? {
		if let id = id, let works = works {
			for work in works {
				if work.id == id {
					return work
				}
			}
		}
		return nil
	}

	func update() {
		works = CloudContainer.contents?
			.compactMap { Work($0) }
		readingID = NSUbiquitousKeyValueStore.default.string(forKey: NSUbiquitousKeyValueStore.savedWorkIDKey)
	}
}
