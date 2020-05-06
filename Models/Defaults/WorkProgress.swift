import Combine
import Foundation

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named)"
}

final class WorkProgress: ObservableObject {
	private let id: String

	private func save(value: Any?, name: String = #function) {
		let key = getKey(for: id, named: name)
		UserDefaults.standard.set(value, forKey: key)
		NSUbiquitousKeyValueStore.default.set(value, forKey: key)
	}

	@Published var volume: Int {
		didSet {
			save(value: volume)
			page = 1
		}
	}
	@Published var page: Int {
		didSet {
			save(value: page)
		}
	}

	@Published var rating: Int {
		didSet {
			save(value: rating)
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
