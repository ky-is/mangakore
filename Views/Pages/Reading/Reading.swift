import SwiftUI

struct Reading: View {
	let work: Work

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
			.modifier(ReadingUINavigationModifier(work: work))
			.onAppear {
				self.work.progress.startReading()
				if self.work.progress.volume < 1 {
					self.work.progress.volume = 1
				}
			}
			.onDisappear {
				self.work.progress.saveReadingTime(continuing: false)
				LocalSettings.shared.hasInteracted = false
				if !LocalSettings.shared.showUI {
					withAnimation {
						LocalSettings.shared.showUI = true
					}
				}
				DataModel.shared.readingID = nil
			}
	}
}

private struct ReadingPage: View {
	let work: Work

	private let advancePageWidth: CGFloat = 44

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				ReadingPageContent(work: self.work, geometry: geometry)
					.onTapGesture {
						if !LocalSettings.shared.hasInteracted {
							LocalSettings.shared.hasInteracted = true
						}
						withAnimation {
							LocalSettings.shared.showUI.toggle()
						}
					}
				ReadingUI(work: self.work, geometry: geometry)
			}
		}
	}
}

private struct ReadingPageContent: View {
	let work: Work
	let geometry: GeometryProxy

	@ObservedObject private var settings: WorkSettings
	@ObservedObject private var userSettings = UserSettings.shared

	init(work: Work, geometry: GeometryProxy) {
		self.work = work
		self.settings = work.settings
		self.geometry = geometry
	}

	var body: some View {
		Group {
			if settings.contiguous {
				ReadingContiguous(work: work, geometry: geometry)
			} else {
				ReadingPaginated(work: work, geometry: geometry)
			}
		}
			.colorInvert(userSettings.invertContent)
			.opacity(userSettings.darkContent ? 2/3 : 1)
			.scaleEffect(CGFloat(settings.magnification))
			.background(Color.black)
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		Reading(id: "TEST")
	}
}
