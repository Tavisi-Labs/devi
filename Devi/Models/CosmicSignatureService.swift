// MARK: - Models/CosmicSignatureService.swift
// Generates a daily "cosmic signature" — either via Claude API or local fallback

import Foundation

@MainActor
class CosmicSignatureService {

    // MARK: - Cache

    /// UserDefaults cache keyed by "{city}-{dateString}"
    private func cachedSignature(city: String, dateString: String) -> String? {
        UserDefaults.standard.string(forKey: cosmicCacheKey(city: city, dateString: dateString))
    }

    private func cacheSignature(_ text: String, city: String, dateString: String) {
        UserDefaults.standard.set(text, forKey: cosmicCacheKey(city: city, dateString: dateString))
    }

    private func cosmicCacheKey(city: String, dateString: String) -> String {
        "cosmic.\(city).\(dateString)"
    }

    // MARK: - API Key

    /// Reads the API key from iOS Keychain or environment.
    /// Returns nil if no key is configured (falls back to offline mode).
    private var apiKey: String? {
        // Check Keychain first
        if let key = KeychainHelper.read(key: "anthropic_api_key"), !key.isEmpty {
            return key
        }
        // Fallback to Info.plist (development builds only)
        #if DEBUG
        if let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String, !key.isEmpty {
            return key
        }
        #endif
        return nil
    }

    // MARK: - Public API

    /// Fetches the cosmic signature for today. Returns cached result if available,
    /// otherwise calls Claude API or falls back to offline generation.
    func fetchSignature(panchang: DailyPanchang, city: String) async -> String {
        let dateString = panchang.dateString

        // 1. Check cache
        if let cached = cachedSignature(city: city, dateString: dateString) {
            return cached
        }

        // 2. Try Claude API if key is available
        if let key = apiKey {
            if let apiResult = await callClaudeAPI(panchang: panchang, city: city, apiKey: key) {
                cacheSignature(apiResult, city: city, dateString: dateString)
                return apiResult
            }
        }

        // 3. Offline fallback: compose from PanchangDescriptions
        let fallback = offlineFallback(panchang: panchang)
        cacheSignature(fallback, city: city, dateString: dateString)
        return fallback
    }

    // MARK: - Claude API Call

    private func callClaudeAPI(panchang: DailyPanchang, city: String, apiKey: String) async -> String? {
        let systemPrompt = """
        You are a Vedic scholar interpreting the day's cosmic alignment. \
        In 2-3 sentences, describe the unique spiritual significance of this \
        specific combination. Be poetic but grounded in Vedic tradition. \
        Do not use bullet points or lists. Write flowing prose.
        """

        let userPrompt = """
        Today's panchang for \(city):
        - Tithi: \(panchang.tithi.displayName) (ends \(panchang.tithi.endTime))
        - Nakshatra: \(panchang.nakshatra.name) (ruler: \(panchang.nakshatra.ruler), deity: \(panchang.nakshatra.deity))
        - Yoga: \(panchang.yoga.name)
        - Karana: \(panchang.karanas.map(\.name).joined(separator: ", "))
        - Vara: \(panchang.varaDeity)
        - Lunar Month: \(panchang.lunarMonth)
        - Festivals: \(panchang.festivals.isEmpty ? "None" : panchang.festivals.joined(separator: ", "))
        """

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 200,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstBlock = content.first,
               let text = firstBlock["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }

        return nil
    }

    // MARK: - Offline Fallback

    /// Composes a meaningful signature from existing PanchangDescriptions data
    private func offlineFallback(panchang: DailyPanchang) -> String {
        var parts: [String] = []

        // Tithi significance
        if let tithiInfo = PanchangDescriptions.tithiInfo(for: panchang.tithi.name) {
            parts.append("The \(tithiInfo.name) tithi, ruled by \(tithiInfo.rulingDeity), \(tithiInfo.significance.lowercased()).")
        }

        // Nakshatra quality
        if let nakInfo = PanchangDescriptions.nakshatraInfo(for: panchang.nakshatra.name) {
            parts.append("\(nakInfo.name) nakshatra (\(nakInfo.meaning)) brings the energy of \(nakInfo.presidingDeity).")
        }

        // Yoga quality
        if let yogaInfo = PanchangDescriptions.yogaInfo(forName: panchang.yoga.name) {
            parts.append("The \(yogaInfo.name) yoga (\(yogaInfo.meaning)) makes this \(yogaInfo.quality.lowercased()).")
        }

        if parts.isEmpty {
            return "Today's celestial alignment invites mindful presence and spiritual awareness."
        }

        // Take first 2-3 parts for conciseness
        return parts.prefix(3).joined(separator: " ")
    }
}

// MARK: - Simple Keychain Helper

enum KeychainHelper {
    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        // Delete any existing entry first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
