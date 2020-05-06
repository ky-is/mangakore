import SwiftUI

struct Reading: View {
	let work: Work
	@ObservedObject var progress: WorkProgress

	var body: some View {
		Group {
			if progress.volume > 0 {
				ReadingPage(work: work, progress: progress)
			} else {
				EmptyView()
			}
		}
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("")
			.navigationBarHidden(true)
			.onAppear {
				if self.progress.volume < 1 {
					self.progress.volume = 1
				}
			}
	}
}

private struct ReadingPage: View {
	let work: Work
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode
	@State private var showUI = false

	private let advancePageWidth: CGFloat = 44

	var body: some View {
		let images = self.work.volumes[self.progress.volume - 1].images
		print(self.progress.volume, self.work.volumes.count, self.progress.page, images.count)
		return GeometryReader { geometry in
			ZStack {
				CloudImage(images[self.progress.page - 1], size: geometry.size.width)
					.onTapGesture {
						self.showUI.toggle()
					}
				Group {
					ReadingPageToggle {
						if self.progress.page < images.count {
							self.progress.page = self.progress.page + 1
						} else if self.progress.volume < self.work.volumes.count {
							self.progress.volume = self.progress.volume + 1
						} else {
							self.presentationMode.wrappedValue.dismiss()
						}
					}
						.frame(width: self.advancePageWidth, height: geometry.size.height)
						.position(x: 0 + self.advancePageWidth / 2, y: geometry.size.height / 2)
					ReadingPageToggle {
						if self.progress.page > 0 {
							self.progress.page = self.progress.page - 1
						} else if self.progress.volume > 0 {
							self.progress.volume = self.progress.volume - 1
						}
					}
						.frame(width: self.advancePageWidth, height: geometry.size.height)
						.position(x: geometry.size.width - self.advancePageWidth / 2, y: geometry.size.height / 2)
				}
			}
		}
	}
}

private struct ReadingPageToggle: View {
	let callback: () -> Void

	var body: some View {
		Rectangle()
			.fill(Color.clear)
			.contentShape(Rectangle())
			.onTapGesture(perform: callback)
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return Reading(work: work, progress: WorkProgress(work))
	}
}
