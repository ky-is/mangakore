import SwiftUI

struct WorkIcon: View {
	let url: URL?
	let size: CGFloat

	init(_ work: Work, size: CGFloat = 128) {
		self.url = work.progress.currentVolume.icon
		self.size = size
	}

	var body: some View {
		CloudImage(url, priority: false, contentMode: .fill)
			.frame(size: size, alignment: .topLeading)
			.background(Color.gray)
			.clipped()
	}
}

struct WorkProgressStats: View {
	let work: Work

	@ObservedObject private var progress: WorkProgress

	init(work: Work) {
		self.work = work
		self.progress = work.progress
	}

	var body: some View {
		HStack(spacing: 0) {
			WorkProgressVolume(work: work)
			if progress.volume > 0 && progress.page > 0 {
				Text("　")
				WorkProgressPage(work: work)
			}
//			Text("　") //SAMPLE
//			Text(Int(progress.timeReading).description)
		}
			.font(Font.subheadline.monospacedDigit())
	}
}

struct WorkProgressVolume: View {
	let work: Work

	@ObservedObject private var progress: WorkProgress
	@ObservedObject private var settings: WorkSettings

	init(work: Work) {
		self.work = work
		self.progress = work.progress
		self.settings = work.settings
	}

	var body: some View {
		Text(progress.volume.description)
		+
		Text("/\(work.volumes.count)")
			.foregroundColor(.secondary)
		+
		Text(settings.contiguous ? "章" : "巻")
	}
}

struct WorkProgressPage: View {
	@ObservedObject private var progress: WorkProgress

	init(work: Work) {
		self.progress = work.progress
	}

	var body: some View {
		Text(progress.page.description)
		+
		Text("/\(progress.currentVolume.pageCount)")
			.foregroundColor(.secondary)
		+
		Text("頁")
	}
}

struct WorkEntry_Previews: PreviewProvider {
	static let sampleWork = Work(URL(string: "")!)!

	static var previews: some View {
		VStack {
			WorkProgressStats(work: sampleWork)
			WorkIcon(sampleWork)
		}
	}
}
