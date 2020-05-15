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
	@ObservedObject var progress: WorkProgress

	init(work: Work) {
		self.work = work
		self.progress = work.progress
	}

	var body: some View {
		HStack(spacing: 0) {
			WorkProgressVolume(work: work)
			Text("　")
			if progress.volume > 0 && progress.page > 0 {
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
	@ObservedObject var progress: WorkProgress
	@ObservedObject var settings: WorkSettings

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
	@ObservedObject var progress: WorkProgress

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
	static let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!

	static var previews: some View {
		VStack {
			HStack {
				WorkProgressVolume(work: sampleWork)
				WorkProgressPage(work: sampleWork)
			}
			WorkIcon(sampleWork)
		}
	}
}
