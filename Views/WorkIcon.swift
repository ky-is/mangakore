import SwiftUI

struct WorkIcon: View {
	let image: UIImage?
	let size: CGFloat

	init(_ work: Work, size: CGFloat = 128) {
		if let path = work.icon?.path {
			image = UIImage(contentsOfFile: path)
		} else {
			image = nil
		}
		self.size = size
	}

	var body: some View {
		Group {
			if image != nil {
				Image(uiImage: image!)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: size, height: size)
					.clipped()
			} else {
				Text("?")
					.font(.largeTitle)
					.frame(width: size, height: size)
					.background(Color.gray)
			}
		}
	}
}

struct WorkIcon_Previews: PreviewProvider {
	static var previews: some View {
		let sampleWork = Work(FileManager.default.url(forUbiquityContainerIdentifier: nil)!)!
		return WorkIcon(sampleWork)
	}
}
