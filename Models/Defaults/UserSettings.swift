import Combine
import Foundation

final class UserSettings: ObservableObject {
	static let shared = UserSettings()

	private func save(value: Any?, name: String = #function) {
		UserDefaults.standard.set(value, forKey: name)
	}

	@Published var invertContent = UserDefaults.standard.bool(forKey: "invertContent") {
		didSet {
			save(value: invertContent)
		}
	}

	@Published var darkContent = UserDefaults.standard.bool(forKey: #function) {
		didSet {
			save(value: invertContent)
		}
	}
}
