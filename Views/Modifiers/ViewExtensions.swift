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
}
