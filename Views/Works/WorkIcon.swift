import SwiftUI

struct WorkIcon: View {
	let url: URL?
	let size: CGFloat

	init(_ work: Work, size: CGFloat = 128) {
		self.url = work.icon
		self.size = size
	}

	var body: some View {
		CloudImage(url, width: size, height: size, contentMode: .fill, alignment: .leading)
			.background(Color.gray)
	}
}

struct WorkIcon_Previews: PreviewProvider {
	static var previews: some View {
		let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!
		return WorkIcon(sampleWork)
	}
}
