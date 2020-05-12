import SwiftUI

struct Works: View {
	@EnvironmentObject private var dataModel: DataModel
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationView {
			WorksListContainer()
				.navigationBarTitle("漫画")
		}
			.navigationViewStyle(StackNavigationViewStyle())
			.statusBar(hidden: !userSettings.showUI)
	}
}

private struct WorksListContainer: View {
	@EnvironmentObject private var dataModel: DataModel

	var body: some View {
		Group {
			if dataModel.worksProgress != nil {
				WorksList(worksProgress: dataModel.worksProgress!)
					.background(
						HiddenNavigationLink(enabled: dataModel.reading != nil, destination: Reading(progress: dataModel.reading ?? WorkProgress(Work(URL(string: "/")!)!)))
					)
			} else {
				VStack {
					Text("iCloud Drive Unavailable")
						.font(.title)
						.padding(.bottom)
					Text("manga kore requires iCloud Drive to store and manage your library. Please enable it in settings and try again.")
						.font(.subheadline)
				}
					.padding(.horizontal)
			}
		}
	}
}

private struct WorksList: View {
	let reading: [WorkProgress]
	let unread: [WorkProgress]
	let finished: [WorkProgress]

	init(worksProgress: [WorkProgress]) {
		var reading: [WorkProgress] = []
		var unread: [WorkProgress] = []
		var finished: [WorkProgress] = []
		for workProgress in worksProgress {
			if workProgress.finished {
				finished.append(workProgress)
			} else if workProgress.volume > 1 || workProgress.page > 1 {
				reading.append(workProgress)
			} else {
				unread.append(workProgress)
			}
		}
		self.reading = reading
		self.unread = unread
		self.finished = finished
	}

	var body: some View {
		List {
			if !reading.isEmpty {
				Section(header: Text("Reading")) {
					ForEach(reading) {
						WorksEntry(progress: $0)
					}
				}
			}
			if !unread.isEmpty {
				Section(header: Text("Unread")) {
					ForEach(unread) {
						WorksEntry(progress: $0)
					}
				}
			}
			if !finished.isEmpty {
				Section(header: Text("Finished")) {
					ForEach(finished) {
						WorksEntry(progress: $0)
					}
				}
			}
		}
	}
}

private struct WorksEntry: View {
	@ObservedObject var progress: WorkProgress

	@State private var showOptions = false

	var body: some View {
		HStack {
			WorkIcon(progress)
			Button(action: {
				DataModel.shared.reading = self.progress
			}) {
				VStack(alignment: .leading) {
					Text(progress.work.name)
						.font(.headline)
					HStack(spacing: 0) {
						WorkProgressVolume(progress: progress)
						Text("　")
						if progress.volume > 0 && progress.page > 0 {
							WorkProgressPage(progress: progress)
						}
					}
						.font(Font.subheadline.monospacedDigit())
				}
			}
			Spacer()
			Button(action: {
				self.showOptions = true
			}) {
				Text("⋯")
					.bold()
					.actionPopover(isPresented: $showOptions) {
						ActionPopover(title: Text(self.progress.work.name).font(.title), message: nil, accentColor: .primary, buttons: [
							.destructive(Text("Reset reading progress")) {
								self.progress.volume = 0
								self.progress.page = 0
								self.progress.rating = 0
							},
							.default(Text("Cache local copy")) {
								self.progress.work.cache(true)
							},
							.destructive(Text("Remove local copy")) {
								self.progress.work.cache(false)
							},
							.cancel(),
						])
					}
					.frame(size: 28)
					.background(
						Circle()
							.fill(Color.gray.opacity(0.5))
					)
			}
				.buttonStyle(BorderlessButtonStyle())
				.frame(size: 44)
		}
			.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
			.accentColor(.primary)
	}
}

struct Works_Previews: PreviewProvider {
	static var previews: some View {
		Works()
			.environmentObject(DataModel.shared)
	}
}
