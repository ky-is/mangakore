import SwiftUI

struct NavigationUnicodeButton: View {
	let label: String
	let action: () -> Void

	init(_ label: String, action: @escaping () -> Void) {
		self.label = label
		self.action = action
	}

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(Font.system(size: 28).weight(.light))
				.frame(size: 40)
		}
	}
}

struct NavigationEmojiButton: View {
	let label: String
	let action: () -> Void

	init(_ label: String, action: @escaping () -> Void) {
		self.label = label
		self.action = action
	}

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(.system(size: 24))
				.frame(size: 40)
		}
	}
}

struct NavigationButtons_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			NavigationUnicodeButton("⊕") { }
			NavigationEmojiButton("☯️") { }
		}
	}
}
