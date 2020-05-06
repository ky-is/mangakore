import SwiftUI

struct Works: View {
	var body: some View {
		NavigationView {
			WorksList()
				.navigationBarTitle("漫画")
		}
	}
}

private struct WorksList: View {
	@EnvironmentObject var dataModel: DataModel

	var body: some View {
		List(dataModel.works) {
			WorksEntry(work: $0)
		}
	}
}

private struct WorksEntry: View {
	let work: Work
	let progress: WorkProgress

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
							Text("・\(progress.page) / \(work.volumes[progress.volume].images.count)頁")
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
						.frame(width: 32, height: 32)
						.background(
							Circle()
								.fill(Color.gray)
						)
						.padding()
				}
					.accentColor(.black)
			}
		}
			.padding(.trailing, -32)
			.buttonStyle(BorderlessButtonStyle())
			.actionSheet(isPresented: $showOptions) {
				ActionSheet(title: Text(work.id), message: nil, buttons: [
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
	}
}

struct Works_Previews: PreviewProvider {
	static var previews: some View {
		Works()
			.environmentObject(DataModel.shared)
	}
}
