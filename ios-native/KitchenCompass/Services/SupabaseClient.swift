import Foundation

struct SupabaseConfiguration {
    let url: URL
    let publishableKey: String

    static func load() -> SupabaseConfiguration {
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let values = NSDictionary(contentsOfFile: path),
           let urlString = values["SUPABASE_URL"] as? String,
           let url = URL(string: urlString) {
            return SupabaseConfiguration(url: url, publishableKey: values["SUPABASE_PUBLISHABLE_KEY"] as? String ?? "")
        }
        return SupabaseConfiguration(url: URL(string: "https://ohjezigyqrhkykbjimgo.supabase.co")!, publishableKey: "")
    }
}

struct SupabaseSession: Codable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

enum SupabaseClientError: LocalizedError {
    case missingKey
    case badResponse

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Add SUPABASE_PUBLISHABLE_KEY to SupabaseConfig.plist before using live auth."
        case .badResponse: return "Supabase returned an unexpected response."
        }
    }
}

final class SupabaseClient {
    private let configuration = SupabaseConfiguration.load()

    func signUp(email: String, password: String) async throws -> SupabaseSession? {
        try await auth(path: "/auth/v1/signup", body: ["email": email, "password": password])
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession? {
        try await auth(path: "/auth/v1/token?grant_type=password", body: ["email": email, "password": password])
    }

    private func auth(path: String, body: [String: String]) async throws -> SupabaseSession? {
        guard !configuration.publishableKey.isEmpty else { throw SupabaseClientError.missingKey }
        guard let endpoint = URL(string: path, relativeTo: configuration.url)?.absoluteURL else { throw SupabaseClientError.badResponse }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw SupabaseClientError.badResponse }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }
}
