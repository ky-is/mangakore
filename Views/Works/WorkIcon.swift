import SwiftUI

struct WorkIcon: View {
	let url: URL?
	let size: CGFloat

	init(_ progress: WorkProgress, size: CGFloat = 128) {
		self.url = progress.currentVolume.icon
		self.size = size
	}

	var body: some View {
		CloudImage(url, width: size, height: size, contentMode: .fill, alignment: .leading)
			.background(Color.gray)
	}
}

struct WorkIcon_Previews: PreviewProvider {
	static let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!

	static var previews: some View {
		WorkIcon(WorkProgress(sampleWork))
	}
}
