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

struct ReadingUINavigationModifier: ViewModifier {
	let work: Work

	@ObservedObject private var localSettings = LocalSettings.shared

	func body(content: Content) -> some View {
		content
			.navigationBarTitle(Text(work.name), displayMode: .inline)
			.navigationBarItems(trailing:
				HStack {
					NavigationVolumeButton(work: work)
					NavigationInvertButton()
				}
			)
			.navigationBarHidden(!localSettings.showUI)
	}
}

private struct NavigationInvertButton: View {
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationEmojiButton("☯️") {
			self.userSettings.invertContent = !self.userSettings.invertContent
		}
			.colorInvert(userSettings.invertContent)
	}
}

private struct NavigationVolumeButton: View {
	let work: Work

	@State private var showVolumeList = false
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationEmojiButton("📖") {
			self.showVolumeList.toggle()
		}
			.popover(isPresented: $showVolumeList, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
				VolumeList(work: self.work)
					.environmentObject(DataModel.shared)
			}
	}
}

private struct VolumeList: View {
	let work: Work

	@ObservedObject private var progress: WorkProgress
	@Environment(\.presentationMode) private var presentationMode

	init(work: Work) {
		self.work = work
		self.progress = work.progress
	}

	var body: some View {
		let currentVolume = progress.currentVolume
		return List(work.volumes) { volume in
			Button(action: {
				self.progress.volume = volume.id
				self.presentationMode.wrappedValue.dismiss()
			}) {
				HStack {
					Text("✔︎")
						.hidden(volume != currentVolume)
					Text("\(volume.id)巻")
				}
			}
				.disabled(volume == currentVolume)
		}
			.font(Font.body.monospacedDigit())
			.frame(minWidth: 256, minHeight: 256)
	}
}

private struct ReadingBar: View {
	let work: Work
	let geometry: GeometryProxy

	init(work: Work, geometry: GeometryProxy) {
		self.work = work
		self.geometry = geometry
	}

	var body: some View {
		VStack(spacing: 0) {
			Divider()
			HStack(spacing: 0) {
				Spacer()
				WorkProgressStats(work: work)
				Spacer()
				ReadingMagnification(work: work)
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

private struct ReadingMagnification: View {
	@ObservedObject private var settings: WorkSettings

	init(work: Work) {
		self.settings = work.settings
	}

	var body: some View {
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
