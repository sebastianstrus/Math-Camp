//
//  ContentValidator.swift
//  Math Camp
//
//  Self-check of the whole curriculum. Compiled in Debug builds (and by the unit tests).
//

#if DEBUG
import Foundation

nonisolated enum ContentValidator {
    /// Runs every per-task check and returns one line per problem (empty = all good).
    static func validate(categories: [Category] = ContentCatalog.availableCategories) -> [String] {
        var issues: [String] = []

        for category in categories {
            for task in 1...ContentCatalog.tasksPerCategory {
                let tier = Tier.tier(forTask: task)
                let label = "\(category.id) task \(task)"
                let exercises = ExerciseFactory.exercises(for: category, taskNumber: task)

                // Count and determinism.
                if exercises.count != category.exercisesPerTask {
                    issues.append("\(label): \(exercises.count) exercises, expected \(category.exercisesPerTask)")
                }
                if exercises != ExerciseFactory.exercises(for: category, taskNumber: task) {
                    issues.append("\(label): not deterministic")
                }

                for exercise in exercises {
                    issues += check(exercise, category: category, label: label)
                }

                // Duplicates: forbidden when the pool is large enough, otherwise no repeats in a row.
                let prompts = exercises.map(\.prompt)
                if zip(prompts, prompts.dropFirst()).contains(where: { $0 == $1 }) {
                    issues.append("\(label): same exercise twice in a row")
                }
                if let generator = category.generator as? DraftGenerator {
                    let pool = generator.estimatedPoolSize(tier: tier, taskNumber: task, count: exercises.count)
                    if Double(pool) >= 1.5 * Double(exercises.count), Set(prompts).count != prompts.count {
                        issues.append("\(label): duplicates although the pool has \(pool) exercises")
                    }
                    // Share of "=" in comparisons (15–20 %).
                    if generator.equalFraction > 0, generator.equalFraction < 0.3 {
                        let equal = exercises.filter { $0.answer == .comparison(.equal) }.count
                        let share = Double(equal) / Double(exercises.count)
                        if share < 0.15 || share > 0.20 { issues.append("\(label): '=' share is \(share)") }
                    }
                }
            }
        }
        return issues
    }

    private static func check(_ exercise: Exercise, category: Category, label: String) -> [String] {
        var issues: [String] = []
        func fail(_ message: String) { issues.append("\(label) #\(exercise.id): \(message)") }

        // Range.
        for number in exercise.allNumbers {
            if abs(number) > category.valueLimit { fail("number \(number) outside ±\(category.valueLimit)") }
            if number < 0 && !category.allowsNegatives { fail("negative number \(number)") }
        }

        // The stored answer must be what the prompt itself says.
        if let expected = exercise.prompt.computedAnswer {
            if expected != exercise.answer { fail("answer \(exercise.answer) does not match the prompt (\(expected))") }
        } else {
            switch exercise.prompt {
            case .sequence, .wordProblem: break
            default: fail("prompt is not valid (no computable answer)")
            }
        }

        // The printed form of every expression must mean what the expression tree says.
        func checkPrinting(_ expressions: [Expression]) {
            for expression in expressions where InfixEvaluator.evaluate(expression.tokens) != expression.evaluate() {
                fail("printed form means something else than the expression tree")
            }
        }

        switch exercise.prompt {
        case .equation(let lhs, let rhs, _), .comparison(let lhs, let rhs),
             .solveForX(let lhs, let rhs, _), .trueFalseComparison(let lhs, _, let rhs):
            checkPrinting([lhs, rhs])

        case .trueFalse(let expression, _):
            checkPrinting([expression])

        case .numberLine(let config, _, let target):
            if !(config.lower...config.upper).contains(target) || (target - config.lower) % config.tickStep != 0 {
                fail("target is not on a tick")
            }

        case .decimalNumberLine(let config, _, let target):
            if !(config.lower...config.upper).contains(target) || (target - config.lower) % config.tickStep != 0 {
                fail("decimal target is not on a tick")
            }

        case .fractionNumberLine(let denominator, let numerator, _):
            if numerator < 1 || numerator >= denominator { fail("fraction outside the number line") }

        case .fractionPicture(let fraction, _):
            if fraction.numerator < 1 || fraction.numerator >= fraction.denominator { fail("fraction picture not a proper fraction") }

        case .clock(let hour, let minute):
            if !(1...12).contains(hour) || !(0...59).contains(minute) { fail("invalid clock time") }

        case .sequence(let terms):
            let known = terms.enumerated().compactMap { index, term in term.map { (index, $0) } }
            guard known.count >= 2, case .multiple(let gaps) = exercise.answer else { fail("bad sequence"); break }
            let step = (known[1].1 - known[0].1) / (known[1].0 - known[0].0)
            let start = known[0].1 - step * known[0].0
            let full = terms.indices.map { start + step * $0 }
            let missing = terms.indices.filter { terms[$0] == nil }.map { full[$0] }
            if missing != gaps { fail("sequence answer does not continue the pattern") }
            if known.contains(where: { $0.1 != full[$0.0] }) { fail("sequence is not arithmetic") }

        case .rulePattern(let start, let length, let rule, let gaps):
            // The pattern must stay recognisable: at least four numbers remain visible.
            if length - gaps.count < 4 { fail("too few visible numbers") }
            if rule.terms(start: start, length: length).contains(where: { $0 < 0 }) { fail("negative term") }

        case .wordProblem(let templateID, let values, let names):
            guard let template = WordProblems.template(id: templateID) else {
                fail("unknown template \(templateID)")
                break
            }
            let (a, b, c) = (values["a"] ?? 0, values["b"] ?? 0, values["c"] ?? 0)
            if exercise.answer != .number(template.kind.answer(a: a, b: b, c: c)) { fail("wrong word problem answer") }
            if exercise.answer.numbers.contains(where: { $0 < 1 }) { fail("answer below 1") }
            // Every number that the story shows is at least 2 (plural-safe).
            for (letter, value) in zip("abc", [a, b, c]) where template.args.contains(letter) && value < 2 {
                fail("shown number \(letter) below 2 (plural)")
            }
            if template.args.contains("q") && names["p"] == names["q"] { fail("same name twice") }
            if !L10n.hasString(template.catalogKey) { fail("missing catalog entry \(template.catalogKey)") }

        default:
            break
        }
        return issues
    }

    /// Word-problem rules that concern a whole task and all templates.
    static func validateWordProblems() -> [String] {
        var issues: [String] = []
        for (index, generator) in WordProblems.all.enumerated() {
            let name = "s\(index + 1)"
            if generator.templates.count < 20 { issues.append("\(name): only \(generator.templates.count) templates") }
            if Set(generator.templates.map(\.id)).count != generator.templates.count { issues.append("\(name): duplicate template ids") }
        }
        for category in ContentCatalog.availableCategories where category.generator is WordProblemGenerator {
            for task in 1...ContentCatalog.tasksPerCategory {
                let ids = ExerciseFactory.exercises(for: category, taskNumber: task).compactMap { exercise -> String? in
                    if case .wordProblem(let id, _, _) = exercise.prompt { return id }
                    return nil
                }
                if Set(ids).count != ids.count { issues.append("\(category.id) task \(task): template repeated") }
            }
        }
        return issues
    }

    /// Catalog completeness: every category has a title (and a description when available).
    static func validateCatalog() -> [String] {
        var issues: [String] = []
        for section in ContentCatalog.sections {
            for key in [section.titleKey, section.subtitleKey] where !L10n.hasString(key) {
                issues.append("missing string \(key)")
            }
            for category in section.categories {
                if !L10n.hasString(category.titleKey) { issues.append("missing string \(category.titleKey)") }
                if category.isAvailable && !L10n.hasString(category.descriptionKey) {
                    issues.append("missing string \(category.descriptionKey)")
                }
            }
        }
        return issues
    }

    /// Prints the outcome (called once at debug launch).
    static func logResults() {
        let issues = validate() + validateWordProblems() + validateCatalog()
        if issues.isEmpty {
            print("✅ ContentValidator: all checks passed")
        } else {
            print("❌ ContentValidator: \(issues.count) problems")
            issues.prefix(50).forEach { print("  • \($0)") }
        }
    }
}
#endif
