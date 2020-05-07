import SwiftUI

struct Works: View {
	var body: some View {
		NavigationView {
			WorksList()
				.navigationBarTitle("漫画")
		}
			.navigationViewStyle(StackNavigationViewStyle())
	}
}

private struct WorksList: View {
	@EnvironmentObject var dataModel: DataModel

	var body: some View {
		Group {
			if dataModel.works != nil {
				List(dataModel.works!) {
					WorksEntry(work: $0)
				}
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

private struct WorksEntry: View {
	let work: Work

	@ObservedObject private var progress: WorkProgress
	@State private var showOptions = false

	init(work: Work) {
		self.work = work
		self.progress = WorkProgress(work)
	}

	var body: some View {
		NavigationLink(destination: Reading(work: work, progress: progress)) {
			HStack {
				WorkIcon(work)
				VStack(alignment: .leading) {
					Text(work.id)
						.font(.headline)
					HStack {
						Text("\(progress.volume) / \(work.volumes.count)巻")
						if progress.volume > 0 {
							Text("・\(progress.page) / \(work.volumes[progress.volume - 1].images.count)頁")
						}
					}
						.font(Font.subheadline.monospacedDigit())
				}
				Spacer()
				Button(action: {
					self.showOptions = true
				}) {
					Text("⋯")
						.bold()
						.frame(width: 28, height: 28)
						.background(
							Circle()
								.fill(Color.gray.opacity(0.5))
						)
						.padding()
				}
					.accentColor(.black)
			}
		}
			.padding(.trailing, -32)
			.buttonStyle(BorderlessButtonStyle())
			.actionSheet(isPresented: $showOptions) {
				ActionSheet(title: Text(work.id).font(.title), message: nil, buttons: [
					.destructive(Text("Reset reading progress")) {
						self.progress.volume = 0
						self.progress.page = 0
						self.progress.rating = 0
					},
					.default(Text("Cache local copy")) {
						self.work.volumes.forEach { volume in
							volume.images.forEach { url in
								try? FileManager.default.startDownloadingUbiquitousItem(at: url)
							}
						}
					},
					.destructive(Text("Remove local copy")) {
						self.work.volumes.forEach { volume in
							volume.images.forEach { url in
								try? FileManager.default.evictUbiquitousItem(at: url)
							}
						}
					},
					.cancel(),
				])
			}
			.accentColor(.primary)
	}
}

struct Works_Previews: PreviewProvider {
	static var previews: some View {
		Works()
			.environmentObject(DataModel.shared)
	}
}
