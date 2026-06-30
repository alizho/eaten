//
//  FeedView.swift
//  eaten
//
//  The visual diary: background-removed food cutouts floating on cream, laid out
//  as a vertical timeline — newest day first, dates running down the right edge.
//

import SwiftUI

struct FeedView: View {
    @Environment(EatenStore.self) private var store
    @Binding var activeTag: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var days: [MealDay] {
        guard let activeTag else { return store.days }
        let cal = Calendar.current
        let filtered = store.meals(taggedWith: activeTag)
        return Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
            .map { MealDay(id: $0.key, meals: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        ZStack {
            Theme.background
            if store.meals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    ZStack(alignment: .topTrailing) {
                        // Continuous line behind everything; each date's cream
                        // background breaks it, connecting the dates like beads.
                        timelineLine
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                                daySection(day, isFirst: index == 0)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 130) // clear the floating glass bar
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if activeTag != nil { activeFilterBar }
        }
        .tint(.eatenViolet)
    }

    // MARK: - Sections

    @ViewBuilder
    private func daySection(_ day: MealDay, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                if isFirst {
                    Text("eaten")
                        .font(.polyItalic(34, relativeTo: .largeTitle))
                        .foregroundStyle(Color.eatenViolet)
                }
                Spacer()
                Text(day.title)
                    .font(.poly(20, relativeTo: .title3))
                    .foregroundStyle(Color.eatenViolet)
                    .padding(.leading, 12)        // cream gap masks the line behind it
                    .padding(.vertical, 2)
                    .background(Color.eatenCream)  // right edge flush with content, like "tags"
            }

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(day.meals) { meal in
                    NavigationLink(value: meal) {
                        MealThumbnail(meal: meal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// The timeline the dates sit on; their cream backgrounds break it into segments.
    private var timelineLine: some View {
        Rectangle()
            .fill(Color.tagCount.opacity(0.25))
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .padding(.trailing, 2)
    }

    private var activeFilterBar: some View {
        HStack(spacing: 8) {
            Text("filtered by")
                .font(.poly(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
            if let activeTag { TagPill(name: activeTag) }
            Spacer()
            Button("clear") { withAnimation { activeTag = nil } }
                .font(.poly(15, relativeTo: .subheadline))
                .tint(.eatenViolet)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.macro")
                .font(.system(size: 56))
                .foregroundStyle(Color.eatenViolet)
            Text("nothing eaten yet")
                .font(.poly(22, relativeTo: .title2))
            Text("Tap the camera below to snap your first meal.")
                .font(.poly(17, relativeTo: .body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

/// One cutout in the grid — the food floats on the cream background, no card.
struct MealThumbnail: View {
    @Environment(EatenStore.self) private var store
    let meal: Meal

    var body: some View {
        Group {
            if let image = store.image(for: meal) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
    }
}
