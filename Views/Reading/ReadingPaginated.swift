import SwiftUI

struct ReadingPaginated: View {
	let work: Work
	let geometry: GeometryProxy

	private let advancePageWidth: CGFloat

	init(work: Work, geometry: GeometryProxy) {
		self.work = work
		self.geometry = geometry
		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		self.advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
	}

	var body: some View {
		ZStack {
			ReadingPaginatedPage(work: work, geometry: geometry)
			ReadingPageToggle(progress: work.progress, forward: true, width: advancePageWidth, height: geometry.size.height)
				.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
			ReadingPageToggle(progress: work.progress, forward: false, width: advancePageWidth, height: geometry.size.height)
				.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
		}
	}
}

private struct ReadingPaginatedPage: View {
	let geometry: GeometryProxy

	@ObservedObject private var progress: WorkProgress

	init(work: Work, geometry: GeometryProxy) {
		self.progress = work.progress
		self.geometry = geometry
	}

	var body: some View {
		let pages = progress.currentVolume.images
		let pageIndex = max(1, progress.page) - 1
		let url = pages[pageIndex]
		url.cache(true)
		pages[safe: pageIndex + 1]?.cache(true)
		return CloudImage(url, priority: true, contentMode: .fit)
			.frame(width: geometry.size.width, height: geometry.size.height)
			.modifier(PinchToZoom())
	}
}


private struct ReadingPageToggle: View {
	let progress: WorkProgress
	let forward: Bool
	let width: CGFloat
	let height: CGFloat

	private let yInset: CGFloat = 44

	var body: some View {
		Rectangle()
			.hidden()
			.contentShape(Rectangle())
			.onTapGesture {
				if !LocalSettings.shared.hasInteracted {
					LocalSettings.shared.hasInteracted = true
					withAnimation {
						LocalSettings.shared.showUI = false
					}
				}
				self.progress.advancePage(forward: self.forward)
			}
			.frame(width: width, height: height - yInset * 2)
	}
}

struct ReadingPaginated_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return GeometryReader { geometry in
			ReadingPaginated(work: work, geometry: geometry)
		}
	}
}
