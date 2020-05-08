import SwiftUI

struct Volume: Identifiable, Equatable {
	let id: Int
	let root: URL
	let images: [URL]

	init(_ number: Int, root: URL, urls: [URL]) {
		self.id = number
		self.root = root
		let imageExtensions = [".png", ".jpg", ".jpeg"]
		self.images = urls
			.filter { url in
				return imageExtensions.contains { url.lastPathComponent.contains($0) }
			}
			.sorted { a, b in
				var aName = a.lastPathComponent
				var bName = b.lastPathComponent
				if aName.first == "." {
					aName = String(aName.dropFirst())
				}
				if bName.first == "." {
					bName = String(bName.dropFirst())
				}
				return aName.compare(bName) == .orderedAscending
			}
		icon?.cache(true)
	}

	var pageCount: Int {
		images.count
	}

	var icon: URL? {
		images.first
	}

	func cache(_ enable: Bool) {
		root.cache(enable)
	}
}

struct Work: Identifiable {
	let id: String
	let name: String
	let root: URL
	let volumes: [Volume]

	init?(_ root: URL) {
		guard let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
			return nil
		}
		let childDirectories = contents.filter { url in
			guard let resources = try? url.resourceValues(forKeys: [.isDirectoryKey]), let isDirectory = resources.isDirectory else {
				return false
			}
			return isDirectory
		}
		if childDirectories.isEmpty {
			self.volumes = [Volume(1, root: root, urls: contents)]
		} else {
			let directories = childDirectories
				.sorted { a, b in a.lastPathComponent.compare(b.lastPathComponent) == .orderedAscending }
			var volumesAccumulator: [Volume] = []
			var currentVolume = 1
			directories.forEach { url in
				guard let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
					return
				}
				volumesAccumulator.append(Volume(currentVolume, root: url, urls: children))
				currentVolume += 1
			}
			self.volumes = volumesAccumulator
		}
		self.id = root.lastPathComponent.lowercased().filter { !$0.isWhitespace }
		self.name = root.lastPathComponent
		self.root = root
	}

	func cache(_ enable: Bool) {
		root.cache(enable)
	}
}

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var works: [Work]? = []

	func update() {
		works = CloudContainer.contents?.compactMap { Work($0) }
	}
}
