import SwiftUI

struct Reading: View {
	let work: Work

	@State private var showVolumeList = false
	@ObservedObject private var userSettings = UserSettings.shared

	init(id: String) {
		self.work = DataModel.shared.getWork(by: id)!
	}

	var body: some View {
		Group {
			if work.volumes.isEmpty {
				Text("Invalid folder layout")
			} else {
				ReadingPage(work: work)
			}
		}
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle(Text(work.name), displayMode: .inline)
			.navigationBarItems(trailing:
				HStack {
					NavigationEmojiButton("📖") {
						self.showVolumeList.toggle()
					}
						.popover(isPresented: $showVolumeList, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
							VolumeList(work: self.work)
								.environmentObject(DataModel.shared)
						}
					NavigationEmojiButton("☯️") {
						self.userSettings.invertContent = !self.userSettings.invertContent
					}
						.colorInvert(userSettings.invertContent)
				}
			)
			.navigationBarHidden(!userSettings.showUI)
			.onAppear {
				self.work.progress.startReading()
				if self.work.progress.volume < 1 {
					self.work.progress.volume = 1
				}
			}
			.onDisappear {
				self.work.progress.saveReadingTime(continuing: false)
				withAnimation {
					self.userSettings.showUI = true
				}
				DataModel.shared.readingID = nil
			}
	}
}

private struct VolumeList: View {
	let work: Work
	@ObservedObject var progress: WorkProgress

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

private struct ReadingPage: View {
	let work: Work
	@ObservedObject var settings: WorkSettings

	@ObservedObject private var userSettings = UserSettings.shared
	private let advancePageWidth: CGFloat = 44
	@State private var hasInteracted = false

	init(work: Work) {
		self.work = work
		self.settings = work.settings
	}

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				Group {
					if self.settings.contiguous {
						ReadingContiguous(work: self.work, geometry: geometry, hasInteracted: self.$hasInteracted)
					} else {
						ReadingPaginated(work: self.work, geometry: geometry, hasInteracted: self.$hasInteracted)
					}
				}
					.colorInvert(self.userSettings.invertContent)
					.scaleEffect(CGFloat(self.settings.magnification))
					.onTapGesture {
						self.hasInteracted = true
						withAnimation {
							self.userSettings.showUI.toggle()
						}
					}
				if self.userSettings.showUI {
					ReadingUI(work: self.work, geometry: geometry)
				}
			}
		}
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		Reading(id: "TEST")
	}
}
