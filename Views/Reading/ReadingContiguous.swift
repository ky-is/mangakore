import SwiftUI

struct ReadingContiguous: View {
	let pageURLs: [URL]
	@ObservedObject var progress: WorkProgress

	let screenWidth: CGFloat
	let screenHeight: CGFloat
	@Binding var hasInteracted: Bool

	@State private var savedOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat?
	@GestureState private var isDragPanning = false

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
		page2Data.updateURL(pageURLs[safe: pageIndex + 1], priority: false)
		if update && !hasInteracted {
			hasInteracted = true
			withAnimation {
				UserSettings.shared.showUI = false
			}
		}
	}

	private func getScroll(from drag: DragGesture.Value) -> CGFloat {
		return drag.translation.height * 3
	}

	private func getScrollOffset() -> CGFloat {
		return savedOffset + (dragOffset ?? 0)
	}

	var body: some View {
		let page0Height = page0Data.image?.height(scaledWidth: screenWidth) ?? screenHeight
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
			.offset(y: getScrollOffset() - page0Height)
			.frame(width: screenWidth, height: screenHeight, alignment: .top)
			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 0)
					.updating($dragOffset) { drag, dragOffset, transaction in
						let newOffset = self.getScroll(from: drag)
						dragOffset = newOffset
					}
					.updating($isDragPanning) { drag, isDragPanning, transaction in
						if !isDragPanning && abs(drag.predictedEndTranslation.height) > 15 {
							isDragPanning = true
						}
					}
					.onEnded { drag in
						let newOffset = self.getScroll(from: drag)
						self.addScroll(offset: newOffset, page0Height: page0Height, isFirstPage: isFirstPage, isLastPage: isLastPage)
					}
			)
			.overlay(
				Group {
					if dragOffset != nil && !isDragPanning {
						ActiveScrolling(scrollOffset: $savedOffset, onScroll: onScroll(direction:))
					}
				}
			)
			.onReceive(progress.$volume) { _ in
				self.savedOffset = 0
			}
	}

	private func onScroll(direction: CGFloat) {
		let page0Height = page0Data.image?.height(scaledWidth: screenWidth) ?? screenHeight
		let isFirstPage = progress.page == 1
		let isLastPage = progress.page == progress.currentVolume.pageCount
		addScroll(offset: -direction, page0Height: page0Height, isFirstPage: isFirstPage, isLastPage: isLastPage)
	}

	private func addScroll(offset: CGFloat, page0Height: CGFloat, isFirstPage: Bool, isLastPage: Bool) {
		savedOffset += offset
		guard let page1Height = self.page1Data.image?.height(scaledWidth: screenWidth) else {
			return
		}
		let distance = -getScrollOffset()
		if offset > 0 { // Scrolled up
			let willAdvanceVolume = isFirstPage
			let threshold = -page0Height / 2
			if distance < threshold {
				progress.advancePage(forward: false)
				if !willAdvanceVolume {
					savedOffset -= page0Height
					updatePages(update: true)
				}
			}
		} else { // Scrolled down
			let willAdvanceVolume = isLastPage
			let threshold = willAdvanceVolume ? page1Height - screenHeight / 2 : page1Height / 2
			if distance > threshold {
				progress.advancePage(forward: true)
				if !willAdvanceVolume {
					savedOffset += page1Height
					updatePages(update: true)
				}
			}
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

private struct ActiveScrolling: View {
	@Binding var scrollOffset: CGFloat
	let onScroll: (CGFloat) -> Void

	private let timer = Timer.publish(every: 0, on: .main, in: .default).autoconnect()

	var body: some View {
		Rectangle()
			.hidden()
			.onReceive(timer) { _ in
				self.onScroll(0.1)
			}
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
