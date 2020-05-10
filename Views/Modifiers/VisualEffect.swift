import SwiftUI

struct BlurEffect: UIViewRepresentable {
	let effect: UIBlurEffect

	init(style: UIBlurEffect.Style) {
		effect = UIBlurEffect(style: style)
	}

	func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
		UIVisualEffectView()
	}

	func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
		uiView.effect = effect
	}
}
