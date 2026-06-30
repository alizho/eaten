//
//  ContentView.swift
//  eaten
//
//  Root shell: the screens, a custom floating Liquid Glass nav bar, and an inline
//  glass capture selector (no separate Add page).
//

import SwiftUI

enum AppTab: Hashable {
    case feed, tags
}

struct ContentView: View {
    @State private var store = EatenStore()
    @State private var tab: AppTab = .feed
    @State private var activeTag: String?
    @State private var feedPath: [Meal] = []
    @State private var showCaptureMenu = false
    @State private var captureSource: CaptureSource?

    /// Hide the floating bar while a detail page is pushed.
    private var barVisible: Bool { tab == .tags || feedPath.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .feed:
                    NavigationStack(path: $feedPath) {
                        FeedView(activeTag: $activeTag)
                            .navigationDestination(for: Meal.self) { MealDetailView(meal: $0) }
                    }
                case .tags:
                    TagsView { tag in
                        activeTag = tag
                        withAnimation(.snappy) { tab = .feed }
                    }
                }
            }

            if barVisible {
                VStack(alignment: .trailing, spacing: 12) {
                    if showCaptureMenu { captureMenu }
                    GlassNavBar(
                        tab: $tab,
                        onCamera: { withAnimation(.snappy) { showCaptureMenu.toggle() } }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: barVisible)
        .environment(store)
        .mealCapture(source: $captureSource) { image, place, date in
            store.addMeal(image: image, date: date, place: place)
            tab = .feed
        }
    }

    /// Liquid Glass popover that replaces the old Add page.
    private var captureMenu: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 2) {
                captureButton("take photo", "camera.fill") { captureSource = .camera }
                Divider().opacity(0.4)
                captureButton("camera roll", "photo.on.rectangle") { captureSource = .library }
            }
            .frame(width: 180)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing)))
    }

    private func captureButton(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { showCaptureMenu = false }
            action()
        } label: {
            HStack {
                Text(title).font(.poly(17, relativeTo: .body))
                Spacer()
                Image(systemName: icon)
            }
            .foregroundStyle(Color.eatenViolet)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }
}

/// Floating bar: two tabs in a glass capsule + a prominent violet capture button.
struct GlassNavBar: View {
    @Binding var tab: AppTab
    var onCamera: () -> Void
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                Spacer()
                HStack(spacing: 6) {
                    tabButton(.feed, "square.grid.2x2.fill")
                    tabButton(.tags, "tag.fill")
                }
                .padding(6)
                .glassEffect(.regular, in: .capsule)
                .glassEffectID("bar", in: glass)

                Button(action: onCamera) {
                    Image(systemName: "camera.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                }
                .background(Color.eatenViolet, in: Circle())
                .glassEffect(.regular.interactive(), in: .circle)
                .glassEffectID("add", in: glass)
            }
        }
    }

    private func tabButton(_ target: AppTab, _ icon: String) -> some View {
        let selected = tab == target
        return Button {
            withAnimation(.snappy) { tab = target }
        } label: {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(selected ? Color.eatenViolet : Color.eatenViolet.opacity(0.4))
                .frame(width: 52, height: 48)
                .background {
                    if selected {
                        Capsule().fill(Color.eatenViolet.opacity(0.16))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
