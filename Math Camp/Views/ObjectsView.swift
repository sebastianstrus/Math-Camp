//
//  ObjectsView.swift
//  Math Camp
//

import SwiftUI

private struct ExerciseAreaKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

extension EnvironmentValues {
    /// Visible size of the scroll area holding the exercise card, so pictures can shrink to fit it.
    var exerciseArea: CGSize? {
        get { self[ExerciseAreaKey.self] }
        set { self[ExerciseAreaKey.self] = newValue }
    }
}

/// Space left for the pictures once the card padding, instruction, answer field and spacing are taken out.
/// The card is tighter on compact screens (see `InteractiveExerciseView`), so less is reserved there.
private func pictureBudget(for area: CGSize?, compact: Bool) -> CGSize? {
    let overhead: CGFloat = compact ? 130 : 190
    let inset: CGFloat = compact ? 24 : 40
    return area.map { CGSize(width: max($0.width - inset, 100), height: max($0.height - overhead, 60)) }
}

/// Emoji to count: loose rows, groups of five, or ten-frames.
struct ObjectsView: View {
    let symbol: String
    let count: Int
    let grouping: ObjectGrouping

    @ScaledMetric(relativeTo: .largeTitle) private var baseSize: CGFloat = 40
    @Environment(\.exerciseArea) private var exerciseArea
    @Environment(\.screenHeight) private var screenHeight

    /// Rows (or ten-frames) are the blocks that get arranged in one or two columns.
    private var blockCount: Int {
        grouping == .tenFrame ? (count + 9) / 10 : rowLengths.count
    }

    /// Block size as `width = a * size + b`, `height = c * size + d`, plus the gaps between blocks.
    private var metrics: (a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, hGap: CGFloat, vGap: CGFloat) {
        switch grouping {
        case .none: (6.25, 32, 1.25, 0, 12, 8)
        case .fives: (6.25, 40, 1.25, 16, 12, 10)
        case .tenFrame: (6.25, 16, 2.5, 10, 12, 14)
        }
    }

    /// The largest size that fits `columns` columns in the budget.
    private func fittedSize(columns: Int, budget: CGSize) -> CGFloat {
        let m = metrics
        let rows = CGFloat((blockCount + columns - 1) / columns)
        let k = CGFloat(columns)
        let byHeight = (budget.height - rows * m.d - (rows - 1) * m.vGap) / (rows * m.c)
        let byWidth = (budget.width - k * m.b - (k - 1) * m.hGap) / (k * m.a)
        return min(baseSize, byHeight, byWidth)
    }

    /// One column at full size when it fits, otherwise two columns and a smaller size.
    private var layout: (columns: Int, size: CGFloat) {
        guard let budget = pictureBudget(for: exerciseArea, compact: NumericKeypad.isCompact(screenHeight: screenHeight)) else {
            return (1, baseSize)
        }
        let one = fittedSize(columns: 1, budget: budget)
        guard one < baseSize * 0.75, blockCount > 1 else { return (1, max(one, 16)) }
        return (2, max(fittedSize(columns: 2, budget: budget), 16))
    }

    private var size: CGFloat { layout.size }

    var body: some View {
        let columns = layout.columns
        // A grid keeps the columns lined up, even when the last row is shorter.
        Grid(alignment: .leading, horizontalSpacing: metrics.hGap, verticalSpacing: metrics.vGap) {
            ForEach(Array(stride(from: 0, to: blockCount, by: columns)), id: \.self) { first in
                GridRow {
                    ForEach(first..<min(first + columns, blockCount), id: \.self) { block(at: $0) }
                }
            }
        }
        // Each object is its own element, so a VoiceOver user can count by swiping.
        .accessibilityElement(children: .contain)
    }

    private var rowLengths: [Int] {
        stride(from: 0, to: count, by: 5).map { min(5, count - $0) }
    }

    @ViewBuilder
    private func block(at index: Int) -> some View {
        switch grouping {
        case .none:
            HStack(spacing: 8) {
                ForEach(0..<rowLengths[index], id: \.self) { _ in object() }
            }
        case .fives:
            HStack(spacing: 6) {
                ForEach(0..<rowLengths[index], id: \.self) { _ in object() }
            }
            .padding(8)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        case .tenFrame:
            tenFrame(filled: min(10, count - index * 10))
        }
    }

    private func object() -> some View {
        Text(symbol)
            .font(.system(size: size))
            .frame(width: size * 1.25, height: size * 1.25)
            .accessibilityLabel(Text("count.object.accessibility"))
    }

    private func tenFrame(filled: Int) -> some View {
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

    @ScaledMetric(relativeTo: .title) private var baseSize: CGFloat = 30
    @Environment(\.exerciseArea) private var exerciseArea
    @Environment(\.screenHeight) private var screenHeight

    /// Emoji size, shrunk on small screens so all groups stay visible (two boxes per row) next to the answer field.
    private var size: CGFloat {
        guard let budget = pictureBudget(for: exerciseArea, compact: NumericKeypad.isCompact(screenHeight: screenHeight)) else {
            return baseSize
        }
        let perRow = CGFloat(min(perGroup, 5))
        let innerRows = CGFloat(rows.count)
        let oneColumn = fittedSize(columns: 1, budget: budget, perRow: perRow, innerRows: innerRows)
        guard oneColumn < baseSize * 0.75, groups > 1 else { return max(oneColumn, 14) }
        return max(fittedSize(columns: 2, budget: budget, perRow: perRow, innerRows: innerRows), 14)
    }

    private func fittedSize(columns: Int, budget: CGSize, perRow: CGFloat, innerRows: CGFloat) -> CGFloat {
        let k = CGFloat(columns)
        let boxRows = CGFloat((groups + columns - 1) / columns)
        // Box = emoji grid + 10pt padding on each side; boxes are 10pt apart.
        let byHeight = (budget.height - boxRows * (20 + 4 * (innerRows - 1)) - (boxRows - 1) * 10) / (boxRows * innerRows * 1.3)
        let byWidth = (budget.width - k * (20 + 4 * (perRow - 1)) - (k - 1) * 10) / (k * perRow * 1.3)
        return min(baseSize, byHeight, byWidth)
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size * 1.3 * CGFloat(min(perGroup, 5)) + 28), spacing: 10)], spacing: 10) {
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
