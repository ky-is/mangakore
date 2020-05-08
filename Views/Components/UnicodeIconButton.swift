import SwiftUI

struct UnicodeIconButton: View {
	let label: String
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(Font.system(size: 28).weight(.light))
				.frame(width: 44)
		}
	}
}

struct UnicodeIconButton_Previews: PreviewProvider {
	static var previews: some View {
		UnicodeIconButton(label: "☯") { }
	}
}
