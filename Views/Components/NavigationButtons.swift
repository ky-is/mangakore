import SwiftUI

struct NavigationButton: View {
	let image: String
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Image(systemName: image)
//				.font(.system(size: 24))
				.frame(size: 40)
		}
	}
}

struct NavigationSpacer: View {
	var body: some View {
		Spacer()
			.frame(size: 40)
	}
}

struct NavigationButtons_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			NavigationSpacer()
			NavigationSpacer()
			NavigationButton(image: "circle.lefthalf.fill") {}
		}
	}
}
