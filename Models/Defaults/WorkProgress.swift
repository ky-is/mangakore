import Combine
import Foundation
import ImageIO

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
			sync(value: page)
			DataModel.shared.markAsUpdated()
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
