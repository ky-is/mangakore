import SwiftUI

struct ReadingContiguous: View {
	let pageURLs: [URL]
	@ObservedObject var progress: WorkProgress
	let geometry: GeometryProxy
	@Binding var hasInteracted: Bool

	@State private var savedOffset: CGFloat = 0
	@State private var internalOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat = 0

	@ObservedObject private var page0Data = CloudImage.Data()
	@ObservedObject private var page1Data = CloudImage.Data()
	@ObservedObject private var page2Data = CloudImage.Data()

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy, hasInteracted: Binding<Bool>) {
		self.pageURLs = pages
		self.progress = progress
		self.geometry = geometry
		self._hasInteracted = hasInteracted
		updatePages(update: false)
		progress.currentVolume.cache(true)
	}

	private func updatePages(update: Bool) {
		let pageIndex = max(1, progress.page) - 1
		let previousPageURL = pageURLs[safe: pageIndex - 1]
		page0Data.updateURL(previousPageURL, priority: true)
		page1Data.updateURL(pageURLs[safe: pageIndex + 0], priority: true)
		page2Data.updateURL(pageURLs[safe: pageIndex + 1], priority: true)
		if update && !hasInteracted {
			hasInteracted = true
			UserSettings.shared.showUI = false
		}
	}

	private func getScroll(from size: CGSize) -> CGFloat {
		return size.height * 3
	}

	var body: some View {
		let initialOffset = page0Data.url == nil ? -geometry.size.height : 0
		let screenHeight = geometry.size.height
		return VStack(spacing: 0) {
			CloudImage(page0Data, contentMode: .fill, defaultHeight: screenHeight)
			CloudImage(page1Data, contentMode: .fill, defaultHeight: screenHeight)
			if page2Data.url != nil {
				CloudImage(page2Data, contentMode: .fill, defaultHeight: screenHeight)
			} else {
				Button(action: {
					self.progress.volume = self.progress.volume + 1 //TODO += 1 didSet not called
				}) {
					Text("次章")
						.font(Font.title.bold())
				}
					.frame(width: geometry.size.width, height: screenHeight / 2)
			}
		}
			.offset(y: savedOffset + dragOffset + initialOffset + internalOffset)
			.frame(width: geometry.size.width, height: screenHeight, alignment: .top)
			.contentShape(Rectangle())
			.gesture(
				DragGesture()
					.updating($dragOffset) { value, state, transaction in
						state = self.getScroll(from: value.translation)
					}
					.onEnded { value in
						let newOffset = self.getScroll(from: value.translation)
						self.savedOffset += newOffset
						let distance = -(self.savedOffset + self.dragOffset + initialOffset + self.internalOffset)
						if newOffset > 0 { // Scrolled up
							let willAdvanceVolume = self.progress.page <= 1
							let threshold = willAdvanceVolume ? screenHeight / 2 : screenHeight
							if distance < threshold {
								self.progress.advancePage(forward: false)
								if willAdvanceVolume {
//									self.internalOffset = 0
								} else {
									self.updatePages(update: true)
									if let newPage0Height = self.page0Data.image?.height(scaledWidth: self.geometry.size.width) {
										self.internalOffset -= newPage0Height
									}
								}
							}
						} else { // Scrolled down
							if let page1Height = self.page1Data.image?.height(scaledWidth: self.geometry.size.width) {
								let page0Height = self.page0Data.image?.height(scaledWidth: self.geometry.size.width) ?? screenHeight
								let willAdvanceVolume = self.progress.page >= self.progress.currentVolume.pageCount
								let threshold = page0Height + (willAdvanceVolume ? page1Height - screenHeight / 2 : page1Height / 2)
								if distance > threshold {
									self.progress.advancePage(forward: true)
									if !willAdvanceVolume {
										self.internalOffset += page0Height + initialOffset
										self.updatePages(update: true)
									}
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
