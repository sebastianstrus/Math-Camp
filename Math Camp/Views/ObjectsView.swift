//
//  ObjectsView.swift
//  Math Camp
//

import SwiftUI

/// Emoji to count: loose rows, groups of five, or ten-frames.
struct ObjectsView: View {
    let symbol: String
    let count: Int
    let grouping: ObjectGrouping

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 40

    var body: some View {
        Group {
            switch grouping {
            case .none: looseRows
            case .fives: groupsOfFive
            case .tenFrame: tenFrames
            }
        }
        // Each object is its own element, so a VoiceOver user can count by swiping.
        .accessibilityElement(children: .contain)
    }

    private var rowLengths: [Int] {
        stride(from: 0, to: count, by: 5).map { min(5, count - $0) }
    }

    private func object() -> some View {
        Text(symbol)
            .font(.system(size: size))
            .frame(width: size * 1.25, height: size * 1.25)
            .accessibilityLabel(Text("count.object.accessibility"))
    }

    private var looseRows: some View {
        VStack(spacing: 8) {
            ForEach(Array(rowLengths.enumerated()), id: \.offset) { _, length in
                HStack(spacing: 8) {
                    ForEach(0..<length, id: \.self) { _ in object() }
                }
            }
        }
    }

    private var groupsOfFive: some View {
        VStack(spacing: 10) {
            ForEach(Array(rowLengths.enumerated()), id: \.offset) { _, length in
                HStack(spacing: 6) {
                    ForEach(0..<length, id: \.self) { _ in object() }
                }
                .padding(8)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var tenFrames: some View {
        VStack(spacing: 14) {
            ForEach(0..<((count + 9) / 10), id: \.self) { frame in
                let filled = min(10, count - frame * 10)
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    ForEach(0..<2, id: \.self) { row in
                        GridRow {
                            ForEach(0..<5, id: \.self) { column in
                                cell(isFilled: row * 5 + column < filled)
                            }
                        }
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func cell(isFilled: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.navyDeep)
            if isFilled {
                Text(symbol)
                    .font(.system(size: size * 0.9))
                    .accessibilityLabel(Text("count.object.accessibility"))
            }
        }
        .frame(width: size * 1.25, height: size * 1.25)
        .accessibilityHidden(!isFilled)
    }
}

/// Equal groups: `3 groups of 4`, each group in its own rounded box.
struct GroupsView: View {
    let symbol: String
    let groups: Int
    let perGroup: Int

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 30

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size * 1.3 * 5 + 28), spacing: 10)], spacing: 10) {
            ForEach(0..<groups, id: \.self) { _ in
                VStack(spacing: 4) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, length in
                        HStack(spacing: 4) {
                            ForEach(0..<length, id: \.self) { _ in
                                Text(symbol)
                                    .font(.system(size: size))
                                    .frame(width: size * 1.3, height: size * 1.3)
                                    .accessibilityLabel(Text("count.object.accessibility"))
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .contain)
            }
        }
    }

    private var rows: [Int] {
        stride(from: 0, to: perGroup, by: 5).map { min(5, perGroup - $0) }
    }
}
