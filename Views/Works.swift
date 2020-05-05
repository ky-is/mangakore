import SwiftUI

struct Works: View {
	@EnvironmentObject var dataModel: DataModel

	var body: some View {
		List(dataModel.works) { work in
			HStack {
				WorkIcon(work)
				VStack(alignment: .leading) {
					Text(work.id)
						.font(.headline)
					Text("\(work.volumes.count)巻")
						.font(Font.subheadline.monospacedDigit())
				}
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
