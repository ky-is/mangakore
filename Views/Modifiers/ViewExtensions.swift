import SwiftUI

extension View {
	func colorInvert(_ enabled: Bool) -> some View {
		Group {
			if enabled {
				colorInvert()
			} else {
				self
			}
		}
	}

	func hidden(_ enabled: Bool) -> some View {
		Group {
			if enabled {
				hidden()
			} else {
				self
			}
		}
	}

	func reload(on: Any?) -> some View {
		self
	}
}

struct HiddenNavigationLink<Destination: View>: View {
	let enabled: Bool
	let destination: Destination

	var body: some View {
		NavigationLink(destination: destination, isActive: .constant(enabled)) { EmptyView() }
			.hidden()
	}
}
