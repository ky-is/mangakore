import SwiftUI

struct Reading: View {
	let work: Work
	let progress: WorkProgress

	var body: some View {
		Text(work.id)
			.navigationBarTitle("")
			.navigationBarHidden(true)
	}
}

struct Reading_Previews: PreviewProvider {
	static var previews: some View {
		let work = Work(URL(string: "/")!)!
		return Reading(work: work, progress: WorkProgress(work))
	}
}
