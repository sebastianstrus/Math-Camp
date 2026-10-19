//
//  TaskSession.swift
//  Math Camp
//

import SwiftUI
import Observation

/// A key of the custom keypad.
enum KeypadKey: Hashable {
    case digit(Int)
    case delete
    case next
    case sign(ComparisonSign)
    case boolean(Bool)
    /// ± key for numbers that may be negative.
    case negate
    /// Decimal point key.
    case point
}

/// The state of one attempt at a task. It lives only in memory: an unfinished task is not saved.
@Observable
final class TaskSession {
    let category: Category
    let taskNumber: Int
    let exercises: [Exercise]

    /// What the child entered: one string per slot of every exercise
    /// (digits, `<` `=` `>`, or `true` / `false`; empty means not answered yet).
    var slots: [[String]]
    var activeExercise = 0
    var activeSlot = 0

    private(set) var isChecked = false
    private(set) var correctness: [Bool] = []

    private static let maxDigits = 5

    init(category: Category, taskNumber: Int) {
        self.category = category
        self.taskNumber = taskNumber
        let exercises = ExerciseFactory.exercises(for: category, taskNumber: taskNumber)
        self.exercises = exercises
        self.slots = exercises.map { [String](repeating: "", count: $0.slotCount) }
    }

    // MARK: Derived state

    var total: Int { exercises.count }

    /// The "Check" button is enabled when every slot is filled.
    var isComplete: Bool { slots.allSatisfy { $0.allSatisfy { !$0.isEmpty } } }

    var correctCount: Int { correctness.filter { $0 }.count }
    var stars: Int { TaskResult.stars(correct: correctCount, total: total) }

    func isAnswered(_ index: Int) -> Bool {
        slots.indices.contains(index) && slots[index].allSatisfy { !$0.isEmpty }
    }

    var activeExerciseValue: Exercise? {
        exercises.indices.contains(activeExercise) ? exercises[activeExercise] : nil
    }

    // MARK: Selection

    func select(exercise: Int, slot: Int = 0) {
        guard !isChecked, exercises.indices.contains(exercise) else { return }
        activeExercise = exercise
        activeSlot = min(slot, max(0, exercises[exercise].slotCount - 1))
        // Tapping a typed number lets the child type it again from scratch.
        if exercises[exercise].needsKeypad, exercises[exercise].inputKind.isNumeric {
            slots[exercise][activeSlot] = ""
        }
    }

    /// Moves to another exercise (interactive tasks); lands on its first empty slot.
    func go(to exercise: Int) {
        guard exercises.indices.contains(exercise) else { return }
        activeExercise = exercise
        activeSlot = slots[exercise].firstIndex(where: \.isEmpty) ?? 0
    }

    func setSlot(_ value: String, exercise: Int, slot: Int = 0) {
        guard !isChecked, slots.indices.contains(exercise), slots[exercise].indices.contains(slot) else { return }
        slots[exercise][slot] = value
    }

    // MARK: Keypad

    func press(_ key: KeypadKey) {
        guard !isChecked, let exercise = activeExerciseValue else { return }
        let e = activeExercise
        let s = activeSlot

        switch key {
        case .digit(let digit):
            guard exercise.inputKind.isNumeric else { return }
            var text = slots[e][s]
            if text.filter(\.isNumber).count >= Self.maxDigits { return }
            // A lone zero is replaced, except in decimals ("0.5") where the zero stays.
            if text == "0" { text = String(digit) } else if text == "-0" { text = "-" + String(digit) } else { text += String(digit) }
            slots[e][s] = text
            // Move on as soon as the answer has the expected number of characters.
            if text.count == exercise.answer.correctSlots[s].count { advance() }

        case .negate:
            guard exercise.inputKind == .signedNumber else { return }
            let text = slots[e][s]
            slots[e][s] = text.hasPrefix("-") ? String(text.dropFirst()) : "-" + text

        case .point:
            guard exercise.inputKind == .decimal, !slots[e][s].contains(".") else { return }
            slots[e][s] = slots[e][s].isEmpty ? "0." : slots[e][s] + "."

        case .delete:
            guard !slots[e][s].isEmpty else { return }
            slots[e][s].removeLast()

        case .next:
            advance()

        case .sign(let sign):
            guard exercise.inputKind == .comparison else { return }
            slots[e][s] = sign.rawValue
            advance()

        case .boolean(let value):
            guard exercise.inputKind == .boolean else { return }
            slots[e][s] = value ? "true" : "false"
            advance()
        }
    }

    /// Next slot of the same exercise; in drill tasks also the first slot of the next exercise.
    private func advance() {
        guard let exercise = activeExerciseValue else { return }
        if activeSlot + 1 < exercise.slotCount {
            activeSlot += 1
        } else if category.style == .drill, activeExercise + 1 < exercises.count {
            activeExercise += 1
            activeSlot = 0
        }
    }

    // MARK: Checking

    func check() {
        guard isComplete, !isChecked else { return }
        correctness = exercises.indices.map { exercises[$0].answer.isCorrect(slots: slots[$0]) }
        isChecked = true
    }

    /// "Try again": same exercises, empty answers.
    func retry() {
        slots = exercises.map { [String](repeating: "", count: $0.slotCount) }
        correctness = []
        isChecked = false
        activeExercise = 0
        activeSlot = 0
    }
}
