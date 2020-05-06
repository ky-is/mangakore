import Combine
import Foundation

final class WorkProgress: ObservableObject {
	@Published var volume: Int {
		didSet {
			page = 0
		}
	}
	@Published var page: Int
	@Published var rating: Int

	init(_ work: Work) {
		volume = UserDefaults.standard.integer(forKey: "\(work.id)｜volume")
		page = UserDefaults.standard.integer(forKey: "\(work.id)｜page")
		rating = UserDefaults.standard.integer(forKey: "\(work.id)｜rating")
	}
}
