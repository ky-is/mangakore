import SwiftUI

struct Works: View {
	@ObservedObject private var localSettings = LocalSettings.shared

	var body: some View {
		NavigationView {
			WorksListContainer()
				.navigationBarTitle("漫画コレ")
		}
			.navigationViewStyle(StackNavigationViewStyle())
			.statusBar(hidden: !localSettings.showUI)
	}
}

private struct WorksListContainer: View {
	@EnvironmentObject private var dataModel: DataModel

	var body: some View {
		Group {
			if dataModel.works != nil {
				WorksList(works: dataModel.works!)
					.background(
						Group {
							if dataModel.readingID != nil {
								HiddenNavigationLink(enabled: true, destination: Reading(id: dataModel.readingID!))
							}
						}
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
	let reading: [Work]
	let unread: [Work]
	let finished: [Work]

	init(works: [Work]) {
		var reading: [Work] = []
		var unread: [Work] = []
		var finished: [Work] = []
		for work in works {
			let progress = work.progress
			if progress.finished {
				finished.append(work)
			} else if progress.started {
				reading.append(work)
			} else {
				unread.append(work)
			}
		}
		self.reading = reading
		self.unread = unread
		self.finished = finished
	}

	var body: some View {
		List {
			if !reading.isEmpty {
				Section(header: Text("読中")) {
					ForEach(reading) {
						WorksEntry(work: $0)
					}
				}
			}
			if !unread.isEmpty {
				Section(header: Text("未読")) {
					ForEach(unread) {
						WorksEntry(work: $0)
					}
				}
			}
			if !finished.isEmpty {
				Section(header: Text("読破")) {
					ForEach(finished) {
						WorksEntry(work: $0)
					}
				}
			}
		}
	}
}

private struct WorksEntry: View {
	let work: Work

	@State private var showOptions = false

	var body: some View {
		HStack {
			WorkIcon(work)
			Button(action: {
				DataModel.shared.readingID = self.work.id
			}) {
				VStack(alignment: .leading) {
					Text(work.name)
						.font(.headline)
					WorkProgressStats(work: work)
				}
			}
			Spacer()
			Button(action: {
				self.showOptions = true
			}) {
				Text("⋯")
					.bold()
					.actionPopover(isPresented: $showOptions) {
						ActionPopover(title: Text(self.work.name).font(.title), message: nil, accentColor: .primary, buttons: [
							.destructive(Text("Reset reading progress")) {
								self.work.progress.volume = 0
								self.work.progress.page = 0
							},
							.default(Text("Cache local copy")) {
								self.work.cache(true)
							},
							.destructive(Text("Remove local copy")) {
								self.work.cache(false)
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
