import Combine
import SwiftUI

private enum CloudImageStatus {
	case loading, success, error
}

private final class CloudImageData: ObservableObject {
	private let url: URL?

	@Published var status: CloudImageStatus = .loading
	@Published var image: UIImage? = nil

	func updateStatus() {
		DispatchQueue.global(qos: .userInteractive).async {
			let status = self.getStatus()
			let image = status == .success ? UIImage(contentsOfFile: self.url!.path) : nil
			DispatchQueue.main.async {
				self.status = status
				self.image = image
			}
		}
	}

	private func getStatus() -> CloudImageStatus {
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

	init(for url: URL?, priority: Bool) {
		if let url = url, url.lastPathComponent.hasSuffix(".icloud") {
			let imageFileName = String(url.lastPathComponent.dropFirst().dropLast(7))
			self.url = url.deletingLastPathComponent().appendingPathComponent(imageFileName)
			updateStatus()
		} else {
			self.url = url
			if priority {
				self.status = getStatus()
				self.image = UIImage(contentsOfFile: self.url!.path)
			}
		}
	}
}

struct CloudImage: View {
	let width: CGFloat
	let height: CGFloat
	let contentMode: ContentMode
	let alignment: Alignment?

	@ObservedObject private var data: CloudImageData

	init(_ url: URL?, priority: Bool, width: CGFloat, height: CGFloat, contentMode: ContentMode, alignment: Alignment? = nil) {
		self.width = width
		self.height = height
		self.contentMode = contentMode
		self.alignment = alignment
		self.data = CloudImageData(for: url, priority: priority)
	}

	var body: some View {
		Group {
			if data.image != nil {
				Image(uiImage: data.image!)
					.resizable()
					.aspectRatio(contentMode: contentMode)
					.frame(width: width, height: height, alignment: alignment ?? .center)
					.clipped()
			} else if data.status == .error {
				InvalidCloudImage(status: data.status, width: width, height: height)
			} else {
				LoadingCloudImage(status: data.status, width: width, height: height) { _ in
					self.data.updateStatus()
				}
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
		CloudImage(nil, priority: true, width: 128, height: 128, contentMode: .fit)
	}
}
