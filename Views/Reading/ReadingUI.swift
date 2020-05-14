import SwiftUI

struct ReadingUI: View {
	let geometry: GeometryProxy
	@ObservedObject var progress: WorkProgress

	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		Group {
			if userSettings.showUI {
				ReadingBar(geometry: geometry, progress: progress)
			}
		}
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
				ReadingUI(geometry: geometry, progress: WorkProgress(work))
			}
				.edgesIgnoringSafeArea(.all)
		}
	}
}
