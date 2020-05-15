import SwiftUI

struct Reading: View {
	@ObservedObject var progress: WorkProgress

	@State private var showVolumeList = false
	@ObservedObject private var userSettings = UserSettings.shared
	@EnvironmentObject private var dataModel: DataModel

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
				self.progress.startReading()
				if self.progress.volume < 1 {
					self.progress.volume = 1
				}
			}
			.onDisappear {
				self.progress.saveReadingTime(continuing: false)
				withAnimation {
					self.userSettings.showUI = true
				}
				self.dataModel.reading = nil
			}
	}
}

private struct VolumeList: View {
	@ObservedObject var progress: WorkProgress

	@Environment(\.presentationMode) private var presentationMode
	@EnvironmentObject private var dataModel: DataModel

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

	@ObservedObject private var userSettings = UserSettings.shared

	private let advancePageWidth: CGFloat = 44

	@State private var hasInteracted = false

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
						Group {
							if self.progress.contiguous {
								ReadingContiguous(pages: pages, progress: self.progress, geometry: geometry, hasInteracted: self.$hasInteracted)
							} else {
								ReadingPaginated(pages: pages, progress: self.progress, geometry: geometry, hasInteracted: self.$hasInteracted)
							}
						}
							.colorInvert(self.userSettings.invertContent)
							.scaleEffect(CGFloat(self.progress.magnification))
					}
				}
					.onTapGesture {
						self.hasInteracted = true
						withAnimation {
							self.userSettings.showUI.toggle()
						}
					}
				ReadingUI(geometry: geometry, progress: self.progress)
			}
		}
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return Reading(progress: WorkProgress(work))
	}
}
