import Combine
import Foundation

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named)"
}

final class WorkProgress: ObservableObject {
	private let work: Work

	private func save(value: Any?, name: String = #function) {
		let key = getKey(for: work.id, named: name)
		UserDefaults.standard.set(value, forKey: key)
		NSUbiquitousKeyValueStore.default.set(value, forKey: key)
	}

	@Published var volume: Int {
		didSet {
			save(value: volume)
			page = 1
			work.volumes[safe: oldValue]?.cache(false)
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

	@Published var magnification: Float {
		didSet {
			save(value: magnification)
		}
	}

	init(_ work: Work) {
		let id = work.id
		self.work = work
		self.volume = UserDefaults.standard.integer(forKey: getKey(for: id, named: "volume"))
		self.page = UserDefaults.standard.integer(forKey: getKey(for: id, named: "page"))
		self.rating = UserDefaults.standard.integer(forKey: getKey(for: id, named: "rating"))
		let magnification = UserDefaults.standard.float(forKey: getKey(for: id, named: "magnification"))
		self.magnification = magnification > 0 ? magnification : 1
	}

	var currentVolume: Volume {
		work.volumes[volume - 1]
	}
}
