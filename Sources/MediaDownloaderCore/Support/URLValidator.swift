import Foundation

public enum URLValidator {
    public static func looksLikeWebURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }

        guard let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return false
        }

        return components.host?.isEmpty == false
    }
}
