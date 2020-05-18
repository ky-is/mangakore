import Foundation

struct Volume: Equatable, Identifiable {
	let id: Int
	let root: URL
	let images: [URL]

	init(_ number: Int, root: URL, urls: [URL]) {
		self.id = number
		self.root = root
		let imageExtensions = [".png", ".jpg", ".jpeg"]
		self.images = urls
			.filter { url in
				return imageExtensions.contains { url.lastPathComponent.lowercased().contains($0) }
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
				return aName.caseInsensitiveCompare(bName) == .orderedAscending
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

struct Work: Equatable, Identifiable {
	static func == (lhs: Work, rhs: Work) -> Bool {
		lhs.id == rhs.id
	}

	let id: String
	let name: String
	let root: URL
	let volumes: [Volume]

	let progress: WorkProgress
	let settings: WorkSettings

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
		let volumes: [Volume]
		if childDirectories.isEmpty {
			volumes = [Volume(1, root: root, urls: contents)]
		} else {
			let directories = childDirectories
				.sorted { a, b in a.lastPathComponent.caseInsensitiveCompare(b.lastPathComponent) == .orderedAscending }
			var volumesAccumulator: [Volume] = []
			var currentVolume = 1
			directories.forEach { url in
				guard let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
					return
				}
				volumesAccumulator.append(Volume(currentVolume, root: url, urls: children))
				currentVolume += 1
			}
			volumes = volumesAccumulator
		}
		let id = String(root.lastPathComponent.lowercased().filter({ !$0.isWhitespace }).prefix(19))
		self.id = id
		self.name = root.lastPathComponent
		self.root = root
		self.volumes = volumes
		self.settings = WorkSettings(id: id, volumes: volumes)
		self.progress = WorkProgress(id: id, volumes: volumes)
	}

	func cache(_ enable: Bool) {
		root.cache(enable)
	}
}
