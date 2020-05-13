import Combine
import Foundation
import ImageIO

private let maximumTimePerPage: TimeInterval = 60

private func getKey(for id: String, named: String) -> String {
	return "\(id)｜\(named.first!)"
}

final class WorkProgress: ObservableObject, Equatable, Identifiable {
	static func == (lhs: WorkProgress, rhs: WorkProgress) -> Bool {
		lhs.work == rhs.work
	}

	let work: Work

	private func sync(value: Any?, name: String = #function) {
		let key = getKey(for: work.id, named: name)
		NSUbiquitousKeyValueStore.default.set(value, forKey: key)
	}

	@Published var volume: Int {
		didSet {
			guard volume != oldValue else {
				return
			}
			sync(value: volume)
			page = 1
			work.volumes[safe: oldValue]?.cache(false)
			DataModel.shared.markAsUpdated()
		}
	}

	@Published var page: Int {
		didSet {
			guard page != oldValue else {
				return
			}
			if startedReadingAt > 0 {
				saveReadingTime(continuing: true)
			}
			sync(value: page)
			DataModel.shared.markAsUpdated()
		}
	}

	func advancePage(forward: Bool) { //TODO += 1 didSet not called
		if forward {
			if page < currentVolume.pageCount {
				page = page + 1
			} else if volume < work.volumes.count {
				volume = volume + 1
			} else {
				DataModel.shared.reading = nil
			}
		} else {
			if page > 1 {
				page = page - 1
			} else if volume > 1 {
				volume = volume - 1
			}
		}
	}

	@Published var rating: Int {
		didSet {
			guard rating != oldValue else {
				return
			}
			sync(value: rating)
		}
	}

	private var startedReadingAt: TimeInterval = .zero
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
			sync(value: timeReading)
		}
	}

	private var _contiguous: Bool?
	var contiguous: Bool {
		get {
			if let contiguous = _contiguous {
				return contiguous
			}
			guard let url = work.volumes.first?.images.first else {
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
			sync(value: isContinuous)
			return isContinuous
		}
		set {
			_contiguous = newValue
			objectWillChange.send()
			sync(value: newValue)
		}
	}

	@Published var magnification: Double

	init(_ work: Work) {
		let id = work.id
		self.work = work
		let store = NSUbiquitousKeyValueStore.default
		self.volume = store.integer(forKey: getKey(for: id, named: "volume"))
		self.page = store.integer(forKey: getKey(for: id, named: "page"))
		self.rating = store.integer(forKey: getKey(for: id, named: "rating"))
		let magnification = store.double(forKey: getKey(for: id, named: "magnification"))
		self.magnification = magnification > 0 ? magnification : 1
		self._contiguous = store.object(forKey: getKey(for: id, named: "contiguous")) as? Bool
		self.timeReading = store.double(forKey: getKey(for: id, named: "timeReading"))
	}

	var currentVolume: Volume {
		work.volumes[max(0, volume - 1)]
	}

	var startedReading: Bool {
		volume > 1 || page > 1
	}

	var finished: Bool {
		volume >= work.volumes.count && page >= (work.volumes.last?.pageCount ?? 0)
	}
}
