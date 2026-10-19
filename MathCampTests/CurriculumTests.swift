//
//  CurriculumTests.swift
//  MathCampTests
//

import Foundation
import Testing
@testable import Math_Camp

// MARK: - Generator foundations

struct GeneratorFoundationTests {
    @Test func fnv1aMatchesTheReferenceValues() {
        #expect(StableHash.fnv1a64("") == 0xCBF2_9CE4_8422_2325)
        #expect(StableHash.fnv1a64("a") == 0xAF63_DC4C_8601_EC8C)
    }

    @Test func seedUsesCategoryTaskAndVersion() {
        #expect(StableHash.seed(categoryID: "s1.add10", taskNumber: 7) == StableHash.fnv1a64("s1.add10#7#v1"))
    }

    @Test func splitMixMatchesTheReferenceSequence() {
        var rng = SeededRandomNumberGenerator(seed: 0)
        #expect(rng.next() == 0xE220_A839_7B1D_CDAF)
    }

    @Test func randomHelpersStayInRangeAndAreRepeatable() {
        var a = SeededRandomNumberGenerator(seed: 42)
        var b = SeededRandomNumberGenerator(seed: 42)
        for _ in 0..<200 {
            let value = a.int(3...9)
            #expect((3...9).contains(value))
            #expect(value == b.int(3...9))
        }
        #expect(a.shuffled(Array(1...10)) == b.shuffled(Array(1...10)))
    }

    @Test func tiersFollowTheTaskNumber() {
        #expect(Tier.tier(forTask: 1) == .easy)
        #expect(Tier.tier(forTask: 10) == .easy)
        #expect(Tier.tier(forTask: 11) == .medium)
        #expect(Tier.tier(forTask: 21) == .hard)
        #expect(Tier.difficulty(forTask: 1) == 0)
        #expect(Tier.difficulty(forTask: 10) == 1)
    }
}

// MARK: - Whole curriculum

struct CurriculumValidationTests {
    /// Every task of every available category: count, determinism, answers, ranges, duplicates.
    @Test("All tasks pass the content checks", arguments: ContentCatalog.availableCategories)
    func categoryIsValid(_ category: Math_Camp.Category) {
        #expect(ContentValidator.validate(categories: [category]) == [])
    }

    @Test func wordProblemRulesHold() {
        #expect(ContentValidator.validateWordProblems() == [])
    }

    @Test func everyCategoryHasItsStrings() {
        #expect(ContentValidator.validateCatalog() == [])
    }

    @Test func sectionsIToVIIAreAllAvailable() {
        #expect(ContentCatalog.sections.count == 7)
        #expect(ContentCatalog.sections.allSatisfy { $0.isAvailable })
        #expect(ContentCatalog.availableCategories.count == 72)
    }

    @Test func freeTasksFollowTheRules() throws {
        let sectionI = try #require(ContentCatalog.category(id: "s1.add10"))
        #expect((1...30).allSatisfy { sectionI.isFree(taskNumber: $0) })
        let sectionII = try #require(ContentCatalog.category(id: "s2.addregroup"))
        #expect(sectionII.isFree(taskNumber: 3))
        #expect(!sectionII.isFree(taskNumber: 4))
    }

    @Test func eachTaskHasTheDocumentedNumberOfExercises() throws {
        let drill = try #require(ContentCatalog.category(id: "s1.add10"))
        let interactive = try #require(ContentCatalog.category(id: "s1.numberline"))
        let words = try #require(ContentCatalog.category(id: "s1.words"))
        #expect(ExerciseFactory.exercises(for: drill, taskNumber: 5).count == 30)
        #expect(ExerciseFactory.exercises(for: interactive, taskNumber: 5).count == 15)
        #expect(ExerciseFactory.exercises(for: words, taskNumber: 5).count == 6)
    }

    @Test func aTaskNeverChanges() throws {
        let category = try #require(ContentCatalog.category(id: "s2.addregroup"))
        let first = ExerciseFactory.exercises(for: category, taskNumber: 7)
        let second = ExerciseFactory.exercises(for: category, taskNumber: 7)
        #expect(first == second)
        #expect(first != ExerciseFactory.exercises(for: category, taskNumber: 8))
    }
}

// MARK: - Answers and scoring

struct AnswerTests {
    @Test func starsFollowTheThresholds() {
        #expect(TaskResult.stars(correct: 27, total: 30) == 3)
        #expect(TaskResult.stars(correct: 26, total: 30) == 2)
        #expect(TaskResult.stars(correct: 21, total: 30) == 2)
        #expect(TaskResult.stars(correct: 20, total: 30) == 1)
        #expect(TaskResult.stars(correct: 15, total: 30) == 1)
        #expect(TaskResult.stars(correct: 14, total: 30) == 0)
        #expect(TaskResult.stars(correct: 6, total: 6) == 3)
        #expect(TaskResult.stars(correct: 5, total: 6) == 2)
    }

    @Test func decimalAnswersAcceptEquivalentSpellings() {
        let answer = ExpectedAnswer.decimal(value: 70, scale: 2)
        #expect(answer.isCorrect(slots: ["0.7"]))
        #expect(answer.isCorrect(slots: ["0.70"]))
        #expect(!answer.isCorrect(slots: ["0.07"]))
        #expect(!answer.isCorrect(slots: ["0.701"]))
        #expect(ExpectedAnswer.decimal(value: 10, scale: 1).isCorrect(slots: ["1"]))
        #expect(ExpectedAnswer.decimalText(75, scale: 2) == "0.75")
        #expect(ExpectedAnswer.decimalText(20, scale: 1) == "2")
    }

    @Test func expressionsRespectPrecedenceAndBrackets() {
        let plain = Expression.add(.n(3), .prod(4, 2))
        #expect(plain.evaluate() == 11)
        #expect(InfixEvaluator.evaluate(plain.tokens) == 11)
        let bracketed = Expression.multiply(.parenthesized(.sum(3, 4)), .n(2))
        #expect(bracketed.evaluate() == 14)
        #expect(bracketed.valueIgnoringParentheses == 11)
        #expect(Expression.quot(7, 2).evaluate() == nil)
        #expect(!Expression.diff(3, 5).isWellFormed)
    }

    @Test func magicSquareBlanksAreFound() {
        let cells: [Int?] = [2, nil, 6, 9, 5, nil, 4, 3, 8]
        #expect(MagicSquare.solve(cells, sum: 15) == [2, 7, 6, 9, 5, 1, 4, 3, 8])
        #expect(ExercisePrompt.magicSquare(cells: cells, sum: 15).computedAnswer == .multiple([7, 1]))
    }

    @Test func conversionsAndFractionsAreComputedFromThePrompt() {
        #expect(ExercisePrompt.conversion(value: 3, from: .m, to: .cm).computedAnswer == .number(300))
        #expect(ExercisePrompt.conversion(value: 4000, from: .g, to: .kg).computedAnswer == .number(4))
        #expect(ExercisePrompt.conversion(value: 3, from: .m, to: .kg).computedAnswer == nil)
        let half = Fraction(numerator: 1, denominator: 2)
        let quarter = Fraction(numerator: 1, denominator: 4)
        #expect(ExercisePrompt.fractionArithmetic(half, quarter, operation: .add, resultDenominator: 4).computedAnswer == .number(3))
        #expect(ExercisePrompt.fractionComparison(half, quarter).computedAnswer == .comparison(.greater))
        #expect(ExercisePrompt.rounding(value: 347, to: 100).computedAnswer == .number(300))
        #expect(ExercisePrompt.rounding(value: 350, to: 100).computedAnswer == .number(400))
    }
}

// MARK: - Notation and input

@MainActor
struct NotationAndInputTests {
    private let formatter = PromptFormatter(notation: MathNotation(), locale: Locale(identifier: "en_US"))

    @Test func equationIsSpokenForVoiceOver() {
        let prompt = ExercisePrompt.equation(lhs: .sum(47, 32), rhs: .n(79), blank: .right)
        let parts = formatter.parts(for: prompt)
        #expect(formatter.spokenSentence(parts, slots: [""]) == "47 plus 32 equals blank")
    }

    @Test func numbersFollowTheLocale() {
        let german = PromptFormatter(notation: MathNotation(), locale: Locale(identifier: "de_DE"))
        #expect(german.display(slot: "0.5") == "0,5")
        #expect(formatter.display(slot: "-3") == "−3")
    }

    @Test func keypadTypesAndMovesOnAtTheExpectedLength() throws {
        let category = try #require(ContentCatalog.category(id: "s1.add10"))
        let session = TaskSession(category: category, taskNumber: 1)
        let expected = session.exercises[0].answer.correctSlots[0]
        for character in expected { session.press(.digit(Int(String(character))!)) }
        #expect(session.slots[0][0] == expected)
        #expect(session.activeExercise == 1)
        #expect(!session.isComplete)
    }

    @Test func checkNeedsEveryAnswerAndCountsCorrectOnes() throws {
        let category = try #require(ContentCatalog.category(id: "s1.add10"))
        let session = TaskSession(category: category, taskNumber: 1)
        session.check()
        #expect(!session.isChecked)
        for (index, exercise) in session.exercises.enumerated() {
            for (slot, text) in exercise.answer.correctSlots.enumerated() {
                session.setSlot(text, exercise: index, slot: slot)
            }
        }
        session.check()
        #expect(session.isChecked)
        #expect(session.correctCount == session.total)
        #expect(session.stars == 3)
        session.retry()
        #expect(!session.isChecked)
        #expect(session.slots.allSatisfy { $0.allSatisfy { $0.isEmpty } })
    }

    @Test func negativeAndDecimalKeysWork() throws {
        let negatives = try #require(ContentCatalog.category(id: "s7.negatives"))
        let session = TaskSession(category: negatives, taskNumber: 5)
        // Find an exercise that asks for a number (not a comparison).
        let index = try #require(session.exercises.firstIndex { $0.inputKind == .signedNumber })
        session.select(exercise: index)
        session.press(.negate)
        session.press(.digit(4))
        #expect(session.slots[index][0].hasPrefix("-4") || session.slots[index][0] == "-4")
    }
}
