import SwiftUI

struct Works: View {
	@ObservedObject private var userSettings = UserSettings.shared

	var body: some View {
		NavigationView {
			WorksList()
				.navigationBarTitle("漫画")
		}
			.navigationViewStyle(StackNavigationViewStyle())
			.statusBar(hidden: !userSettings.showUI)
	}
}

private struct WorksList: View {
	@EnvironmentObject var dataModel: DataModel

	var body: some View {
		Group {
			if dataModel.worksProgress != nil {
				List(dataModel.worksProgress!) {
					WorksEntry(progress: $0)
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
	@ObservedObject var progress: WorkProgress

	@State private var showOptions = false

	var body: some View {
		NavigationLink(destination: Reading(progress: progress)) {
			HStack {
				WorkIcon(progress)
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
//						.accentColor(.primary)
						.frame(width: 28, height: 28)
						.background(
							Circle()
								.fill(Color.gray.opacity(0.5))
						)
						.padding()
				}
			}
		}
			.padding(.trailing, -32)
			.buttonStyle(BorderlessButtonStyle())
			.accentColor(.primary)
	}
}

struct Works_Previews: PreviewProvider {
	static var previews: some View {
		Works()
			.environmentObject(DataModel.shared)
	}
}
