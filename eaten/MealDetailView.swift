//
//  MealDetailView.swift
//  eaten
//
//  One entry: the cutout, when/where you ate it, and its tags. Glass back/more
//  controls; tags edited inline.
//

import SwiftUI

struct MealDetailView: View {
    @Environment(EatenStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let meal: Meal

    @State private var showMore = false
    @State private var showDeleteConfirm = false
    @State private var showEditSource = false
    @State private var captureSource: CaptureSource?
    @State private var addingTag = false
    @State private var draftTag = ""

    /// Always read the freshest copy so tag/photo edits show immediately.
    private var current: Meal { store.meals.first { $0.id == meal.id } ?? meal }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photo
                    header
                    Rectangle()
                        .fill(Color.tagCount.opacity(0.25))
                        .frame(height: 3)               // matches the timeline line
                    tagSection
                }
                .padding(20)
                .padding(.top, 56)
                .padding(.bottom, 60)
            }

            glassControls
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .tint(.eatenViolet)
        .mealCapture(source: $captureSource) { image, _, _ in
            store.replaceImage(for: current, with: image)
        }
        .confirmationDialog("Replace photo", isPresented: $showEditSource, titleVisibility: .visible) {
            Button("Take Photo") { captureSource = .camera }
            Button("Camera Roll") { captureSource = .library }
        }
        .confirmationDialog("Delete this meal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.delete(current)
                dismiss()
            }
        }
    }

    // MARK: - Photo

    private var photo: some View {
        Group {
            if let image = store.image(for: current) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "fork.knife").font(.largeTitle).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    // MARK: - When / where

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(current.date.formatted(.dateTime.weekday(.abbreviated).month(.wide).day()).lowercased())
                    .font(.poly(22, relativeTo: .title2))
                    .foregroundStyle(Color.eatenViolet)
                Spacer()
                Text(current.date.formatted(.dateTime.hour().minute()).lowercased())
                    .font(.poly(17, relativeTo: .headline))
                    .foregroundStyle(Color.eatenViolet)
            }
            if let place = current.placeName {
                Text(place)
                    .font(.poly(15, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tags

    private var tagSection: some View {
        FlowLayout(spacing: 10) {
            ForEach(current.tags, id: \.self) { tag in
                TagPill(name: tag)
                    .onLongPressGesture { removeTag(tag) }
            }
            if addingTag {
                TextField("tag", text: $draftTag)
                    .font(.poly(15, relativeTo: .subheadline))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(width: 90)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.tagFill.opacity(0.45)))
                    .onSubmit(commitTag)
            } else {
                Button { addingTag = true } label: { AddTagPill() }
                    .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Glass controls

    private var glassControls: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.headline).frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)

            Spacer()

            Button { withAnimation(.snappy) { showMore.toggle() } } label: {
                Image(systemName: "ellipsis").font(.headline).frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
        }
        .tint(.eatenViolet)
        .padding(.horizontal, 16)
        .overlay(alignment: .topTrailing) {
            if showMore { moreMenu.padding(.top, 60).padding(.trailing, 16) }
        }
    }

    private var moreMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuButton("delete item") {
                showMore = false
                showDeleteConfirm = true
            }
            Divider()
            menuButton("edit photo") {
                showMore = false
                showEditSource = true
            }
        }
        .frame(width: 150)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
    }

    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.poly(17, relativeTo: .body))
                .foregroundStyle(Color.eatenViolet)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func commitTag() {
        let value = draftTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            store.setTags(current.tags + [value], for: current)
        }
        draftTag = ""
        addingTag = false
    }

    private func removeTag(_ tag: String) {
        store.setTags(current.tags.filter { $0 != tag }, for: current)
    }
}
