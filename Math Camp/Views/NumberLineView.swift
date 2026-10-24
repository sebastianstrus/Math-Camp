//
//  NumberLineView.swift
//  Math Camp
//

import SwiftUI

/// A horizontal number line. It works with `Double` positions and a label formatter, so the same
/// view will also serve fractions and decimals in later sections.
///
/// - Interactive (place mode): touch or drag; the marker snaps to the nearest tick.
/// - Not interactive (read mode): the marker is only displayed.
struct NumberLineView: View {
    let lower: Double
    let upper: Double
    /// Distance between ticks.
    let tickStep: Double
    /// Distance between labelled ticks, counted from `lower`.
    let labelStep: Double
    /// The marker to show (the child's choice, or the target in read mode).
    var marker: Double?
    var markerColor: Color = Theme.orange
    /// The right position, shown in green after a wrong answer.
    var revealed: Double?
    var isInteractive = false
    var format: (Double) -> String = { $0.formatted() }
    var onSelect: (Double) -> Void = { _ in }

    @ScaledMetric(relativeTo: .body) private var regularHeight: CGFloat = 130
    @ScaledMetric(relativeTo: .body) private var compactHeight: CGFloat = 100
    /// Slightly below the smallest text style (11 pt), for crowded labels on small devices.
    @ScaledMetric(relativeTo: .caption2) private var crowdedLabelSize: CGFloat = 10
    @Environment(\.screenHeight) private var screenHeight
    @State private var feedbackTrigger = 0

    private let inset: CGFloat = 26

    /// Short screens trim the empty space above the axis, leaving just room for the marker.
    private var isCompact: Bool { NumericKeypad.isCompact(screenHeight: screenHeight) }
    private var height: CGFloat { isCompact ? compactHeight : regularHeight }
    private var axisFraction: CGFloat { isCompact ? 0.5 : 0.62 }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width - inset * 2, 1)
            let axisY = proxy.size.height * axisFraction

            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawAxis(context: &context, width: width, axisY: size.height * axisFraction)
                }

                if let revealed {
                    pin(color: Theme.correct)
                        .position(x: x(for: revealed, width: width), y: axisY - 24)
                }
                if let marker {
                    pin(color: markerColor)
                        .position(x: x(for: marker, width: width), y: axisY - 24)
                        .animation(.snappy(duration: 0.15), value: marker)
                }
            }
            .contentShape(Rectangle())
            .gesture(drag(width: width), isEnabled: isInteractive)
            .sensoryFeedback(.selection, trigger: feedbackTrigger)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("numberline.accessibility \(format(lower)) \(format(upper))"))
        .accessibilityValue(marker.map { Text(format($0)) } ?? Text("numberline.noMarker"))
        .accessibilityAdjustableAction { direction in
            guard isInteractive else { return }
            let current = marker ?? lower
            switch direction {
            case .increment: onSelect(min(current + tickStep, upper))
            case .decrement: onSelect(max(current - tickStep, lower))
            @unknown default: break
            }
        }
    }

    // MARK: Gesture

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { drag in
            let value = snappedValue(forX: drag.location.x, width: width)
            if value != marker {
                feedbackTrigger += 1
                onSelect(value)
            }
        }
    }

    // MARK: Geometry

    private func x(for value: Double, width: CGFloat) -> CGFloat {
        inset + CGFloat((value - lower) / (upper - lower)) * width
    }

    private func snappedValue(forX x: CGFloat, width: CGFloat) -> Double {
        let fraction = min(max(Double((x - inset) / width), 0), 1)
        let steps = ((fraction * (upper - lower)) / tickStep).rounded()
        return min(lower + steps * tickStep, upper)
    }

    // MARK: Drawing

    private func drawAxis(context: inout GraphicsContext, width: CGFloat, axisY: CGFloat) {
        var axis = Path()
        axis.move(to: CGPoint(x: inset, y: axisY))
        axis.addLine(to: CGPoint(x: inset + width, y: axisY))
        context.stroke(axis, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        let tickCount = Int(((upper - lower) / tickStep).rounded())
        let labelFont = labelFont(width: width)
        for i in 0...tickCount {
            let value = lower + Double(i) * tickStep
            let position = x(for: value, width: width)
            let labelSteps = (value - lower) / labelStep
            let isLabelled = abs(labelSteps - labelSteps.rounded()) < 1e-6

            var tick = Path()
            tick.move(to: CGPoint(x: position, y: axisY - (isLabelled ? 12 : 7)))
            tick.addLine(to: CGPoint(x: position, y: axisY + (isLabelled ? 12 : 7)))
            context.stroke(tick, with: .color(.white.opacity(isLabelled ? 0.95 : 0.55)),
                           style: StrokeStyle(lineWidth: isLabelled ? 3 : 2, lineCap: .round))

            if isLabelled {
                let label = context.resolve(
                    Text(format(value)).font(labelFont).foregroundStyle(Color.white))
                context.draw(label, at: CGPoint(x: position, y: axisY + 18), anchor: .top)
            }
        }
    }

    /// Labels like `100 … 1 000` would run into each other on a narrow line, so they get smaller there.
    private func labelFont(width: CGFloat) -> Font {
        guard isCompact else { return Theme.font(.callout) }
        let labelCount = max((upper - lower) / labelStep, 1)
        let spacing = width / CGFloat(labelCount)
        let longest = max(format(lower).count, format(upper).count)
        // Roughly 8 points per character at footnote size.
        return spacing < CGFloat(longest) * 8 ? .system(size: crowdedLabelSize, weight: .bold, design: .rounded) : Theme.font(.footnote)
    }

    /// A round head with a short stem pointing at the tick.
    private func pin(color: Color) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
            Capsule()
                .fill(color)
                .frame(width: 4, height: 14)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
    }
}
