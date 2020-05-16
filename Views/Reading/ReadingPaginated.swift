import SwiftUI

struct ReadingPaginated: View {
	let work: Work
	let geometry: GeometryProxy
	@Binding var hasInteracted: Bool

	private let advancePageWidth: CGFloat

	init(work: Work, geometry: GeometryProxy, hasInteracted: Binding<Bool>) {
		self.work = work
		self.geometry = geometry
		self._hasInteracted = hasInteracted
		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		self.advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
	}

	var body: some View {
		ZStack {
			ReadingPaginatedPage(work: work, geometry: geometry)
			ReadingPageToggle(progress: work.progress, forward: true, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
				.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
			ReadingPageToggle(progress: work.progress, forward: false, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
				.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
		}
	}
}

private struct ReadingPaginatedPage: View {
	@ObservedObject var progress: WorkProgress
	let geometry: GeometryProxy

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
	@Binding var hasInteracted: Bool

	private let yInset: CGFloat = 44

	var body: some View {
		Rectangle()
			.hidden()
			.contentShape(Rectangle())
			.onTapGesture {
				if !self.hasInteracted {
					self.hasInteracted = true
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
			ReadingPaginated(work: work, geometry: geometry, hasInteracted: .constant(false))
		}
	}
}
