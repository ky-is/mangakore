import Combine
import SwiftUI

struct CloudImage: View {
	let contentMode: ContentMode
	let defaultHeight: CGFloat?
	let progress: WorkProgress?
	let forward: Bool?

	@ObservedObject private var data: Data

	init(_ data: Data, contentMode: ContentMode, defaultHeight: CGFloat? = nil, progress: WorkProgress? = nil, forward: Bool = true) {
		self.data = data
		self.contentMode = contentMode
		self.defaultHeight = defaultHeight
		self.progress = progress
		self.forward = forward
	}

	init(_ url: URL?, priority: Bool, contentMode: ContentMode, defaultHeight: CGFloat? = nil) {
		self.contentMode = contentMode
		self.defaultHeight = defaultHeight
		self.data = Data(for: url, priority: priority)
		self.progress = nil
		self.forward = nil
	}

	var body: some View {
		Group {
			if progress != nil && data.url == nil {
				CloudImagePlaceholder(defaultHeight: defaultHeight, progress: progress!, forward: forward!)
			} else if data.image != nil {
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
		var url: URL?
		@Published var status: Status = .reading
		@Published var image: UIImage? = nil

		func updateStatus() {
			let startURL = url
			DispatchQueue.global(qos: .userInteractive).async {
				let status = self.getStatus()
				let image = status == .success || status == .downloading ? UIImage(contentsOfFile: self.url!.path) : nil
				DispatchQueue.main.async {
					if self.url == startURL {
						self.status = status
						self.image = image
					}
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

		init() {}

		init(for url: URL?, priority: Bool) {
			load(url, priority: priority)
		}

		func load(_ url: URL?, priority: Bool) {
			if let url = url, url.lastPathComponent.hasSuffix(".icloud") {
				let imageFileName = String(url.lastPathComponent.dropFirst().dropLast(7))
				self.url = url.deletingLastPathComponent().appendingPathComponent(imageFileName)
				self.status = .downloading
				self.image = nil
				updateStatus()
			} else {
				self.url = url
				if priority {
					self.status = getStatus()
					self.image = url != nil ? UIImage(contentsOfFile: url!.path) : nil
				} else {
					self.status = .reading
					self.image = nil
				}
			}
		}

		func assign(from source: Data) {
			url = source.url
			image = source.image
			status = source.status
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
		Image(systemName: status == .downloading ? "icloud.and.arrow.down" : (status == .error ? "exclamationmark.icloud" : "icloud"))
			.font(.largeTitle)
			.frame(maxWidth: .infinity, maxHeight: defaultHeight ?? .infinity)
	}
}

private struct CloudImagePlaceholder: View {
	let defaultHeight: CGFloat?
	let label: String

	init(defaultHeight: CGFloat?, progress: WorkProgress, forward: Bool) {
		self.defaultHeight = defaultHeight
		self.label = forward
			? (progress.isLastVolume ? "読破": "次章")
			: (progress.isFirstVolume ? "未読" : "前章")
	}

	var body: some View {
		Text(label)
			.font(.largeTitle)
			.frame(maxWidth: .infinity, maxHeight: defaultHeight ?? .infinity)
	}
}

struct CloudImage_Previews: PreviewProvider {
	static var previews: some View {
		CloudImage(nil, priority: true, contentMode: .fit)
	}
}
