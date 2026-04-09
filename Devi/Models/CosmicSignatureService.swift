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

    /// Cache namespace — bump the suffix (e.g. `cosmic.v3.`) whenever the
    /// offline composer changes shape so users on previously-visited days
    /// see the new prose on their next visit. Orphaned old keys are harmless.
    private func cosmicCacheKey(city: String, dateString: String) -> String {
        "cosmic.v2.\(city).\(dateString)"
    }

    // MARK: - API Key

    /// Whether an API key is configured (Keychain or Info.plist)
    var hasAPIKey: Bool { apiKey != nil }

    /// Set to true when an API key was present but the API call failed
    private(set) var lastFetchAPIFailed: Bool = false

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
    /// Pass `forceRefresh: true` to bypass cache (e.g. on retry after API failure).
    func fetchSignature(panchang: DailyPanchang, city: String, forceRefresh: Bool = false) async -> String {
        let dateString = panchang.dateString

        // 1. Check cache (skip on forced refresh)
        if !forceRefresh, let cached = cachedSignature(city: city, dateString: dateString) {
            return cached
        }

        // 2. Try Claude API if key is available
        lastFetchAPIFailed = false
        if let key = apiKey {
            if let apiResult = await callClaudeAPI(panchang: panchang, city: city, apiKey: key) {
                cacheSignature(apiResult, city: city, dateString: dateString)
                return apiResult
            }
            // API key was configured but the call failed
            lastFetchAPIFailed = true
        }

        // 3. Offline fallback: compose from PanchangDescriptions
        let fallback = offlineFallback(panchang: panchang)
        // Only cache fallback when there's no API key (permanent offline mode).
        // When API key exists but call failed, don't cache — allows retry to re-attempt API.
        if !lastFetchAPIFailed {
            cacheSignature(fallback, city: city, dateString: dateString)
        }
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

    /// Composes a meaningful signature for the day with no network round-trip.
    ///
    /// Strategy:
    /// 1. Try the bundled fragment library (`cosmic_signature_library.json`)
    ///    — pick one fragment from each of the tithi / nakshatra / yoga pools
    ///    using a date-derived hash. This is the primary path and produces
    ///    essentially non-repeating prose across any realistic user horizon.
    /// 2. If any lookup misses (library gap or schema drift), fall through to
    ///    the legacy `PanchangDescriptions`-based composer so the user still
    ///    sees something meaningful instead of a blank card.
    private func offlineFallback(panchang: DailyPanchang) -> String {
        if let composed = composedFragmentSignature(panchang: panchang) {
            return composed
        }
        return legacyPanchangDescriptionsSignature(panchang: panchang)
    }

    // MARK: - Fragment Composer

    /// Fragment-composition path. Returns `nil` when any of the three pools
    /// has no entry for the day's panchang (letting the caller fall through
    /// to the legacy composer).
    ///
    /// The selection hash uses three coprime primes so the index shuffles
    /// broadly across the fragment space even when one field is constant:
    ///
    ///   hash = tithi.number * 1009
    ///        + nakshatra.number * 751
    ///        + yoga.number * 433
    private func composedFragmentSignature(panchang: DailyPanchang) -> String? {
        guard let library = Self.cosmicLibrary else { return nil }

        let tithiPool     = library.tithiFragments[panchang.tithi.displayName] ?? []
        let nakshatraPool = library.nakshatraFragments[panchang.nakshatra.name] ?? []
        let yogaPool      = library.yogaFragments[panchang.yoga.name] ?? []

        guard !tithiPool.isEmpty, !nakshatraPool.isEmpty, !yogaPool.isEmpty else {
            return nil
        }

        let hash = (panchang.tithi.number * 1009)
                 + (panchang.nakshatra.number * 751)
                 + (panchang.yoga.number * 433)
        let safeHash = abs(hash)

        let tithiFragment     = tithiPool[safeHash % tithiPool.count]
        let nakshatraFragment = nakshatraPool[safeHash % nakshatraPool.count]
        let yogaFragment      = yogaPool[safeHash % yogaPool.count]

        return [tithiFragment, nakshatraFragment, yogaFragment]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Legacy composer — kept as a graceful fallback for panchang values that
    /// the fragment library doesn't cover. Builds a 2-3 sentence prose block
    /// from the existing `PanchangDescriptions` lookup tables.
    private func legacyPanchangDescriptionsSignature(panchang: DailyPanchang) -> String {
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

    // MARK: - Cosmic Signature Library Loader

    /// Lazy-loaded fragment library. Decoded exactly once at first access.
    /// Returns `nil` when the JSON is missing or malformed — the offline
    /// fallback then uses the legacy `PanchangDescriptions` path.
    private static let cosmicLibrary: CosmicSignatureLibraryData? = {
        guard let url = Bundle.main.url(
            forResource: "cosmic_signature_library",
            withExtension: "json"
        ),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("cosmic_signature_library.json missing from bundle")
            return nil
        }
        do {
            return try JSONDecoder().decode(CosmicSignatureLibraryData.self, from: data)
        } catch {
            assertionFailure("cosmic_signature_library.json decode failed: \(error)")
            return nil
        }
    }()
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
