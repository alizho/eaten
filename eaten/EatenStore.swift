//
//  EatenStore.swift
//  eaten
//
//  Owns the meals: cutout PNGs (+ a downsized original) live on disk, metadata in
//  a JSON sidecar. Deliberately simple (no SwiftData/Core Data) so it's easy to read.
//

import SwiftUI
import CoreLocation
import Observation

@Observable
final class EatenStore {
    private(set) var meals: [Meal] = []
    /// Tags the user pre-created on the tags page but hasn't used yet.
    private(set) var customTags: [String] = []

    private let fileManager = FileManager.default
    private var imageCache: [String: UIImage] = [:]

    /// Longest edge we keep for stored images — caps storage without visible loss.
    private let maxDimension: CGFloat = 1600

    init() {
        load()
    }

    // MARK: - Derived views

    /// Meals grouped into day-sections, newest day first.
    var days: [MealDay] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: meals) { cal.startOfDay(for: $0.date) }
        return groups
            .map { key, value in
                MealDay(id: key, meals: value.sorted { $0.date > $1.date })
            }
            .sorted { $0.id > $1.id }
    }

    /// Every tag (used + pre-created) with its usage count, most-used first.
    var tagCounts: [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        var order: [String] = []
        for tag in customTags where counts[tag.lowercased()] == nil {
            counts[tag.lowercased()] = 0
            order.append(tag)
        }
        for tag in meals.flatMap(\.tags) {
            let key = tag.lowercased()
            if counts[key] == nil { order.append(tag) }
            counts[key, default: 0] += 1
        }
        return order
            .map { (tag: $0, count: counts[$0.lowercased()] ?? 0) }
            .sorted { $0.count > $1.count }
    }

    /// Tag names, most-used first — for suggestions in the detail editor.
    var allTags: [String] { tagCounts.map(\.tag) }

    func meals(taggedWith tag: String) -> [Meal] {
        meals
            .filter { $0.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame } }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Mutations

    /// Saves a new meal: downsizes the photo, removes its background (on device),
    /// and stores the cutout PNG plus a downsized original as a fallback.
    func addMeal(
        image: UIImage,
        tags: [String] = [],
        date: Date = .now,
        place: PlaceInfo = PlaceInfo()
    ) {
        let original = downsized(image)
        guard let originalName = writeJPEG(original) else { return }

        // Cutout if available (device); otherwise show the original.
        let cutout = BackgroundRemover.cutout(from: original)
        let displayName = cutout.flatMap(writePNG) ?? originalName

        meals.append(Meal(
            imageFileName: displayName,
            originalFileName: originalName,
            date: date,
            tags: clean(tags),
            placeName: place.name,
            latitude: place.coordinate?.latitude,
            longitude: place.coordinate?.longitude
        ))
        save()
    }

    func setTags(_ tags: [String], for meal: Meal) {
        guard let idx = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        meals[idx].tags = clean(tags)
        save()
    }

    /// "Edit photo" on the detail screen — swap the image and re-run removal.
    func replaceImage(for meal: Meal, with image: UIImage) {
        guard let idx = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        removeFiles(for: meals[idx])

        let original = downsized(image)
        guard let originalName = writeJPEG(original) else { return }
        let cutout = BackgroundRemover.cutout(from: original)
        meals[idx].originalFileName = originalName
        meals[idx].imageFileName = cutout.flatMap(writePNG) ?? originalName
        save()
    }

    func addCustomTag(_ tag: String) {
        let value = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              !allTags.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
        else { return }
        customTags.append(value)
        save()
    }

    func delete(_ meal: Meal) {
        meals.removeAll { $0.id == meal.id }
        removeFiles(for: meal)
        save()
    }

    // MARK: - Image access

    func image(for meal: Meal) -> UIImage? { loadImage(meal.imageFileName) }

    func originalImage(for meal: Meal) -> UIImage? {
        guard let name = meal.originalFileName else { return image(for: meal) }
        return loadImage(name)
    }

    private func loadImage(_ name: String) -> UIImage? {
        if let cached = imageCache[name] { return cached }
        let url = imagesDirectory.appendingPathComponent(name)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        imageCache[name] = image
        return image
    }

    // MARK: - Persistence

    private var documents: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var imagesDirectory: URL {
        let dir = documents.appendingPathComponent("meals", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var metadataURL: URL {
        documents.appendingPathComponent("meals.json")
    }

    private var customTagsURL: URL {
        documents.appendingPathComponent("customTags.json")
    }

    private func load() {
        if let data = try? Data(contentsOf: metadataURL),
           let decoded = try? JSONDecoder().decode([Meal].self, from: data) {
            meals = decoded
        }
        if let data = try? Data(contentsOf: customTagsURL),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            customTags = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(meals) {
            try? data.write(to: metadataURL, options: .atomic)
        }
        if let data = try? JSONEncoder().encode(customTags) {
            try? data.write(to: customTagsURL, options: .atomic)
        }
    }

    // MARK: - Image storage helpers

    private func writeJPEG(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        return writeData(data, ext: "jpg", image: image)
    }

    private func writePNG(_ image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        return writeData(data, ext: "png", image: image)
    }

    private func writeData(_ data: Data, ext: String, image: UIImage) -> String? {
        let name = "\(UUID().uuidString).\(ext)"
        do {
            try data.write(to: imagesDirectory.appendingPathComponent(name))
            imageCache[name] = image
            return name
        } catch {
            print("eaten: failed to write image — \(error)")
            return nil
        }
    }

    private func removeFiles(for meal: Meal) {
        for name in [meal.imageFileName, meal.originalFileName].compactMap({ $0 }) {
            imageCache[name] = nil
            try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(name))
        }
    }

    /// Scales an image down so its longest edge is at most `maxDimension`.
    private func downsized(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func clean(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }
}
