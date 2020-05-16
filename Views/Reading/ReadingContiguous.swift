import SwiftUI

private var dragStartTime: Date?
private var previousVolume = 0
private var previousPage = 0
private var lastScrollDate: Date?

struct ReadingContiguous: View {
	let work: Work
	let progress: WorkProgress
	let geometry: GeometryProxy

	@State private var savedOffset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat?
	@GestureState private var dragDirection: FloatingPointSign?

	private let page0Data = CloudImage.Data()
	private let page1Data = CloudImage.Data()
	private let page2Data = CloudImage.Data()

	init(work: Work, geometry: GeometryProxy) {
		self.work = work
		self.progress = work.progress
		self.geometry = geometry
		reloadPages()
	}

	private func getIndex(of page: Int) -> Int {
		return max(1, page) - 1
	}

	private func reloadPages() {
		let pageIndex = getIndex(of: progress.page)
		let pages = progress.currentVolume.images
		self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
		self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
		self.page2Data.load(pages[safe: pageIndex + 1], priority: false)
		previousPage = progress.page
		previousVolume = progress.volume
	}

	var body: some View {
		ReadingContiguousRenderer(page0Data: page0Data, page1Data: page1Data, page2Data: page2Data, isFirstVolume: progress.isFirstVolume, isLastVolume: progress.isLastVolume, isFirstPage: progress.isFirstPage, isLastPage: progress.isLastPage, geometry: geometry)
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
							let newDirection = totalDragDistance.sign
							if newDirection != dragDirection {
								dragDirection = newDirection
							}
						}
					}
					.onEnded { drag in
						lastScrollDate = nil
						let newOffset = self.getScroll(from: drag)
						var interpretAsTap = false
						if let startTime = dragStartTime, newOffset.magnitude < 10 {
							let timeSinceStart = startTime.distance(to: drag.time)
							if timeSinceStart < 0.1 {
								interpretAsTap = true
							}
						}
						if interpretAsTap {
							if !LocalSettings.shared.hasInteracted {
								LocalSettings.shared.hasInteracted = true
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
			.onReceive(progress.$page) { page in
				let changedVolume = previousVolume != self.progress.volume
				guard changedVolume || page != previousPage else {
					return //print("unchanged", previousVolume, self.progress.volume, previousPage, page)
				}
				if changedVolume {
					self.reloadPages()
					self.savedOffset = 0
					self.progress.currentVolume.cache(true)
				} else {
					let pageChange = page - previousPage
					let pageIndex = self.getIndex(of: page)
					let pages = self.progress.currentVolume.images
					if pageChange == +1 {
						if self.page1Data.image != nil {
							self.page0Data.assign(from: self.page1Data)
						} else {
							self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
						}
						if self.page2Data.image != nil {
							self.page1Data.assign(from: self.page2Data)
						} else {
							self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
						}
						self.page2Data.load(pages[safe: pageIndex + 1], priority: false)
					} else if pageChange == -1 {
						if self.page1Data.image != nil {
							self.page2Data.assign(from: self.page1Data)
						} else {
							self.page2Data.load(pages[safe: pageIndex + 1], priority: true)
						}
						if self.page0Data.image != nil {
							self.page1Data.assign(from: self.page0Data)
						} else {
							self.page1Data.load(pages[safe: pageIndex + 0], priority: true)
						}
						self.page0Data.load(pages[safe: pageIndex - 1], priority: true)
					} else {
						print("Unknown page transition", previousPage, page)
						self.reloadPages()
					}
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
		if !LocalSettings.shared.hasInteracted {
			LocalSettings.shared.hasInteracted = true
			withAnimation {
				LocalSettings.shared.showUI = false
			}
		}
	}
}

private struct ReadingContiguousRenderer: View {
	let page0Data: CloudImage.Data
	let page1Data: CloudImage.Data
	let page2Data: CloudImage.Data
	let isFirstVolume: Bool
	let isLastVolume: Bool
	let isFirstPage: Bool
	let isLastPage: Bool
	let screenHeight: CGFloat

	init(page0Data: CloudImage.Data, page1Data: CloudImage.Data, page2Data: CloudImage.Data, isFirstVolume: Bool, isLastVolume: Bool, isFirstPage: Bool, isLastPage: Bool, geometry: GeometryProxy) {
		self.page0Data = page0Data
		self.page1Data = page1Data
		self.page2Data = page2Data
		self.isFirstVolume = isFirstVolume
		self.isLastVolume = isLastVolume
		self.isFirstPage = isFirstPage
		self.isLastPage = isLastPage
		self.screenHeight = geometry.size.height
	}

	var body: some View {
		VStack(spacing: 0) {
			if isFirstPage {
				AdvancePage(label: isFirstVolume ? "未読" : "前章", alignment: .bottom, height: screenHeight)
			} else {
				CloudImage(page0Data, contentMode: .fill, defaultHeight: screenHeight)
			}
			CloudImage(page1Data, contentMode: .fill, defaultHeight: screenHeight)
			if !isLastPage {
				CloudImage(page2Data, contentMode: .fill, defaultHeight: screenHeight)
			} else {
				AdvancePage(label: isLastVolume ? "読破": "次章", alignment: .top, height: screenHeight)
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

	private let timer = Timer.publish(every: 1/1000, on: .main, in: .default).autoconnect()

	var body: some View {
		Rectangle()
			.hidden()
			.onReceive(timer) { date in
				let distance: CGFloat
				if let lastScrollDate = lastScrollDate {
					distance = CGFloat(lastScrollDate.distance(to: date))
					if distance < 0.050 {
						self.onScroll(-distance * 300 * CGFloat(self.direction.sign))
					}
				}
				lastScrollDate = date
			}
	}
}

struct ReadingContiguous_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return GeometryReader { geometry in
			ReadingContiguous(work: work, geometry: geometry)
		}
	}
}
