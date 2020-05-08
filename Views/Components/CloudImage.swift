import Combine
import SwiftUI

private enum CloudImageStatus {
	case loading, success, error
}

private func getStatus(of url: URL?) -> CloudImageStatus {
	guard let url = url else {
		return .error
	}
	do {
		let resources = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .ubiquitousItemDownloadRequestedKey])
		if let status = resources.ubiquitousItemDownloadingStatus {
			switch status {
			case .current:
				if resources.ubiquitousItemIsDownloading == false {
					return .success
				}
			case .notDownloaded:
				if resources.ubiquitousItemDownloadRequested == false {
					url.cache(true)
				}
			default:
				break
			}
		}
	} catch {
		print("getStatus", error.localizedDescription)
		return .error
	}
	return .loading
}

struct CloudImage: View {
	let url: URL?
	let width: CGFloat
	let height: CGFloat
	let contentMode: ContentMode

	@State private var status: CloudImageStatus = .loading

	init(_ url: URL?, width: CGFloat, height: CGFloat, contentMode: ContentMode) {
		if let url = url, url.lastPathComponent.hasSuffix(".icloud") {
			let imageFileName = String(url.lastPathComponent.dropFirst().dropLast(7))
			self.url = url.deletingLastPathComponent().appendingPathComponent(imageFileName)
		} else {
			self.url = url
		}
		self.width = width
		self.height = height
		self.contentMode = contentMode
	}

	var body: some View {
		let status = getStatus(of: url)
		if status != self.status { //TODO investigate why this happens
//			print("Mismatch", status, self.status)
		}
		return Group {
			if status == .success {
				Image(uiImage: UIImage(contentsOfFile: url!.path)!)
					.resizable()
					.aspectRatio(contentMode: contentMode)
					.frame(width: width, height: height)
					.clipped()
			} else if status == .loading {
				LoadingCloudImage(status: status, width: width, height: height) { _ in
					self.status = getStatus(of: self.url)
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
		Text(status == .error ? "✕" : "⋯")
			.font(.largeTitle)
			.frame(width: width, height: height)
	}
}

struct CloudImage_Previews: PreviewProvider {
	static var previews: some View {
		let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!
		return WorkIcon(sampleWork)
	}
}
