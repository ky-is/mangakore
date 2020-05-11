import Foundation
import UIKit

extension Collection {
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}

	subscript(suffix suffixIndex: Int) -> Element {
		let resultIndex = index(endIndex, offsetBy: -suffixIndex - 1)
		return self[resultIndex]
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

extension NSUbiquitousKeyValueStore {
	func integer(forKey key: String) -> Int {
		return Int(longLong(forKey: key))
	}
}

extension UIImage {
	func height(scaledWidth: CGFloat) -> CGFloat {
		return size.height * (scaledWidth / size.width)
	}
}
