import SwiftUI

struct Volume {
	let images: [URL]

	init(_ urls: [URL]) {
		let imageExtensions = [".png", ".jpg", ".jpeg"]
		images = urls
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
}

struct Work: Identifiable {
	let id: String
	let icon: URL?
	let volumes: [Volume]

	init?(_ url: URL) {
		guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
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
			volumes = [Volume(contents)]
		} else {
			volumes = childDirectories.compactMap { url in
				guard let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
					return nil
				}
				return Volume(children)
			}
		}
		self.id = url.lastPathComponent
		self.volumes = volumes.compactMap { $0 }
		self.icon = self.volumes.first?.images.first
		if let icon = self.icon {
			try? FileManager.default.startDownloadingUbiquitousItem(at: icon)
//			try? FileManager.default.evictUbiquitousItem(at: icon) //SAMPLE
		}
	}
}

final class DataModel: ObservableObject {
	static let shared = DataModel()

	@Published var works: [Work]? = []

	func update() {
		works = CloudContainer.contents?.compactMap { Work($0) }
	}
}
