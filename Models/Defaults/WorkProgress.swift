import Combine
import Foundation

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named)"
}

final class WorkProgress: ObservableObject {
	private let id: String

	private func update(value: Any, name: String = #function) {
		let key = getKey(for: id, named: name)
		UserDefaults.standard.set(value, forKey: key)
		NSUbiquitousKeyValueStore.default.set(value, forKey: key)
	}

	@Published var volume: Int {
		didSet {
			update(value: volume)
			page = 1
		}
	}
	@Published var page: Int {
		didSet {
			update(value: page)
		}
	}

	@Published var rating: Int {
		didSet {
			update(value: rating)
		}
	}


	init(_ work: Work) {
		let id = work.id
		self.id = id
		volume = UserDefaults.standard.integer(forKey: getKey(for: id, named: "volume"))
		page = UserDefaults.standard.integer(forKey: getKey(for: id, named: "page"))
		rating = UserDefaults.standard.integer(forKey: getKey(for: id, named: "rating"))
	}
}
