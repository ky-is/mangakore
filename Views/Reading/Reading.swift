import SwiftUI

struct Reading: View {
	let work: Work
	@ObservedObject var progress: WorkProgress
	@State private var showUI = false

	var body: some View {
		Group {
			if progress.volume > 0 {
				ReadingPage(work: work, progress: progress, showUI: $showUI)
			} else {
				EmptyView()
			}
		}
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle(Text(work.id), displayMode: .inline)
			.navigationBarHidden(!showUI)
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
	@Binding var showUI: Bool

	@Environment(\.presentationMode) private var presentationMode

	private let advancePageWidth: CGFloat = 44

	var body: some View {
		let images = work.volumes[progress.volume - 1].images
		return GeometryReader { geometry in
			ZStack {
				CloudImage(images[self.progress.page - 1], width: geometry.size.width, height: geometry.size.height, contentMode: .fit)
					.scaleEffect(CGFloat(self.progress.magnification))
					.modifier(PinchToZoom())
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
						if self.progress.page > 1 {
							self.progress.page = self.progress.page - 1
						} else if self.progress.volume > 1 {
							self.progress.volume = self.progress.volume - 1
						}
					}
						.frame(width: self.advancePageWidth, height: geometry.size.height)
						.position(x: geometry.size.width - self.advancePageWidth / 2, y: geometry.size.height / 2)
				}
				if self.showUI {
					ReadingBar(geometry: geometry, progress: self.progress)
				}
			}
		}
	}
}

struct ReadingBar: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		VStack {
			HStack {
				Spacer()
				HStack {
					Button(action: {
						self.progress.magnification = max(1, self.progress.magnification - 0.03)
					}) {
						Text("⊖")
							.font(Font.system(size: 28).weight(.light))
							.frame(width: 44)
					}
						.disabled(progress.magnification <= 1)
					Button(action: {
						self.progress.magnification = self.progress.magnification + 0.03
					}) {
						Text("⊕")
							.font(Font.system(size: 28).weight(.light))
							.frame(width: 44)
					}
						.disabled(progress.magnification > 1.5)
				}
			}
				.frame(height: 44)
				.padding(.horizontal)
				.padding(.bottom, geometry.safeAreaInsets.bottom)
		}
			.transition(.opacity)
			.background(BlurEffect(style: .systemChromeMaterial))
			.position(x: geometry.size.width / 2, y: geometry.size.height - (44 + geometry.safeAreaInsets.bottom) / 2)
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
