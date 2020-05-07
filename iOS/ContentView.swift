import SwiftUI

struct ContentView: View {
	var body: some View {
		Works()
			.accentColor(.primary)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environmentObject(DataModel.shared)
	}
}
