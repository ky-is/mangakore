import Combine
import SwiftUI

private enum CloudImageStatus {
	case loading, success, error
}

private func loadImage(_ url: URL) -> UIImage? {
	do {
		let resources = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemDownloadingErrorKey, .ubiquitousItemIsDownloadingKey, .ubiquitousItemDownloadRequestedKey])
		if let status = resources.ubiquitousItemDownloadingStatus {
			switch status {
			case .current:
				if resources.ubiquitousItemIsDownloading == false {
					return UIImage(contentsOfFile: url.path)
				}
			case .notDownloaded:
				if resources.ubiquitousItemDownloadRequested == false {
					try? FileManager.default.startDownloadingUbiquitousItem(at: url)
				}
			default:
				break
			}
		}
	} catch {
		print("resourceValues", error.localizedDescription)
	}
	return nil
}

struct CloudImage: View {
	let url: URL?
	let size: CGFloat

	@State private var image: UIImage?
	@State private var status: CloudImageStatus

	init(_ url: URL?, size: CGFloat = 128) {
		let initialStatus: CloudImageStatus
		let image: UIImage?
		if let url = url {
			let inCloud = url.lastPathComponent.hasSuffix(".icloud")
			if inCloud {
				let imageFileName = String(url.lastPathComponent.dropFirst().dropLast(6))
				self.url = url.deletingLastPathComponent().appendingPathComponent(imageFileName)
				image = nil
				initialStatus = .loading
				try? FileManager.default.startDownloadingUbiquitousItem(at: url)
			} else {
				self.url = url
				image = loadImage(url)
				initialStatus = image != nil ? .success : .loading
			}
		} else {
			self.url = url
			image = nil
			initialStatus = .error
		}
		self.size = size
		self._image = State(initialValue: image)
		self._status = State(initialValue: initialStatus)
	}

	var body: some View {
		Group {
			if status == .success {
				Image(uiImage: image!)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: size, height: size)
					.clipped()
			} else if status == .loading {
				LoadingCloudImage(status: status, size: size) { _ in
					if let url = self.url, let image = loadImage(url) {
						self.image = image
						self.status = .success
					}
				}
			} else if status == .error {
				InvalidCloudImage(status: status, size: size)
			}
		}
	}
}

private struct LoadingCloudImage: View {
	let status: CloudImageStatus
	let size: CGFloat
	private let timer = Timer.publish(every: 0.1, on: RunLoop.main, in: .default).autoconnect()
	let callback: (Any) -> Void

	var body: some View {
		InvalidCloudImage(status: status, size: size)
			.onReceive(timer, perform: callback)
	}
}

private struct InvalidCloudImage: View {
	let status: CloudImageStatus
	let size: CGFloat

	var body: some View {
		Text(status == .error ? "✕" : "？")
			.font(.largeTitle)
			.frame(width: size, height: size)
			.background(Color.gray)
	}
}

struct CloudImage_Previews: PreviewProvider {
	static var previews: some View {
		let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!
		return WorkIcon(sampleWork)
	}
}
