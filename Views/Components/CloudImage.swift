import Combine
import SwiftUI

struct CloudImage: View {
	let contentMode: ContentMode
	let defaultHeight: CGFloat?

	@ObservedObject private var data: Data

	init(_ data: Data, contentMode: ContentMode, defaultHeight: CGFloat? = nil) {
		self.data = data
		self.defaultHeight = defaultHeight
		self.contentMode = contentMode
	}

	init(_ url: URL?, priority: Bool, contentMode: ContentMode, defaultHeight: CGFloat? = nil) {
		self.contentMode = contentMode
		self.defaultHeight = defaultHeight
		self.data = Data(for: url, priority: priority)
	}

	var body: some View {
		Group {
			if data.image != nil {
				Image(uiImage: data.image!)
					.resizable()
					.aspectRatio(contentMode: contentMode)
			} else if data.status == .error {
				CloudImageInvalid(status: data.status, defaultHeight: defaultHeight)
			} else {
				CloudImageLoading(status: data.status, defaultHeight: defaultHeight) { _ in
					self.data.updateStatus()
				}
			}
		}
	}
}

extension CloudImage {
	enum Status {
		case downloading, reading, success, error
	}

	final class Data: ObservableObject {
		let url: URL?
		@Published var status: Status = .reading
		@Published var image: UIImage? = nil

		func updateStatus() {
			DispatchQueue.global(qos: .userInteractive).async {
				let status = self.getStatus()
				let image = status == .success || status == .downloading ? UIImage(contentsOfFile: self.url!.path) : nil
				DispatchQueue.main.async {
					self.status = status
					self.image = image
				}
			}
		}

		private func getStatus() -> Status {
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
						return .downloading
					default:
						break
					}
				}
			} catch {
				print("getStatus", error.localizedDescription)
				return .error
			}
			return .reading
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
					if url != nil {
						self.image = UIImage(contentsOfFile: url!.path)
					}
				}
			}
		}
	}
}

private struct CloudImageLoading: View {
	let status: CloudImage.Status
	let defaultHeight: CGFloat?
	let callback: (Any) -> Void

	private let timer = Timer.publish(every: 0.1, on: RunLoop.main, in: .default).autoconnect()

	var body: some View {
		CloudImageInvalid(status: status, defaultHeight: defaultHeight)
			.onReceive(timer, perform: callback)
	}
}

private struct CloudImageInvalid: View {
	let status: CloudImage.Status
	let defaultHeight: CGFloat?

	var body: some View {
		Text(status == .downloading ? "☁️" : (status == .error ? "❌" : "⋯"))
			.font(.largeTitle)
			.frame(maxWidth: .infinity, maxHeight: defaultHeight ?? .infinity)
	}
}

struct CloudImage_Previews: PreviewProvider {
	static var previews: some View {
		CloudImage(nil, priority: true, contentMode: .fit)
	}
}
