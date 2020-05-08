import SwiftUI

struct ReadingUI: View {
	let geometry: GeometryProxy
	let work: Work
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		let advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
		return Group {
			ReadingPageToggle {
				if self.progress.page < self.progress.currentVolume.pageCount {
					self.progress.page = self.progress.page + 1
				} else if self.progress.volume < self.work.volumes.count {
					self.progress.volume = self.progress.volume + 1
				} else {
					self.presentationMode.wrappedValue.dismiss()
				}
			}
				.frame(width: advancePageWidth, height: geometry.size.height)
				.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
			ReadingPageToggle {
				if self.progress.page > 1 {
					self.progress.page = self.progress.page - 1
				} else if self.progress.volume > 1 {
					self.progress.volume = self.progress.volume - 1
				}
			}
				.frame(width: advancePageWidth, height: geometry.size.height)
				.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
			if userSettings.showUI {
				ReadingBar(geometry: geometry, progress: progress)
			}
		}
	}
}

private struct ReadingBar: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		VStack(spacing: 0) {
			Divider()
			HStack {
				Spacer()
				HStack {
					UnicodeIconButton(label: "⊖") {
						self.progress.magnification = max(1, self.progress.magnification - 0.025)
					}
						.disabled(progress.magnification <= 1)
					UnicodeIconButton(label: "⊕") {
						self.progress.magnification = self.progress.magnification + 0.025
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
			.fill(Color.clear) //TODO messes with ReadingBar blur
			.contentShape(Rectangle())
			.onTapGesture(perform: callback)
	}
}

struct ReadingUI_Previews: PreviewProvider {
	static let work = Work(URL(string: "/")!)!

	static var previews: some View {
		NavigationView {
			GeometryReader { geometry in
				ReadingUI(geometry: geometry, work: work, progress: WorkProgress(work))
			}
				.edgesIgnoringSafeArea(.all)
		}
	}
}
