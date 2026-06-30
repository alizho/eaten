//
//  TagsView.swift
//  eaten
//
//  Every tag you've invented, as soft-green pills with usage counts.
//

import SwiftUI

struct TagsView: View {
    @Environment(EatenStore.self) private var store
    /// Selecting a tag jumps back to the feed, filtered.
    var onSelect: (String) -> Void

    @State private var showAddTag = false
    @State private var newTag = ""

    var body: some View {
        ZStack {
            Theme.background
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    FlowLayout(spacing: 12) {
                        ForEach(store.tagCounts, id: \.tag) { entry in
                            Button { onSelect(entry.tag) } label: {
                                TagPill(name: entry.tag, count: entry.count)
                            }
                            .buttonStyle(.plain)
                        }
                        Button { showAddTag = true } label: { AddTagPill() }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 130)
            }
        }
        .tint(.eatenViolet)
        .alert("New tag", isPresented: $showAddTag) {
            TextField("name", text: $newTag)
                .textInputAutocapitalization(.never)
            Button("Add") {
                store.addCustomTag(newTag)
                newTag = ""
            }
            Button("Cancel", role: .cancel) { newTag = "" }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("eaten")
                .font(.polyItalic(34, relativeTo: .largeTitle))
                .foregroundStyle(Color.eatenViolet)
            Spacer()
            Text("tags")
                .font(.poly(20, relativeTo: .title3))
                .foregroundStyle(Color.eatenViolet)
        }
    }
}
