import SwiftUI

struct ReadingPaginated: View {
	let url: URL
	let progress: WorkProgress
	let geometry: GeometryProxy
	@Binding var hasInteracted: Bool

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy, hasInteracted: Binding<Bool>) {
		let pageIndex = max(1, progress.page) - 1
		self.progress = progress
		self.url = pages[pageIndex]
		self.geometry = geometry
		self._hasInteracted = hasInteracted

		self.url.cache(true)
		pages[safe: pageIndex + 1]?.cache(true)
	}

	var body: some View {

		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		let advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
		return ZStack {
			CloudImage(url, priority: true, contentMode: .fit)
				.frame(width: geometry.size.width, height: geometry.size.height)
				.modifier(PinchToZoom())
			ReadingPageToggle(progress: progress, forward: true, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
				.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
			ReadingPageToggle(progress: progress, forward: false, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
				.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
		}
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
			.fill(Color.clear)
			.contentShape(Rectangle())
			.onTapGesture {
				if !self.hasInteracted {
					UserSettings.shared.showUI = false
					self.hasInteracted = true
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
			ReadingPaginated(pages: [], progress: WorkProgress(work), geometry: geometry, hasInteracted: .constant(false))
		}
	}
}
