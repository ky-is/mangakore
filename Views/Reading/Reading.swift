import SwiftUI

struct Reading: View {
	@ObservedObject var progress: WorkProgress

	@State private var showVolumeList = false
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		Group {
			if progress.work.volumes.isEmpty {
				Text("Invalid folder layout")
			} else if progress.volume > 0 {
				ReadingPage(progress: progress)
			} else {
				EmptyView()
			}
		}
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle(Text(progress.work.name), displayMode: .inline)
			.navigationBarItems(trailing:
				HStack {
					NavigationEmojiButton("📖") {
						self.showVolumeList.toggle()
					}
						.popover(isPresented: $showVolumeList, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
							VolumeList(progress: self.progress)
						}
					NavigationEmojiButton("☯️") {
						self.userSettings.invertContent = !self.userSettings.invertContent
					}
						.colorInvert(userSettings.invertContent)
				}
			)
			.navigationBarHidden(!userSettings.showUI)
			.onAppear {
				self.userSettings.showUI = false
				if self.progress.volume < 1 {
					self.progress.volume = 1
				}
			}
			.onDisappear {
				self.userSettings.showUI = true
			}
	}
}

private struct VolumeList: View {
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		let currentVolume = progress.currentVolume
		return List(progress.work.volumes) { volume in
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

private struct ReadingPage: View {
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode
	@ObservedObject private var userSettings = UserSettings.shared

	private let advancePageWidth: CGFloat = 44

	var body: some View {
		let pages = progress.currentVolume.images
		return GeometryReader { geometry in
			ZStack {
				Group {
					if pages.isEmpty {
						VStack {
							Text("No pages in this volume")
							Text("Please check the folder in iCloud and try again.")
						}
					} else {
						PageImage(pages: pages, progress: self.progress, geometry: geometry)
					}
				}
					.onTapGesture {
						withAnimation {
							self.userSettings.showUI.toggle()
						}
					}
				ReadingUI(geometry: geometry, progress: self.progress)
			}
		}
	}
}

struct PageImage: View {
	let page: URL
	@ObservedObject var progress: WorkProgress
	let geometry: GeometryProxy

	@ObservedObject private var userSettings = UserSettings.shared

	init(pages: [URL], progress: WorkProgress, geometry: GeometryProxy) {
		let pageIndex = max(1, progress.page) - 1
		self.page = pages[pageIndex]
		self.progress = progress
		self.geometry = geometry

		self.page.cache(true)
		pages[safe: pageIndex + 1]?.cache(true)
	}

	var body: some View {
		CloudImage(page, width: geometry.size.width, height: geometry.size.height, contentMode: .fit)
			.colorInvert(userSettings.invertContent)
			.scaleEffect(CGFloat(progress.magnification))
			.modifier(PinchToZoom())
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return Reading(progress: WorkProgress(work))
	}
}
