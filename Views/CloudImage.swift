import Combine
import SwiftUI

private enum CloudImageStatus {
	case loading, success, error
}

private func getStatus(_ url: URL) -> CloudImageStatus {
	do {
		let resources = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemDownloadingErrorKey, .ubiquitousItemIsDownloadingKey, .ubiquitousItemDownloadRequestedKey])
		if let status = resources.ubiquitousItemDownloadingStatus {
			switch status {
			case .current:
				if resources.ubiquitousItemIsDownloading == false {
					return .success
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
		return .error
	}
	return .loading
}

struct CloudImage: View {
	let url: URL?
	let width: CGFloat
	let height: CGFloat
	let contentMode: ContentMode

	@State private var status: CloudImageStatus

	init(_ url: URL?, width: CGFloat, height: CGFloat, contentMode: ContentMode) {
		let initialStatus: CloudImageStatus
		if let url = url {
			let inCloud = url.lastPathComponent.hasSuffix(".icloud")
			if inCloud {
				let imageFileName = String(url.lastPathComponent.dropFirst().dropLast(7))
				self.url = url.deletingLastPathComponent().appendingPathComponent(imageFileName)
				initialStatus = .loading
				try? FileManager.default.startDownloadingUbiquitousItem(at: url)
			} else {
				self.url = url
				initialStatus = getStatus(url)
			}
		} else {
			self.url = url
			initialStatus = .error
		}
		self.width = width
		self.height = height
		self.contentMode = contentMode
		self._status = State(initialValue: initialStatus)
	}

	var body: some View {
		Group {
			if status == .success {
				Image(uiImage: UIImage(contentsOfFile: url!.path)!)
					.resizable()
					.aspectRatio(contentMode: contentMode)
					.frame(width: width, height: height)
					.clipped()
			} else if status == .loading {
				LoadingCloudImage(status: status, width: width, height: height) { _ in
					if let url = self.url {
						self.status = getStatus(url)
					}
				}
			} else if status == .error {
				InvalidCloudImage(status: status, width: width, height: height)
			}
		}
	}
}

private struct LoadingCloudImage: View {
	let status: CloudImageStatus
	let width: CGFloat
	let height: CGFloat
	private let timer = Timer.publish(every: 0.1, on: RunLoop.main, in: .default).autoconnect()
	let callback: (Any) -> Void

	var body: some View {
		InvalidCloudImage(status: status, width: width, height: height)
			.onReceive(timer, perform: callback)
	}
}

private struct InvalidCloudImage: View {
	let status: CloudImageStatus
	let width: CGFloat
	let height: CGFloat

	var body: some View {
		Text(status == .error ? "✕" : "？")
			.font(.largeTitle)
			.frame(width: width, height: height)
			.background(Color.gray)
	}
}

struct CloudImage_Previews: PreviewProvider {
	static var previews: some View {
		let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!
		return WorkIcon(sampleWork)
	}
}
