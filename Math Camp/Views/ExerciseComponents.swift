//
//  ExerciseComponents.swift
//  Math Camp
//

import SwiftUI

/// A box the child fills in. Highlighted while active, green/red after checking.
struct AnswerSlot: View {
    let text: String
    let isActive: Bool
    /// `nil` before checking.
    let isCorrect: Bool?
    var font: Font = Theme.equationFont
    /// A narrower box, for rows with many boxes (sequences).
    var compact = false
    let action: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var minWidth: CGFloat = 64
    @ScaledMetric(relativeTo: .largeTitle) private var minHeight: CGFloat = 56

    var body: some View {
        Button(action: action) {
            Text(text.isEmpty ? " " : text)
                .font(font)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, compact ? 6 : 10)
                .frame(minWidth: compact ? minWidth * 0.75 : minWidth, minHeight: max(minHeight, Theme.minTouch))
                .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(border, lineWidth: isActive ? 3 : 1.5)
                }
                .shadow(color: isActive ? Theme.yellow.opacity(0.55) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.18), value: isActive)
    }

    private var fill: Color {
        switch isCorrect {
        case true?: Theme.correct.opacity(0.25)
        case false?: Theme.wrong.opacity(0.25)
        case nil: Color.white.opacity(isActive ? 0.22 : 0.12)
        }
    }

    private var border: Color {
        switch isCorrect {
        case true?: Theme.correct
        case false?: Theme.wrong
        case nil: isActive ? Theme.yellow : Color.white.opacity(0.4)
        }
    }
}

/// One line of text and slots, for example `47 + 32 = [ ]`.
struct PromptLine: View {
    let parts: [PromptPart]
    let slots: [String]
    /// The active slot of this exercise, or `nil` if the exercise is not the active one.
    let activeSlot: Int?
    /// `nil` before checking.
    let isCorrect: Bool?
    let formatter: PromptFormatter
    /// Starts one font step lower on small devices (place-value rows).
    var shrinksOnCompact = false
    let onSelect: (Int) -> Void

    @Environment(\.screenHeight) private var screenHeight

    var body: some View {
        // Long sentences such as `(25 + 15) − (12 + 8) = ?` drop to a smaller font instead of overflowing.
        if shrinksOnCompact && NumericKeypad.isCompact(screenHeight: screenHeight) {
            // Small devices: narrower boxes and tighter spacing so `× 10` and `× 1` are not cut off.
            ViewThatFits(in: .horizontal) {
                line(font: Theme.font(.title2), tight: true)
                line(font: Theme.font(.headline), tight: true)
                line(font: Theme.font(.subheadline), tight: true)
            }
        } else {
            ViewThatFits(in: .horizontal) {
                line(font: Theme.font(.largeTitle))
                line(font: Theme.font(.title))
                line(font: Theme.font(.title2))
                line(font: Theme.font(.headline))
            }
        }
    }

    private func line(font: Font, tight: Bool = false) -> some View {
        HStack(spacing: tight ? 4 : 8) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                switch part {
                case .text(let text, _):
                    Text(text)
                        .font(font)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                case .slot(let index):
                    AnswerSlot(text: slotText(index), isActive: activeSlot == index,
                               isCorrect: isCorrect, font: font, compact: tight) { onSelect(index) }
                case .fraction(let numerator, let denominator):
                    VStack(spacing: 2) {
                        field(numerator, font: font)
                        Rectangle().fill(Theme.textPrimary).frame(height: 3)
                        field(denominator, font: font)
                    }
                    .fixedSize()
                }
            }
        }
    }

    /// One half of a stacked fraction.
    @ViewBuilder
    private func field(_ field: FractionField, font: Font) -> some View {
        switch field {
        case .number(let value):
            Text(value, format: .number)
                .font(font)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
        case .slot(let index):
            AnswerSlot(text: slotText(index), isActive: activeSlot == index, isCorrect: isCorrect,
                       font: font, compact: true) { onSelect(index) }
        }
    }

    private func slotText(_ index: Int) -> String {
        slots.indices.contains(index) ? formatter.display(slot: slots[index]) : ""
    }
}

/// One exercise of a drill task: number, line, mark and (after checking) the right answer.
struct ExerciseRow: View {
    let session: TaskSession
    let index: Int
    let formatter: PromptFormatter

    private var exercise: Exercise { session.exercises[index] }
    private var isActive: Bool { session.activeExercise == index && !session.isChecked }
    private var result: Bool? { session.isChecked ? session.correctness[index] : nil }
    @Environment(\.screenHeight) private var screenHeight
    /// Place-value rows on small devices get less padding and spacing.
    private var tightRow: Bool { isPlaceValue && NumericKeypad.isCompact(screenHeight: screenHeight) }
    private var isPlaceValue: Bool {
        if case .placeValue = exercise.prompt { return true }
        return false
    }

    var body: some View {
        let parts = formatter.parts(for: exercise.prompt)

        HStack(alignment: .center, spacing: tightRow ? 6 : 12) {
            Text(index + 1, format: .number)
                .font(Theme.font(.footnote))
                .foregroundStyle(Theme.textSecondary)
                .frame(minWidth: tightRow ? 16 : 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                PromptLine(parts: parts, slots: session.slots[index],
                           activeSlot: isActive ? session.activeSlot : nil,
                           isCorrect: result, formatter: formatter,
                           shrinksOnCompact: isPlaceValue) { slot in
                    session.select(exercise: index, slot: slot)
                }
                if result == false {
                    Text("task.correctAnswer \(formatter.display(answer: exercise.answer))")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.correct)
                }
            }

            Spacer(minLength: 0)

            if let result {
                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(result ? Theme.correct : Theme.wrong)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, tightRow ? 8 : 14)
        .padding(.vertical, 10)
        .frame(minHeight: 72)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.12 : 0.05))
        }
        .animation(.snappy(duration: 0.2), value: isActive)
        // One VoiceOver element per row: "47 plus 32 equals blank".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(formatter.spokenSentence(parts, slots: session.slots[index]))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { session.select(exercise: index) }
        .accessibilityActions {
            if exercise.slotCount > 1 {
                ForEach(0..<exercise.slotCount, id: \.self) { slot in
                    Button("task.editSlot \(slot + 1)") { session.select(exercise: index, slot: slot) }
                }
            }
        }
    }

    private var accessibilityValue: String {
        guard let result else { return "" }
        if result { return String(localized: "task.accessibility.correct") }
        let answer = String(localized: "task.correctAnswer \(formatter.display(answer: exercise.answer))")
        return String(localized: "task.accessibility.wrong") + ". " + answer
    }
}
