import Foundation

struct CloudContainer {
	static let url: URL? = {
		guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
			return nil
		}
		if !FileManager.default.fileExists(atPath: url.path) {
			do {
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print(error.localizedDescription)
			}
		}
//		FileManager.default.createFile(atPath: url.appendingPathComponent(".placeholder").path, contents: Data()) //SAMPLE
		return url
	}()

	static var contents: [URL]? {
		guard let url = url else {
			return nil
		}
		do {
			return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.producesRelativePathURLs, .skipsHiddenFiles])
		} catch {
			print(error.localizedDescription)
			return []
		}
	}
}
