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
//	@UserState("work.id", default: 0) private var currentVolume

	init(work: Work) {
		self.work = work
		self.progress = WorkProgress(work)
	}

	var body: some View {
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
		}
	}
}

struct Works_Previews: PreviewProvider {
	static var previews: some View {
		Works()
			.environmentObject(DataModel.shared)
	}
}
