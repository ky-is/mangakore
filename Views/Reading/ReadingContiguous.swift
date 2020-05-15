import SwiftUI

private var dragStartTime: Date?

struct ReadingContiguous: View {
	let pages: [URL]
	let progress: WorkProgress
	let geometry: GeometryProxy
	@Binding var hasInteracted: Bool

	@State private var savedOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat?
	@GestureState private var dragDirection: FloatingPointSign?

	private let page0Data: CloudImage.Data
	private let page1Data: CloudImage.Data
	private let page2Data: CloudImage.Data

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy, hasInteracted: Binding<Bool>) {
		self.pages = pages
		self.progress = progress
		self.geometry = geometry
		self._hasInteracted = hasInteracted

		let pageIndex = max(1, progress.page) - 1
		self.page0Data = CloudImage.Data(for: pages[safe: pageIndex - 1], priority: true)
		self.page1Data = CloudImage.Data(for: pages[safe: pageIndex + 0], priority: true)
		self.page2Data = CloudImage.Data(for: pages[safe: pageIndex + 1], priority: false)
		self.progress.currentVolume.cache(true)
	}

	var body: some View {
		ReadingContiguousRenderer(pages: pages, progress: progress, page0Data: page0Data, page1Data: page1Data, page2Data: page2Data, geometry: geometry)
			.contentShape(Rectangle())
			.offset(y: getScrollDistance() - getPage0Height())
			.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
			.gesture(
				DragGesture(minimumDistance: 0)
					.updating($dragOffset) { drag, dragOffset, transaction in
						if dragStartTime == nil {
							dragStartTime = drag.time
						}
						let newOffset = self.getScroll(from: drag)
						dragOffset = newOffset
					}
					.updating($dragDirection) { drag, dragDirection, transaction in
						let newDragLocation = drag.location.y
						let totalDragDistance = newDragLocation.distance(to: drag.startLocation.y)
						if totalDragDistance >= 0 || totalDragDistance < -10 {
							dragDirection = totalDragDistance.sign
						}
					}
					.onEnded { drag in
						let newOffset = self.getScroll(from: drag)
						var interpretAsTap = false
						if let startTime = dragStartTime, newOffset.magnitude < 10 {
							let timeSinceStart = startTime.distance(to: drag.time)
							if timeSinceStart < 0.1 {
								interpretAsTap = true
							}
						}
						if interpretAsTap {
							self.hasInteracted = true
							withAnimation {
								UserSettings.shared.showUI.toggle()
							}
						} else {
							self.savedOffset += newOffset
						}
						dragStartTime = nil
					}
			)
			.overlay(
				Group {
					if dragDirection != nil {
						ActiveScrolling(scrollOffset: $savedOffset, direction: dragDirection, onScroll: onScroll(offset:))
					}
				}
			)
			.onReceive(progress.$volume) { _ in
				self.savedOffset = 0
			}
	}

	private func getScroll(from drag: DragGesture.Value) -> CGFloat {
		return drag.translation.height * 3
	}

	private func getPage0Height() -> CGFloat {
		return page0Data.image?.size.height(atWidth: geometry.size.width) ?? geometry.size.height
	}

	private func getScrollDistance() -> CGFloat {
		return savedOffset + (dragOffset ?? 0)
	}

	private func onScroll(offset: CGFloat) {
		savedOffset += offset
		guard let page1Height = self.page1Data.image?.size.height(atWidth: geometry.size.width) else {
			return
		}
		let distance = -getScrollDistance()
		if offset > 0 { // Scrolled up
			let willAdvanceVolume = progress.isFirstPage
			let page0Height = getPage0Height()
			let threshold = willAdvanceVolume ? -page0Height : -page0Height / 2
			if distance < threshold {
				progress.advancePage(forward: false)
				if !willAdvanceVolume {
					scrollToNewPage(offset: -page0Height)
				}
			}
		} else { // Scrolled down
			let willAdvanceVolume = progress.isLastPage
			let threshold = willAdvanceVolume ? page1Height : page1Height / 2
			if distance > threshold {
				progress.advancePage(forward: true)
				if !willAdvanceVolume {
					scrollToNewPage(offset: page1Height)
				}
			}
		}
	}

	private func scrollToNewPage(offset: CGFloat) {
		savedOffset += offset
		if !hasInteracted {
			hasInteracted = true
			withAnimation {
				UserSettings.shared.showUI = false
			}
		}
	}
}

private struct ReadingContiguousRenderer: View {
	let pageURLs: [URL]
	var progress: WorkProgress
	let screenHeight: CGFloat
	var page0Data: CloudImage.Data
	var page1Data: CloudImage.Data
	var page2Data: CloudImage.Data

	init(pages: [URL], progress: WorkProgress, page0Data: CloudImage.Data, page1Data: CloudImage.Data, page2Data: CloudImage.Data, geometry: GeometryProxy) {
		self.pageURLs = pages
		self.progress = progress
		self.screenHeight = geometry.size.height
		self.page0Data = page0Data
		self.page1Data = page1Data
		self.page2Data = page2Data
	}

	var body: some View {
		VStack(spacing: 0) {
			if progress.isFirstPage {
				AdvancePage(label: progress.volume > 1 ? "前章" : "未読", alignment: .bottom, height: screenHeight)
			} else {
				CloudImage(page0Data, contentMode: .fill, defaultHeight: screenHeight)
			}
			CloudImage(page1Data, contentMode: .fill, defaultHeight: screenHeight)
			if !progress.isLastPage {
				CloudImage(page2Data, contentMode: .fill, defaultHeight: screenHeight)
			} else {
				AdvancePage(label: progress.volume < progress.work.volumes.count ? "次章" : "読破", alignment: .top, height: screenHeight)
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
	let direction: FloatingPointSign?
	let onScroll: (CGFloat) -> Void

	private let timer = Timer.publish(every: 0, on: .main, in: .default).autoconnect()

	var body: some View {
		Rectangle()
			.hidden()
			.onReceive(timer) { _ in
				self.onScroll(-0.1 * CGFloat(self.direction.sign))
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
