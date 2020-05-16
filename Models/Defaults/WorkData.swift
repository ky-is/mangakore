import Combine
import Foundation
import ImageIO

private let maximumTimePerPage: TimeInterval = 60

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named.first!)"
}

private func sync(_ id: String, value: Any?, name: String = #function) {
	let key = getKey(for: id, named: name)
	NSUbiquitousKeyValueStore.default.set(value, forKey: key)
}

final class WorkSettings: ObservableObject {
	let id: String
	let imageURL: URL?

	@Published var rating: Int {
		didSet {
			guard rating != oldValue else {
				return
			}
			sync(id, value: rating)
		}
	}

	private var _contiguous: Bool?
	var contiguous: Bool {
		get {
			if let contiguous = _contiguous {
				return contiguous
			}
			guard let url = imageURL else {
				print("No pages", id)
				return false
			}
			guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
				print("No image source", id)
				return false
			}
			guard let properties = CGImageSourceCopyPropertiesAtIndex(source, .zero, nil) as? [CFString: Any] else {
				print("No image properties", id, source)
				return false
			}
			guard let width = properties[kCGImagePropertyPixelWidth] as? Int, let height = properties[kCGImagePropertyPixelHeight] as? Int else {
				print("No image pixel data", id, properties)
				return false
			}
			let isContinuous = height > width * 2
			_contiguous = isContinuous
			sync(id, value: isContinuous)
			return isContinuous
		}
		set {
			_contiguous = newValue
			objectWillChange.send()
			sync(id, value: newValue)
		}
	}

	@Published var magnification: Double

	init(id: String, volumes: [Volume]) {
		let id = id
		self.id = id
		self.imageURL = volumes.first?.images.first
		let store = NSUbiquitousKeyValueStore.default
		self.rating = store.integer(forKey: getKey(for: id, named: "rating"))
		let magnification = store.double(forKey: getKey(for: id, named: "magnification"))
		self.magnification = magnification > 0 ? magnification : 1
		self._contiguous = store.object(forKey: getKey(for: id, named: "contiguous")) as? Bool
	}
}

final class WorkProgress: ObservableObject {
	let id: String
	private let volumes: [Volume]

	@Published var volume: Int {
		didSet {
			guard volume != oldValue else {
				return
			}
			sync(id, value: volume)
			page = 1
			volumes[safe: oldValue]?.cache(false)
		}
	}

	@Published var page: Int {
		didSet {
			guard page != oldValue else {
				return
			}
			if startedReadingAt > 0 { //TODO
				saveReadingTime(continuing: true)
			}
			sync(id, value: page)
		}
	}

	var startedReadingAt: TimeInterval = .zero
	func startReading() {
		startedReadingAt = CFAbsoluteTimeGetCurrent()
	}
	func saveReadingTime(continuing: Bool) {
		guard startedReadingAt > 0 else {
			return print("Reading not started")
		}
		let currentTime = CFAbsoluteTimeGetCurrent()
		let pageTime = min(maximumTimePerPage, currentTime - startedReadingAt)
		timeReading = timeReading + pageTime
		startedReadingAt = continuing ? currentTime : 0
	}
	@Published var timeReading: TimeInterval {
		didSet {
			sync(id, value: timeReading)
		}
	}

	func advancePage(forward: Bool) { //TODO += 1 didSet not called
		if forward {
			if page < currentVolume.pageCount {
				page = page + 1
			} else if volume < volumes.count {
				volume = volume + 1
			} else {
				DataModel.shared.readingID = nil
			}
		} else {
			if page > 1 {
				page = page - 1
			} else if volume > 1 {
				volume = volume - 1
				page = currentVolume.pageCount
			} else {
				DataModel.shared.readingID = nil
				volume = 0
				page = 0
			}
		}
	}

	init(id: String, volumes: [Volume]) {
		let id = id
		self.id = id
		self.volumes = volumes
		let store = NSUbiquitousKeyValueStore.default
		self.volume = store.integer(forKey: getKey(for: id, named: "volume"))
		self.page = store.integer(forKey: getKey(for: id, named: "page"))
		self.timeReading = store.double(forKey: getKey(for: id, named: "timeReading"))
	}

	var started: Bool {
		volume > 1 || page > 1
	}
	var finished: Bool {
		volume >= volumes.count && page >= (volumes.last?.pageCount ?? 0)
	}

	var currentVolume: Volume {
		volumes[max(0, volume - 1)]
	}

	var isFirstPage: Bool {
		page == 1
	}
	var isLastPage: Bool {
		page == currentVolume.pageCount
	}
}
