//
//  PuzzleViews.swift
//  Math Camp
//
//  Pictures for the exercises of Sections IV–VII.
//

import SwiftUI

// MARK: - Clock

/// An analog clock face with hour and minute hands.
struct ClockFaceView: View {
    let hour: Int
    let minute: Int

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            Canvas { context, canvas in
                let center = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
                let radius = size / 2 - 4

                // Face
                let face = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                  width: radius * 2, height: radius * 2))
                context.fill(face, with: .color(Color.white.opacity(0.12)))
                context.stroke(face, with: .color(.white.opacity(0.9)), lineWidth: 4)

                // Minute and hour ticks
                for tick in 0..<60 {
                    let angle = Angle.degrees(Double(tick) * 6 - 90).radians
                    let isHour = tick % 5 == 0
                    let inner = radius * (isHour ? 0.88 : 0.93)
                    var path = Path()
                    path.move(to: point(center, radius * 0.97, angle))
                    path.addLine(to: point(center, inner, angle))
                    context.stroke(path, with: .color(.white.opacity(isHour ? 0.9 : 0.4)),
                                   lineWidth: isHour ? 3 : 1.5)
                }

                // Numerals
                for number in 1...12 {
                    let angle = Angle.degrees(Double(number) * 30 - 90).radians
                    let label = context.resolve(Text(number, format: .number)
                        .font(Theme.font(.title3)).foregroundStyle(Color.white))
                    context.draw(label, at: point(center, radius * 0.72, angle))
                }

                // Hands
                let minuteAngle = Angle.degrees(Double(minute) * 6 - 90).radians
                let hourAngle = Angle.degrees((Double(hour % 12) + Double(minute) / 60) * 30 - 90).radians
                var hourHand = Path()
                hourHand.move(to: center)
                hourHand.addLine(to: point(center, radius * 0.45, hourAngle))
                context.stroke(hourHand, with: .color(Theme.orange), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                var minuteHand = Path()
                minuteHand.move(to: center)
                minuteHand.addLine(to: point(center, radius * 0.68, minuteAngle))
                context.stroke(minuteHand, with: .color(Theme.yellow), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)),
                             with: .color(.white))
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 280)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("clock.accessibility"))
    }

    private func point(_ center: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
    }
}

// MARK: - Fraction picture

/// A bar, circle or grid divided into equal parts, with some parts shaded.
struct FractionPictureView: View {
    let fraction: Fraction
    let shape: FractionShape
    var accent: Color = Theme.orange

    var body: some View {
        Group {
            switch shape {
            case .bar: bar
            case .circle: circle
            case .grid: grid
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("fractionPicture.accessibility \(fraction.denominator)"))
    }

    private var bar: some View {
        HStack(spacing: 3) {
            ForEach(0..<fraction.denominator, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(index < fraction.numerator ? accent : Color.white.opacity(0.14))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
            }
        }
        .frame(maxWidth: 320)
        .frame(height: 64)
    }

    private var circle: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 3
            let parts = fraction.denominator
            for index in 0..<parts {
                let start = Angle.degrees(Double(index) * 360 / Double(parts) - 90)
                let end = Angle.degrees(Double(index + 1) * 360 / Double(parts) - 90)
                var slice = Path()
                slice.move(to: center)
                slice.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                slice.closeSubpath()
                context.fill(slice, with: .color(index < fraction.numerator ? accent : Color.white.opacity(0.14)))
                context.stroke(slice, with: .color(.white.opacity(0.8)), lineWidth: 2)
            }
        }
        .frame(width: 180, height: 180)
    }

    private var grid: some View {
        let columns = gridColumns
        let rows = (fraction.denominator + columns - 1) / columns
        return Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        if index < fraction.denominator {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(index < fraction.numerator ? accent : Color.white.opacity(0.14))
                                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
    }

    private var gridColumns: Int {
        let d = fraction.denominator
        if d == 9 { return 3 }
        if d % 4 == 0 { return 4 }
        if d % 5 == 0 { return 5 }
        if d % 3 == 0 { return 3 }
        return d
    }
}

// MARK: - Balance scale

/// A balanced scale: weights on both pans, one of them unknown (an answer slot).
struct BalanceScaleView: View {
    let left: [Int?]
    let right: [Int?]
    /// The view of the unknown weight.
    let unknown: AnyView

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.textPrimary.opacity(0.9))
                .frame(height: 10)
            HStack(alignment: .top, spacing: 16) {
                pan(left)
                pan(right)
            }
            .padding(.top, 4)
            Triangle()
                .fill(Theme.textPrimary.opacity(0.35))
                .frame(width: 60, height: 36)
                .padding(.top, 8)
        }
        .frame(maxWidth: 420)
        .accessibilityElement(children: .contain)
    }

    private func pan(_ weights: [Int?]) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Array(weights.enumerated()), id: \.offset) { _, weight in
                    if let weight {
                        Text(weight, format: .number)
                            .font(Theme.font(.title2))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(minWidth: 48, minHeight: 48)
                            .background(Theme.blue.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        unknown
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.purple.opacity(0.7))
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Magic square

/// A 3×3 grid; the blanks are answer slots numbered in reading order.
struct MagicSquareView: View {
    let cells: [Int?]
    let slotText: (Int) -> String
    let activeSlot: Int?
    let isCorrect: Bool?
    let onSelect: (Int) -> Void

    var body: some View {
        let slotIndex = blankIndices
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        if let value = cells[index] {
                            Text(value, format: .number)
                                .font(Theme.font(.title))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(minWidth: 64, minHeight: 64)
                                .background(Theme.blue.opacity(0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else if let slot = slotIndex[index] {
                            AnswerSlot(text: slotText(slot), isActive: activeSlot == slot, isCorrect: isCorrect,
                                       font: Theme.font(.title), compact: true) { onSelect(slot) }
                                .accessibilityLabel(Text("magic.cell \(row + 1) \(column + 1)"))
                        }
                    }
                }
            }
        }
    }

    /// Maps a cell index to its slot number.
    private var blankIndices: [Int: Int] {
        var result: [Int: Int] = [:]
        for index in cells.indices where cells[index] == nil { result[index] = result.count }
        return result
    }
}

// MARK: - Column arithmetic

/// Numbers written one under the other, with the operation sign and a line.
struct ColumnArithmeticView: View {
    let top: Int
    let bottom: Int
    /// `+`, `−` or `×` in the current notation.
    let symbol: String
    let answerText: String
    let isActive: Bool
    let isCorrect: Bool?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(String(top))
            HStack(spacing: 16) {
                Text(symbol).foregroundStyle(Theme.yellow)
                Text(String(bottom))
            }
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.9))
                .frame(height: 4)
            AnswerSlot(text: answerText, isActive: isActive, isCorrect: isCorrect, action: action)
        }
        .font(Theme.font(.largeTitle).monospacedDigit())
        .foregroundStyle(Theme.textPrimary)
        .fixedSize()
        .padding(.horizontal, 8)
        .accessibilityElement(children: .contain)
    }
}
