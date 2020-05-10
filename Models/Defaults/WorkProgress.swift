import Combine
import Foundation

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named)"
}

final class WorkProgress: ObservableObject, Identifiable {
	let work: Work

	private func sync(value: Any?, name: String = #function) {
		let key = getKey(for: work.id, named: name)
		NSUbiquitousKeyValueStore.default.set(value, forKey: key)
	}

	@Published var volume: Int {
		didSet {
			sync(value: volume)
			page = 1
			work.volumes[safe: oldValue]?.cache(false)
		}
	}

	@Published var page: Int {
		didSet {
			sync(value: page)
		}
	}

	@Published var rating: Int {
		didSet {
			sync(value: rating)
		}
	}

	@Published var magnification: Double

	init(_ work: Work) {
		let id = work.id
		self.work = work
		self.volume = NSUbiquitousKeyValueStore.default.integer(forKey: getKey(for: id, named: "volume"))
		self.page = NSUbiquitousKeyValueStore.default.integer(forKey: getKey(for: id, named: "page"))
		self.rating = NSUbiquitousKeyValueStore.default.integer(forKey: getKey(for: id, named: "rating"))
		let magnification = NSUbiquitousKeyValueStore.default.double(forKey: getKey(for: id, named: "magnification"))
		self.magnification = magnification > 0 ? magnification : 1
	}

	var currentVolume: Volume {
		work.volumes[max(0, volume - 1)]
	}
}
