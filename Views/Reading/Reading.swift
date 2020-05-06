import SwiftUI

struct Reading: View {
	let work: Work
	@ObservedObject var progress: WorkProgress

	var body: some View {
		GeometryReader { geometry in
			if self.progress.volume > 0 {
				CloudImage(self.work.volumes[self.progress.volume - 1].images[self.progress.page - 1], size: geometry.size.width)
			}
		}
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("")
			.navigationBarHidden(true)
			.onAppear {
				if self.progress.volume < 1 {
					self.progress.volume = 1
				}
			}
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return Reading(work: work, progress: WorkProgress(work))
	}
}
