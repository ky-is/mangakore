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
					NavigationDarkButton()
					NavigationInvertButton()
				}
			)
			.navigationBarHidden(!localSettings.showUI)
	}
}

private struct NavigationInvertButton: View {
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationButton(image: userSettings.invertContent ? "circle.righthalf.fill" : "circle.lefthalf.fill") {
			self.userSettings.invertContent = !self.userSettings.invertContent
		}
	}
}

private struct NavigationDarkButton: View {
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationButton(image: userSettings.darkContent ? "light.min" : "light.max") {
			self.userSettings.darkContent = !self.userSettings.darkContent
		}
	}
}

private struct NavigationVolumeButton: View {
	let work: Work

	@State private var showVolumeList = false
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationButton(image: "book.fill") {
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
				NavigationSpacer()
				NavigationSpacer()
				Spacer()
				WorkProgressStats(work: work)
				Spacer()
				ReadingMagnification(work: work)
			}
				.frame(height: 44)
				.padding(.horizontal, 8)
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
			NavigationButton(image: "minus.magnifyingglass") {
				self.settings.magnification = max(1, self.settings.magnification - 0.025)
			}
				.disabled(settings.magnification <= 1)
			NavigationButton(image: "plus.magnifyingglass") {
				self.settings.magnification = self.settings.magnification + 0.025
			}
				.disabled(settings.magnification > 1.5)
		}
			.frame(width: 44)
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
