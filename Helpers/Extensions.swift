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

extension CGFloat {
	func magnitude(between value: Self) -> Self {
		return distance(to: value).magnitude
	}
}

extension Optional where Wrapped == FloatingPointSign {
	var sign: Int {
		switch self {
		case .plus:
			return 1
		case .minus:
			return -1
		case .none:
			return 0
		}
	}
}

extension FloatingPointSign {
	var sign: Int {
		switch self {
		case .plus:
			return 1
		case .minus:
			return -1
		}
	}
}
