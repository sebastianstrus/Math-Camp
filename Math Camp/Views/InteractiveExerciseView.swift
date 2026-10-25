//
//  InteractiveExerciseView.swift
//  Math Camp
//

import SwiftUI

/// One exercise per screen: counting, number lines, patterns, pictures, puzzles and word problems.
/// Exercises that are plain equations (for example "Equal Groups" in Climb and Peak) use the same card.
struct InteractiveExerciseView: View {
    let session: TaskSession
    let index: Int
    let formatter: PromptFormatter

    @Environment(\.screenHeight) private var screenHeight

    private var isCompact: Bool { NumericKeypad.isCompact(screenHeight: screenHeight) }
    private var exercise: Exercise { session.exercises[index] }
    private var result: Bool? { session.isChecked ? session.correctness[index] : nil }

    var body: some View {
        VStack(spacing: isCompact ? 10 : 20) {
            instruction
                .font(Theme.font(.headline, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            content

            if result == false {
                Text("task.correctAnswer \(formatter.display(answer: exercise.answer))")
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.correct)
            }
        }
        .padding(isCompact ? 12 : 20)
        .frame(maxWidth: .infinity)
        .themeCard()
    }

    // MARK: Instruction

    @ViewBuilder
    private var instruction: some View {
        switch exercise.prompt {
        case .countObjects: Text("instruction.count")
        case .groups: Text("instruction.groups")
        case .numberLine(_, .place, let target):
            Text("instruction.numberline.place \(target.formatted(.number.locale(formatter.locale)))")
        case .numberLine(_, .read, _): Text("instruction.numberline.read")
        case .sequence: Text("instruction.sequence")
        case .rulePattern: Text("instruction.pattern")
        case .wordProblem: Text("instruction.wordproblem")
        case .column: Text("instruction.column")
        case .fractionPicture: Text("instruction.fractionPicture")
        case .fractionNumberLine(let denominator, let numerator, .place):
            Text("instruction.fractionline.place \(String(numerator) + "/" + String(denominator))")
        case .fractionNumberLine(_, _, .read): Text("instruction.fractionline.read")
        case .decimalNumberLine(let config, .place, let target):
            Text("instruction.numberline.place \(formatter.decimalText(ScaledDecimal(value: target, scale: config.scale)))")
        case .decimalNumberLine(_, .read, _): Text("instruction.decimalline.read")
        case .clock: Text("instruction.clock")
        case .calendar: Text("instruction.calendar")
        case .balance: Text("instruction.balance")
        case .magicSquare(_, let sum): Text("instruction.magic \(sum)")
        default: Text("instruction.fill")
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch exercise.prompt {
        case .countObjects(let symbol, let count, let grouping):
            ObjectsView(symbol: symbol, count: count, grouping: grouping)
            slot(0)

        case .groups(let symbol, let groups, let perGroup):
            GroupsView(symbol: symbol, groups: groups, perGroup: perGroup)
            slot(0)

        case .numberLine(let config, let mode, let target):
            numberLine(config, mode: mode, target: target)

        case .sequence(let terms):
            sequence(terms)

        case .rulePattern(let start, let length, let rule, let gaps):
            let terms = rule.terms(start: start, length: length)
            sequence(terms.indices.map { gaps.contains($0) ? nil : terms[$0] })

        case .wordProblem(let templateID, let values, let names):
            Text(WordProblemText.string(templateID: templateID, values: values, names: names))
                .font(Theme.font(.title3, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            slot(0)

        case .column(let a, let b, let operation):
            ColumnArithmeticView(
                top: a, bottom: b,
                symbol: formatter.notation.symbol(for: operation.token, locale: formatter.locale),
                answerText: formatter.display(slot: session.slots[index][0]),
                isActive: !session.isChecked && session.activeSlot == 0, isCorrect: result
            ) { session.select(exercise: index, slot: 0) }

        case .fractionPicture(let fraction, let shape):
            FractionPictureView(fraction: fraction, shape: shape)
            line

        case .fractionNumberLine(let denominator, let numerator, let mode):
            fractionLine(denominator: denominator, numerator: numerator, mode: mode)

        case .decimalNumberLine(let config, let mode, let target):
            decimalLine(config, mode: mode, target: target)

        case .clock(let hour, let minute):
            ClockFaceView(hour: hour, minute: minute)
            line

        case .calendar(let question):
            Text(formatter.calendarText(question))
                .font(Theme.font(.title3, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            slot(0)

        case .balance(let left, let right):
            BalanceScaleView(left: left, right: right, unknown: AnyView(slot(0, compact: true)))

        case .magicSquare(let cells, _):
            MagicSquareView(
                cells: cells,
                slotText: { formatter.display(slot: session.slots[index][$0]) },
                activeSlot: session.isChecked ? nil : session.activeSlot,
                isCorrect: result
            ) { session.select(exercise: index, slot: $0) }

        default:
            // Plain equations and similar prompts reuse the drill line.
            line
        }
    }

    /// The answer line built from the prompt parts (equations, fractions, clock times).
    private var line: some View {
        PromptLine(parts: formatter.parts(for: exercise.prompt), slots: session.slots[index],
                   activeSlot: session.isChecked ? nil : session.activeSlot,
                   isCorrect: result, formatter: formatter, labelOnOwnLine: hasLabelLine) { slot in
            session.select(exercise: index, slot: slot)
        }
    }

    private var hasLabelLine: Bool {
        switch exercise.prompt {
        case .rounding, .estimation: return true
        default: return false
        }
    }

    private func slot(_ slotIndex: Int, compact: Bool = false) -> some View {
        AnswerSlot(text: formatter.display(slot: session.slots[index][slotIndex]),
                   isActive: !session.isChecked && session.activeSlot == slotIndex,
                   isCorrect: result, compact: compact) {
            session.select(exercise: index, slot: slotIndex)
        }
        .accessibilityLabel(Text("task.answer"))
    }

    private var markerColor: Color {
        switch result {
        case true?: Theme.correct
        case false?: Theme.wrong
        case nil: Theme.orange
        }
    }

    // MARK: Number lines

    @ViewBuilder
    private func numberLine(_ config: NumberLineConfig, mode: NumberLineMode, target: Int) -> some View {
        let chosen = Double(session.slots[index][0])
        NumberLineView(
            lower: Double(config.lower), upper: Double(config.upper),
            tickStep: Double(config.tickStep), labelStep: Double(config.labelStep),
            marker: mode == .place ? chosen : Double(target),
            markerColor: mode == .place ? markerColor : Theme.orange,
            revealed: (mode == .place && result == false) ? Double(target) : nil,
            isInteractive: mode == .place && !session.isChecked,
            // No thousands separator: on a narrow line the `1` of `1 000` reads as part of `900`.
            format: { Int($0).formatted(.number.grouping(.never).locale(formatter.locale)) }
        ) { value in
            session.setSlot(String(Int(value)), exercise: index)
        }

        if mode == .read { slot(0) }
    }

    @ViewBuilder
    private func fractionLine(denominator: Int, numerator: Int, mode: NumberLineMode) -> some View {
        let parts = Double(denominator)
        let chosen = Double(session.slots[index][0]).map { $0 / parts }
        NumberLineView(
            lower: 0, upper: 1, tickStep: 1 / parts, labelStep: 1,
            marker: mode == .place ? chosen : Double(numerator) / parts,
            markerColor: mode == .place ? markerColor : Theme.orange,
            revealed: (mode == .place && result == false) ? Double(numerator) / parts : nil,
            isInteractive: mode == .place && !session.isChecked,
            format: { $0 < 0.5 ? "0" : "1" }
        ) { value in
            session.setSlot(String(Int((value * parts).rounded())), exercise: index)
        }

        if mode == .read { line }
    }

    @ViewBuilder
    private func decimalLine(_ config: DecimalLineConfig, mode: NumberLineMode, target: Int) -> some View {
        let factor = pow(10, Double(config.scale))
        let chosen = ExpectedAnswer.scaledValue(of: session.slots[index][0], scale: config.scale).map { Double($0) / factor }
        NumberLineView(
            lower: Double(config.lower) / factor, upper: Double(config.upper) / factor,
            tickStep: Double(config.tickStep) / factor, labelStep: Double(config.labelStep) / factor,
            marker: mode == .place ? chosen : Double(target) / factor,
            markerColor: mode == .place ? markerColor : Theme.orange,
            revealed: (mode == .place && result == false) ? Double(target) / factor : nil,
            isInteractive: mode == .place && !session.isChecked,
            format: { formatter.decimalText(ScaledDecimal(value: Int(($0 * factor).rounded()), scale: config.scale)) }
        ) { value in
            session.setSlot(ExpectedAnswer.decimalText(Int((value * factor).rounded()), scale: config.scale), exercise: index)
        }

        if mode == .read { slot(0) }
    }

    // MARK: Sequence

    private func sequence(_ terms: [Int?]) -> some View {
        // Gaps are numbered in reading order; they are the answer slots.
        var gapIndex = 0
        let cells: [(term: Int?, gap: Int?)] = terms.map { term in
            guard term == nil else { return (term, nil) }
            defer { gapIndex += 1 }
            return (nil, gapIndex)
        }

        return HStack(spacing: 6) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                if let gap = cell.gap {
                    AnswerSlot(text: formatter.display(slot: session.slots[index][gap]),
                               isActive: !session.isChecked && session.activeSlot == gap,
                               isCorrect: result, font: Theme.font(.title), compact: true, expands: true) {
                        session.select(exercise: index, slot: gap)
                    }
                } else if let term = cell.term {
                    Text(term, format: .number.locale(formatter.locale))
                        .font(Theme.font(.title))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTouch + 12)
                        .background(Theme.blue.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}
