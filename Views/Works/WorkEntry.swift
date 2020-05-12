import SwiftUI

struct WorkIcon: View {
	let url: URL?
	let size: CGFloat

	init(_ progress: WorkProgress, size: CGFloat = 128) {
		self.url = progress.currentVolume.icon
		self.size = size
	}

	var body: some View {
		CloudImage(url, priority: false, contentMode: .fill)
			.frame(size: size, alignment: .topLeading)
			.background(Color.gray)
			.clipped()
	}
}

struct WorkProgressVolume: View {
	@ObservedObject var progress: WorkProgress

	var body: some View {
		Text(progress.volume.description)
		+
		Text("/\(progress.work.volumes.count)")
			.foregroundColor(.secondary)
		+
		Text(progress.contiguous ? "章" : "巻")
	}
}

struct WorkProgressPage: View {
	@ObservedObject var progress: WorkProgress

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
		let progress = WorkProgress(sampleWork)
		return VStack {
			HStack {
				WorkProgressVolume(progress: progress)
				WorkProgressPage(progress: progress)
			}
			WorkIcon(progress)
		}
	}
}
