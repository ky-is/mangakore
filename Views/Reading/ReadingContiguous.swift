import SwiftUI

struct ReadingContiguous: View {
	let pageURLs: [URL]
	@ObservedObject var progress: WorkProgress

	let screenWidth: CGFloat
	let screenHeight: CGFloat
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
		self.screenWidth = geometry.size.width
		self.screenHeight = geometry.size.height
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
		let page0Height = page0Data.image?.height(scaledWidth: screenWidth) ?? screenHeight
		let scrollOffset = savedOffset + dragOffset + internalOffset - page0Height
		let isFirstPage = progress.page == 1
		let isLastPage = progress.page == progress.currentVolume.pageCount
		return VStack(spacing: 0) {
			if isFirstPage {
				AdvancePage(label: progress.volume > 1 ? "前章" : "未読", alignment: .bottom, height: screenHeight)
			} else {
				CloudImage(page0Data, contentMode: .fill, defaultHeight: screenHeight)
			}
			CloudImage(page1Data, contentMode: .fill, defaultHeight: screenHeight)
			if !isLastPage {
				CloudImage(page2Data, contentMode: .fill, defaultHeight: screenHeight)
			} else {
				AdvancePage(label: progress.volume < progress.work.volumes.count ? "次章" : "読破", alignment: .top, height: screenHeight)
			}
		}
			.offset(y: scrollOffset)
			.frame(width: screenWidth, height: screenHeight, alignment: .top)
			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 1)
					.updating($dragOffset) { value, state, transaction in
						state = self.getScroll(from: value.translation)
					}
					.onEnded { value in
						let newOffset = self.getScroll(from: value.translation)
						self.savedOffset += newOffset
						let distance = -(scrollOffset + newOffset) - self.screenHeight
						if newOffset > 0 { // Scrolled up
							let willAdvanceVolume = isFirstPage
							let threshold = willAdvanceVolume ? -self.screenHeight / 2 : self.screenHeight / 2
							if distance < threshold {
								self.progress.advancePage(forward: false)
								if !willAdvanceVolume {
									self.internalOffset -= page0Height
									self.updatePages(update: true)
								}
							}
						} else { // Scrolled down
							if let page1Height = self.page1Data.image?.height(scaledWidth: self.screenWidth) {
								let willAdvanceVolume = isLastPage
								let threshold = (willAdvanceVolume ? page0Height - self.screenHeight / 2 : page0Height) + page1Height / 2
								if distance > threshold {
									self.progress.advancePage(forward: true)
									if !willAdvanceVolume {
										self.internalOffset += page1Height
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

private struct AdvancePage: View {
	let label: String
	let alignment: Alignment
	let height: CGFloat

	var body: some View {
		ZStack {
			Text(label)
				.font(Font.title.bold())
				.frame(height: height / 2, alignment: alignment)
		}
			.frame(height: height)
	}
}

struct ReadingContiguous_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return GeometryReader { geometry in
			ReadingContiguous(pages: [], progress: WorkProgress(work), geometry: geometry, hasInteracted: .constant(false))
		}
	}
}
