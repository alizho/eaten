//
//  UIComponents.swift
//  eaten
//
//  Small shared bits: tag chips and a wrapping layout for them.
//

import SwiftUI

/// The signature soft-green tag pill: "name xN".
/// Fill #C8DFB5 @ 45%, name #5D714F, count #94B57D @ 65%.
struct TagPill: View {
    let name: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.poly(15, relativeTo: .subheadline))
                .foregroundStyle(Color.tagName)
            if let count {
                Text("x\(count)")
                    .font(.poly(15, relativeTo: .subheadline))
                    .foregroundStyle(Color.tagCount.opacity(0.65))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Capsule().fill(Color.tagFill.opacity(0.45)))
    }
}

/// A circular "+" pill matching the tag style, for adding tags.
struct AddTagPill: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.tagCount)
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.tagFill.opacity(0.45)))
    }
}

/// Simple wrapping HStack so an arbitrary number of tags flow onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(size)
            x += size.width + spacing
        }
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + (row.map(\.height).max() ?? 0) + spacing
        }
        return CGSize(width: maxWidth, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
