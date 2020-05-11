import SwiftUI

private let savedWorkIDKey = "savedWorkID"

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var worksProgress: [WorkProgress]? = []

	@Published var reading: WorkProgress? = nil {
		didSet {
			NSUbiquitousKeyValueStore.default.set(reading?.work.id, forKey: savedWorkIDKey)
			objectWillChange.send()
		}
	}

	func update() {
		worksProgress = CloudContainer.contents?
			.compactMap { Work($0) }
			.map { WorkProgress($0) }
		if let worksProgress = worksProgress, let savedWorkID = NSUbiquitousKeyValueStore.default.string(forKey: savedWorkIDKey) {
			reading = worksProgress.first { $0.work.id == savedWorkID }
		}
	}

	func markAsUpdated() {
		objectWillChange.send()
	}
}
