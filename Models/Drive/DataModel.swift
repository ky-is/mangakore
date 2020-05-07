import SwiftUI

struct Volume {
	let root: URL
	let images: [URL]

	init(_ root: URL, urls: [URL]) {
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
	}

	func cache(_ enable: Bool) {
		root.cache(enable)
	}
}

struct Work: Identifiable {
	let id: String
	let root: URL
	let icon: URL?
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
		let volumes: [Volume?]
		if childDirectories.isEmpty {
			volumes = [Volume(root, urls: contents)]
		} else {
			volumes = childDirectories
				.sorted { a, b in a.lastPathComponent.compare(b.lastPathComponent) == .orderedAscending }
				.compactMap { url in
					guard let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
						return nil
					}
					return Volume(url, urls: children)
				}
		}
		self.id = root.lastPathComponent
		self.root = root
		self.volumes = volumes.compactMap { $0 }
		self.icon = self.volumes.first?.images.first
		self.icon?.cache(true) //SAMPLE false
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
