import SwiftUI

struct ReadingPaginated: View {
	let url: URL
	let geometry: GeometryProxy

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy) {
		let pageIndex = max(1, progress.page) - 1
		self.url = pages[pageIndex]
		self.geometry = geometry

		self.url.cache(true)
		pages[safe: pageIndex + 1]?.cache(true)
	}

	var body: some View {
		CloudImage(url, priority: true, contentMode: .fit)
			.frame(width: geometry.size.width, height: geometry.size.height)
			.modifier(PinchToZoom())
	}
}

struct ReadingPaginated_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return GeometryReader { geometry in
			ReadingPaginated(pages: [], progress: WorkProgress(work), geometry: geometry)
		}
	}
}
