import SwiftUI

struct ReadingUI: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress
	@Binding var hasInteracted: Bool

	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		let pageWidthRange: ClosedRange<CGFloat> = 40...128
		let advancePageWidth = pageWidthRange.clamp(geometry.size.width * 0.15)
		return Group {
			if !progress.contiguous {
				ReadingPageToggle(progress: progress, forward: true, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
					.position(x: 0 + advancePageWidth / 2, y: geometry.size.height / 2)
				ReadingPageToggle(progress: progress, forward: false, width: advancePageWidth, height: geometry.size.height, hasInteracted: $hasInteracted)
					.position(x: geometry.size.width - advancePageWidth / 2, y: geometry.size.height / 2)
			}
			if userSettings.showUI {
				ReadingBar(geometry: geometry, progress: progress)
			}
		}
	}
}

private struct ReadingPageToggle: View {
	let progress: WorkProgress
	let forward: Bool
	let width: CGFloat
	let height: CGFloat
	@Binding var hasInteracted: Bool

	private let yInset: CGFloat = 44

	var body: some View {
		Rectangle()
			.fill(Color.clear)
			.contentShape(Rectangle())
			.onTapGesture {
				if !self.hasInteracted {
					UserSettings.shared.showUI = false
					self.hasInteracted = true
				}
				self.progress.advancePage(forward: self.forward)
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
					WorkProgressVolume(progress: progress)
					Text("　")
					WorkProgressPage(progress: progress)
//					Text("　") //SAMPLE
//					Text(Int(progress.timeReading).description)
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
