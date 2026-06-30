//
//  Models.swift
//  eaten
//
//  A single thing you ate: one photo, a timestamp, and freeform tags.
//

import Foundation

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    /// The background-removed cutout (PNG with alpha) shown everywhere.
    var imageFileName: String
    /// The downsized un-cut photo, kept as a fallback / for re-running removal.
    var originalFileName: String?
    var date: Date
    var tags: [String]
    /// Reverse-geocoded place, e.g. "Fort Mason, San Francisco, CA".
    var placeName: String?
    var latitude: Double?
    var longitude: Double?

    init(
        id: UUID = UUID(),
        imageFileName: String,
        originalFileName: String? = nil,
        date: Date = .now,
        tags: [String] = [],
        placeName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.originalFileName = originalFileName
        self.date = date
        self.tags = tags
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// One day's worth of meals, used to lay out the feed in date sections.
struct MealDay: Identifiable {
    let id: Date          // start-of-day
    let meals: [Meal]     // newest first within the day

    var title: String {
        let cal = Calendar.current
        if cal.isDateInToday(id) { return "today" }
        let fmt = DateFormatter()
        fmt.dateFormat = cal.isDate(id, equalTo: .now, toGranularity: .year)
            ? "MMMM d"
            : "MMMM d, yyyy"
        return fmt.string(from: id).lowercased()
    }
}
