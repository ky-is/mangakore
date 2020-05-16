import Combine

final class LocalSettings: ObservableObject {
	static let shared = LocalSettings()

	@Published var showUI = true
	@Published var hasInteracted = false
}
