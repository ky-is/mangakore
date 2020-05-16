import SwiftUI

struct ReadingUI: View {
	let work: Work
	let geometry: GeometryProxy

	@ObservedObject private var localSettings = LocalSettings.shared

	var body: some View {
		Group {
			if localSettings.showUI {
				ReadingBar(work: work, geometry: geometry)
			}
		}
	}
}

private struct ReadingBar: View {
	let work: Work
	@ObservedObject var settings: WorkSettings
	let geometry: GeometryProxy

	init(work: Work, geometry: GeometryProxy) {
		self.work = work
		self.settings = work.settings
		self.geometry = geometry
	}

	var body: some View {
		VStack(spacing: 0) {
			Divider()
			HStack(spacing: 0) {
				Spacer()
				WorkProgressStats(work: work)
				Spacer()
				Group {
					NavigationUnicodeButton("⊖") {
						self.settings.magnification = max(1, self.settings.magnification - 0.025)
					}
						.disabled(settings.magnification <= 1)
					NavigationUnicodeButton("⊕") {
						self.settings.magnification = self.settings.magnification + 0.025
					}
						.disabled(settings.magnification > 1.5)
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
				ReadingUI(work: work, geometry: geometry)
			}
				.edgesIgnoringSafeArea(.all)
		}
	}
}
