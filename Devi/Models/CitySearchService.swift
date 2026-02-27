// MARK: - Models/CitySearchService.swift
// Global city search via MapKit + reverse geocoding via CLGeocoder

import Foundation
import MapKit
import CoreLocation

@MainActor
class CitySearchService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false

    // MARK: - Private

    private let completer = MKLocalSearchCompleter()
    private let geocoder = CLGeocoder()

    // MARK: - Init

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    // MARK: - Search

    /// Update the type-ahead query. Empty string clears suggestions.
    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = trimmed
    }

    /// Cancel any in-flight completer query.
    func cancel() {
        completer.cancel()
        suggestions = []
        isSearching = false
    }

    // MARK: - Resolve a Search Completion → UserCity

    /// Taps a search result and resolves it to a full UserCity with coordinates + timezone.
    func resolveCity(from completion: MKLocalSearchCompletion) async throws -> UserCity {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let item = response.mapItems.first else {
            throw CitySearchError.noResults
        }

        let placemark = item.placemark

        let name = placemark.locality
            ?? placemark.name
            ?? placemark.administrativeArea
            ?? "Unknown"
        let country = placemark.isoCountryCode ?? "??"
        let tz = placemark.timeZone ?? TimeZone.current

        return UserCity(
            name: name,
            country: country,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            timezoneIdentifier: tz.identifier
        )
    }

    // MARK: - Reverse Geocode GPS → UserCity

    /// Converts a GPS location to a UserCity via Apple's geocoder.
    func reverseGeocode(location: CLLocation) async throws -> UserCity {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw CitySearchError.noResults
        }

        let name = placemark.locality
            ?? placemark.name
            ?? placemark.administrativeArea
            ?? "Unknown"
        let country = placemark.isoCountryCode ?? "??"
        let tz = placemark.timeZone ?? TimeZone.current

        return UserCity(
            name: name,
            country: country,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timezoneIdentifier: tz.identifier
        )
    }

    // MARK: - Errors

    enum CitySearchError: LocalizedError {
        case noResults

        var errorDescription: String? {
            switch self {
            case .noResults:
                return "Could not load city details. Please try again."
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension CitySearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
            self.isSearching = false
        }
    }
}
