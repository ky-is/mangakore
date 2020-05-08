import Foundation

extension Collection {
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension URL {
	func cache(_ enable: Bool) {
		let method = enable ? FileManager.default.startDownloadingUbiquitousItem : FileManager.default.evictUbiquitousItem
		try? method(self)
	}
}

extension ClosedRange {
	func clamp(_ value: Bound) -> Bound {
		return Swift.min(upperBound, Swift.max(lowerBound, value))
	}
}
