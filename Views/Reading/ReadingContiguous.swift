import SwiftUI

struct ReadingContiguous: View {
	let pageURLs: [URL]
	@ObservedObject var progress: WorkProgress
	let geometry: GeometryProxy

	@State private var savedOffset: CGFloat = 0
	@State private var internalOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat = 0

	@ObservedObject private var page0Data = CloudImage.Data()
	@ObservedObject private var page1Data = CloudImage.Data()
	@ObservedObject private var page2Data = CloudImage.Data()

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy) {
		self.pageURLs = pages
		self.progress = progress
		self.geometry = geometry
		updatePages()
		progress.currentVolume.cache(true)
	}

	private func updatePages() {
		let pageIndex = max(1, progress.page) - 1
		let previousPageURL = pageURLs[safe: pageIndex - 1]
		page0Data.updateURL(previousPageURL, priority: true)
		page1Data.updateURL(pageURLs[safe: pageIndex + 0], priority: true)
		page2Data.updateURL(pageURLs[safe: pageIndex + 1], priority: true)
	}

	private func getScroll(from size: CGSize) -> CGFloat {
		return size.height * 2
	}

	var body: some View {
		let initialOffset = page0Data.url == nil ? -geometry.size.height : 0
		return VStack(spacing: 0) {
			CloudImage(page0Data, contentMode: .fill, defaultHeight: geometry.size.height)
			CloudImage(page1Data, contentMode: .fill, defaultHeight: geometry.size.height)
			if page2Data.url != nil {
				CloudImage(page2Data, contentMode: .fill, defaultHeight: geometry.size.height)
			} else {
				Button(action: {
					self.progress.volume = self.progress.volume + 1 //TODO += 1 didSet not called
				}) {
					Text("次章")
						.font(Font.title.bold())
				}
					.frame(width: geometry.size.width, height: geometry.size.height / 2)
			}
		}
			.offset(y: savedOffset + dragOffset + initialOffset + internalOffset)
			.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
			.contentShape(Rectangle())
			.gesture(
				DragGesture()
					.updating($dragOffset) { value, state, transaction in
						state = self.getScroll(from: value.translation)
					}
					.onEnded { value in
						self.savedOffset += self.getScroll(from: value.translation)
						let distance = -(self.savedOffset + self.dragOffset + initialOffset + self.internalOffset)
						if distance < 0 {
							if self.progress.page > 1 {
								self.progress.page = self.progress.page - 1
								self.updatePages()
								if let newPage0Height = self.page0Data.image?.height(scaledWidth: self.geometry.size.width) {
									self.internalOffset -= newPage0Height
								}
							}
						} else if self.progress.page < self.progress.currentVolume.pageCount {
							if let page1Height = self.page1Data.image?.height(scaledWidth: self.geometry.size.width) {
								let page0Height = self.page0Data.image?.height(scaledWidth: self.geometry.size.width) ?? self.geometry.size.height
								if distance > page0Height + page1Height / 2 {
									self.progress.page = self.progress.page + 1
									self.internalOffset += page0Height + initialOffset
									self.updatePages()
								}
							}
						}
					}
			)
			.onReceive(progress.$volume) { _ in
				self.savedOffset = 0
				self.internalOffset = 0
			}
	}
}

struct ReadingContiguous_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return GeometryReader { geometry in
			ReadingPaginated(pages: [], progress: WorkProgress(work), geometry: geometry)
		}
	}
}
