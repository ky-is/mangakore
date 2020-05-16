import SwiftUI

private var dragStartTime: Date?
private var previousVolume = 0
private var previousPage = 0

struct ReadingContiguous: View {
	let work: Work
	let geometry: GeometryProxy
	@Binding var hasInteracted: Bool

	@State private var savedOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat?
	@GestureState private var dragDirection: FloatingPointSign?

	private let page0Data = CloudImage.Data()
	private let page1Data = CloudImage.Data()
	private let page2Data = CloudImage.Data()

	init(work: Work, geometry: GeometryProxy, hasInteracted: Binding<Bool>) {
		self.work = work
		self.geometry = geometry
		self._hasInteracted = hasInteracted
		reloadPages()
	}

	private func getCurrentPageIndex() -> Int {
		return max(1, work.progress.page) - 1
	}

	private func reloadPages() {
		let pageIndex = getCurrentPageIndex()
		let pages = work.progress.currentVolume.images
		self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
		self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
		self.page2Data.load(pages[safe: pageIndex + 1], priority: false)
		previousPage = work.progress.page
		previousVolume = work.progress.volume
	}

	var body: some View {
		ReadingContiguousRenderer(work: work, page0Data: page0Data, page1Data: page1Data, page2Data: page2Data, geometry: geometry)
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
							if !self.hasInteracted {
								self.hasInteracted = true
							}
							withAnimation {
								LocalSettings.shared.showUI.toggle()
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
			.onReceive(work.progress.$volume) { _ in
				self.savedOffset = 0
				self.work.progress.currentVolume.cache(true)
			}
			.onReceive(work.progress.$page) { page in
				guard previousVolume == self.work.progress.volume, page != previousPage else {
					return //print("unchanged", previousVolume, self.work.progress.volume, previousPage, page)
				}
				let pageIndex = self.getCurrentPageIndex()
				let pages = self.work.progress.currentVolume.images
				if page == previousPage + 1 {
					if self.page1Data.image != nil {
						self.page0Data.assign(self.page1Data)
					} else {
						self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
					}
					if self.page2Data.image != nil {
						self.page1Data.assign(self.page2Data)
					} else {
						self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
					}
					self.page2Data.load(pages[safe: pageIndex + 1], priority: false)
				} else if page == previousPage - 1 {
					if self.page1Data.image != nil {
						self.page2Data.assign(self.page1Data)
					} else {
						self.page2Data.load(pages[safe: pageIndex + 1], priority: true)
					}
					if self.page0Data.image != nil {
						self.page1Data.assign(self.page0Data)
					} else {
						self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
					}
					self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
				} else {
					print("Unknown page transition", previousPage, page)
					self.reloadPages()
				}
				previousPage = page
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
			let willAdvanceVolume = work.progress.isFirstPage
			let page0Height = getPage0Height()
			let threshold = willAdvanceVolume ? -page0Height : -page0Height / 2
			if distance < threshold {
				work.progress.advancePage(forward: false)
				if !willAdvanceVolume {
					scrollToNewPage(offset: -page0Height)
				}
			}
		} else { // Scrolled down
			let willAdvanceVolume = work.progress.isLastPage
			let threshold = willAdvanceVolume ? page1Height : page1Height / 2
			if distance > threshold {
				work.progress.advancePage(forward: true)
				if !willAdvanceVolume {
					scrollToNewPage(offset: page1Height)
				}
			}
		}
	}

	private func scrollToNewPage(offset: CGFloat) {
		savedOffset += offset
		if !hasInteracted {
//			hasInteracted = true
			withAnimation {
				LocalSettings.shared.showUI = false
			}
		}
	}
}

private struct ReadingContiguousRenderer: View {
	let work: Work
	let screenHeight: CGFloat
	var page0Data: CloudImage.Data
	var page1Data: CloudImage.Data
	var page2Data: CloudImage.Data

	@ObservedObject private var progress: WorkProgress

	init(work: Work, page0Data: CloudImage.Data, page1Data: CloudImage.Data, page2Data: CloudImage.Data, geometry: GeometryProxy) {
		self.work = work
		self.progress = work.progress
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
				AdvancePage(label: progress.volume < work.volumes.count ? "次章" : "読破", alignment: .top, height: screenHeight)
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
			ReadingContiguous(work: work, geometry: geometry, hasInteracted: .constant(false))
		}
	}
}
