import SwiftUI

extension View {
	func actionPopover(isPresented: Binding<Bool>, content: @escaping () -> ActionPopover) -> some View {
		Group {
			if UIDevice.current.userInterfaceIdiom == .pad {
				GeometryReader { geometry in
					self.popover(isPresented: isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: geometry.frame(in: .global).origin.y < UIScreen.main.bounds.height / 2 ? .top : .bottom) { content().popover(isPresented: isPresented)
					}
				}
			} else {
				actionSheet(isPresented: isPresented, content: content().actionSheet)
			}
		}
	}
}

struct ActionPopover {
	let title: Text
	let message: Text?
	let accentColor: Color?
	let buttons: [ActionPopover.Button]

	private let width: CGFloat = 256
	private let height: CGFloat = 44

	init(title: Text, message: Text? = nil, accentColor: Color? = nil, buttons: [ActionPopover.Button] = [.cancel()]) {
		self.title = title
		self.message = message
		self.accentColor = accentColor
		self.buttons = buttons
	}

	func actionSheet() -> ActionSheet {
		ActionSheet(title: title, message: message, buttons: buttons.map({ popButton in
			switch popButton.kind {
			case .default: return .default(popButton.label, action: popButton.action)
			case .cancel: return .cancel(popButton.label, action: popButton.action)
			case .destructive: return .destructive(popButton.label, action: popButton.action)
			}
		}))
	}

	func popover(isPresented: Binding<Bool>) -> some View {
		let popoverButtons = Array(buttons.filter({ $0.kind != .cancel }).enumerated())
		return VStack(spacing: 0) {
			VStack {
				title
					.font(.headline)
				message
					.font(.subheadline)
			}
				.frame(height: height)
			ForEach(popoverButtons, id: \.offset) { (offset, button) in
				Group {
					Divider()
					SwiftUI.Button(action: {
						isPresented.wrappedValue = false
						if let action = button.action {
							DispatchQueue.main.async(execute: action)
						}
					}, label: {
						button.label
							.font(.system(size: 18))
					})
						.accentColor(button.kind == .destructive ? .red : self.accentColor)
						.frame(width: self.width, height: self.height)
				}
			}
		}
			.frame(width: width, height: (height) * CGFloat(popoverButtons.count + 1) + 1)
	}

	struct Button {
		let kind: Kind
		let label: Text
		let action: (() -> Void)?
		enum Kind { case `default`, cancel, destructive }

		static func `default`(_ label: Text, action: (() -> Void)? = {}) -> Self {
			Self(kind: .default, label: label, action: action)
		}

		static func cancel(_ label: Text, action: (() -> Void)? = {}) -> Self {
			Self(kind: .cancel, label: label, action: action)
		}

		static func cancel(_ action: (() -> Void)? = {}) -> Self {
			Self(kind: .cancel, label: Text("Cancel"), action: action)
		}

		static func destructive(_ label: Text, action: (() -> Void)? = {}) -> Self {
			Self(kind: .destructive, label: label, action: action)
		}
	}
}

struct ActionPopover_Previews: PreviewProvider {
	static var previews: some View {
		Rectangle()
			.frame(width: 32, height: 32)
			.actionPopover(isPresented: .constant(true)) {
				ActionPopover(title: Text("Test"), message: nil, accentColor: .primary, buttons: [
					.default(Text("Default"), action: {}),
					.destructive(Text("Destructive"), action: {}),
					.cancel(),
				])
			}
	}
}
