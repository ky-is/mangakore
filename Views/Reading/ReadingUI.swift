import SwiftUI

struct ReadingUI: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress
	@Binding var hasInteracted: Bool

	@EnvironmentObject private var dataModel: DataModel
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		let advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
		return Group {
			if !progress.contiguous {
				ReadingPageToggle(width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted) {
					if self.progress.page < self.progress.currentVolume.pageCount {
						self.progress.page = self.progress.page + 1
					} else if self.progress.volume < self.progress.work.volumes.count {
						self.progress.volume = self.progress.volume + 1
					} else {
						self.dataModel.reading = nil
					}
				}
					.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
				ReadingPageToggle(width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted) {
					if self.progress.page > 1 {
						self.progress.page = self.progress.page - 1
					} else if self.progress.volume > 1 {
						self.progress.volume = self.progress.volume - 1
					}
				}
					.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
			}
			if userSettings.showUI {
				ReadingBar(geometry: geometry, progress: progress)
			}
		}
	}
}

private struct ReadingPageToggle: View {
	let width: CGFloat
	let height: CGFloat
	@Binding var hasInteracted: Bool
	let callback: () -> Void

	private let yInset: CGFloat = 44

	var body: some View {
		Rectangle()
			.fill(Color.clear) //TODO messes with ReadingBar blur
			.contentShape(Rectangle())
			.onTapGesture {
				if !self.hasInteracted {
					UserSettings.shared.showUI = false
				}
				self.callback()
			}
			.frame(width: width, height: height - yInset * 2)
	}
}

private struct ReadingBar: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress

	var body: some View {
		VStack(spacing: 0) {
			Divider()
			HStack(spacing: 0) {
				Spacer()
				Group {
					WorkProgressPage(progress: progress)
					Text("　")
					WorkProgressVolume(progress: progress)
				}
				Spacer()
				Group {
					NavigationUnicodeButton("⊖") {
						self.progress.magnification = max(1, self.progress.magnification - 0.025)
					}
						.disabled(progress.magnification <= 1)
					NavigationUnicodeButton("⊕") {
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

struct ReadingUI_Previews: PreviewProvider {
	static let work = Work(URL(string: "/")!)!

	static var previews: some View {
		NavigationView {
			GeometryReader { geometry in
				ReadingUI(geometry: geometry, progress: WorkProgress(work), hasInteracted: .constant(false))
			}
				.edgesIgnoringSafeArea(.all)
		}
	}
}
