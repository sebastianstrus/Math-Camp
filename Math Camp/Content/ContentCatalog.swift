//
//  ContentCatalog.swift
//  Math Camp
//
//  The whole curriculum as data. To add a category see the notes at the bottom of this file.
//

import Foundation

nonisolated enum ContentCatalog {
    /// Every category has exactly this many tasks (10 Warm-up, 10 Climb, 10 Peak).
    static let tasksPerCategory = 30

    static let sections: [CampSection] = [section1, section2, section3, section4, section5, section6, section7]

    static func section(id: String) -> CampSection? { sections.first { $0.id == id } }

    static func category(id: String) -> Category? {
        sections.lazy.flatMap(\.categories).first { $0.id == id }
    }

    /// Categories that already have a generator.
    static var availableCategories: [Category] {
        sections.flatMap(\.categories).filter(\.isAvailable)
    }

    // MARK: - Helpers

    /// Builds one category. `slug` is the last part of the id (`s1.add10` = section `s1`, slug `add10`).
    private static func make(
        _ section: String, _ slug: String, icon: String, example: [MathToken] = [],
        style: ScreenStyle = .drill, exercises: Int = 30, limit: Int, negatives: Bool = false, free: Int,
        generator: (any ExerciseGenerator)?
    ) -> Category {
        Category(id: "\(section).\(slug)", sectionID: section, icon: icon, example: example, style: style,
                 exercisesPerTask: exercises, valueLimit: limit, allowsNegatives: negatives,
                 freeTaskCount: free, generator: generator)
    }

    private static func draft(equalFraction: Double = 0, _ maker: @escaping DraftMaker) -> DraftGenerator {
        DraftGenerator(equalFraction: equalFraction, makeDraft: maker)
    }

    // MARK: - Section I – Base Camp (all free)

    private static let section1 = CampSection(
        id: "s1", number: 1, romanNumeral: "I", icon: "tent.fill", accentHex: 0xFF7A2F,
        categories: {
            let free = tasksPerCategory
            return [
                make("s1", "counting", icon: "circle.grid.2x2.fill", style: .interactive, exercises: 15,
                     limit: 20, free: free, generator: draft(Section1.counting)),
                make("s1", "compare", icon: "arrow.left.arrow.right",
                     example: [.number(8), .greater, .number(5)], limit: 20, free: free,
                     generator: draft(equalFraction: 0.175, Section1.compare)),
                make("s1", "add10", icon: "plus.circle.fill",
                     example: [.number(3), .plus, .number(4)], limit: 20, free: free,
                     generator: draft(Section1.addTo10)),
                make("s1", "sub10", icon: "minus.circle.fill",
                     example: [.number(9), .minus, .number(4)], limit: 20, free: free,
                     generator: draft(Section1.subTo10)),
                make("s1", "make10", icon: "equal.circle.fill",
                     example: [.number(7), .plus, .blank, .equals, .number(10)], limit: 20, free: free,
                     generator: draft(Section1.make10)),
                make("s1", "add20", icon: "plus.circle.fill",
                     example: [.number(12), .plus, .number(5)], limit: 20, free: free,
                     generator: draft(Section1.addTo20)),
                make("s1", "addacross10", icon: "plus.circle.fill",
                     example: [.number(8), .plus, .number(5)], limit: 20, free: free,
                     generator: draft(Section1.addAcross10)),
                make("s1", "subacross10", icon: "minus.circle.fill",
                     example: [.number(15), .minus, .number(8)], limit: 20, free: free,
                     generator: draft(Section1.subAcross10)),
                make("s1", "missing", icon: "questionmark.circle.fill",
                     example: [.blank, .plus, .number(6), .equals, .number(14)], limit: 20, free: free,
                     generator: draft(Section1.missingNumber)),
                make("s1", "numberline", icon: "ruler.fill", style: .interactive, exercises: 15,
                     limit: 20, free: free, generator: draft(Section1.numberLine)),
                make("s1", "patterns", icon: "list.number", style: .interactive, exercises: 15,
                     limit: 20, free: free, generator: draft(Section1.patterns)),
                make("s1", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 20, free: free, generator: WordProblems.section1),
            ]
        }())

    // MARK: - Section II – Forest Trail

    private static let section2 = CampSection(
        id: "s2", number: 2, romanNumeral: "II", icon: "tree.fill", accentHex: 0x2FBF71,
        categories: {
            let free = 3
            return [
                make("s2", "placevalue", icon: "square.grid.3x3.fill", limit: 100, free: free,
                     generator: draft(Section2.tensAndOnes)),
                make("s2", "compare", icon: "arrow.left.arrow.right",
                     example: [.number(58), .less, .number(85)], limit: 100, free: free,
                     generator: draft(equalFraction: 0.175, Section2.compare)),
                make("s2", "addtens", icon: "plus.circle.fill",
                     example: [.number(34), .plus, .number(20)], limit: 100, free: free,
                     generator: draft(Section2.addTens)),
                make("s2", "addnoregroup", icon: "plus.circle.fill",
                     example: [.number(47), .plus, .number(32)], limit: 100, free: free,
                     generator: draft(Section2.addNoRegroup)),
                make("s2", "addregroup", icon: "plus.circle.fill",
                     example: [.number(38), .plus, .number(47)], limit: 100, free: free,
                     generator: draft(Section2.addRegroup)),
                make("s2", "subnoregroup", icon: "minus.circle.fill",
                     example: [.number(76), .minus, .number(34)], limit: 100, free: free,
                     generator: draft(Section2.subNoRegroup)),
                make("s2", "subregroup", icon: "minus.circle.fill",
                     example: [.number(62), .minus, .number(27)], limit: 100, free: free,
                     generator: draft(Section2.subRegroup)),
                make("s2", "missing", icon: "questionmark.circle.fill",
                     example: [.number(35), .plus, .blank, .equals, .number(80)], limit: 100, free: free,
                     generator: draft(Section2.missingNumber)),
                make("s2", "numberline", icon: "ruler.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section2.numberLine)),
                make("s2", "brackets", icon: "parentheses",
                     example: [.number(30), .minus, .openParen, .number(7), .plus, .number(2), .closeParen],
                     limit: 100, free: free, generator: draft(Section2.brackets)),
                make("s2", "skipcount", icon: "list.number", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section2.skipCounting)),
                make("s2", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 100, free: free, generator: WordProblems.section2),
            ]
        }())

    // MARK: - Section III – Rocky Ridge

    private static let section3 = CampSection(
        id: "s3", number: 3, romanNumeral: "III", icon: "mountain.2.fill", accentHex: 0x2F6FE0,
        categories: {
            let free = 3
            return [
                make("s3", "groups", icon: "circle.grid.3x3.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section3.equalGroups)),
                make("s3", "tables2510", icon: "multiply.circle.fill",
                     example: [.number(5), .times, .number(7)], limit: 100, free: free,
                     generator: draft(Section3.timesTables(Section3.tables2510))),
                make("s3", "tables34", icon: "multiply.circle.fill",
                     example: [.number(4), .times, .number(6)], limit: 100, free: free,
                     generator: draft(Section3.timesTables(Section3.tables34))),
                make("s3", "tables69", icon: "multiply.circle.fill",
                     example: [.number(7), .times, .number(8)], limit: 100, free: free,
                     generator: draft(Section3.timesTables(Section3.tables69))),
                make("s3", "tablesmixed", icon: "multiply.circle.fill",
                     example: [.number(9), .times, .number(6)], limit: 100, free: free,
                     generator: draft(Section3.timesTables(Section3.tablesMixed))),
                make("s3", "division", icon: "divide.circle.fill",
                     example: [.number(42), .divide, .number(6)], limit: 100, free: free,
                     generator: draft(Section3.divisionFacts)),
                make("s3", "missingfactor", icon: "questionmark.circle.fill",
                     example: [.number(7), .times, .blank, .equals, .number(56)], limit: 100, free: free,
                     generator: draft(Section3.missingFactor)),
                make("s3", "remainder", icon: "divide.circle.fill",
                     example: [.number(47), .divide, .number(6)], limit: 100, free: free,
                     generator: draft(Section3.remainder)),
                make("s3", "order", icon: "parentheses",
                     example: [.number(3), .plus, .number(4), .times, .number(2)], limit: 100, free: free,
                     generator: draft(Section3.orderOfOperations)),
                make("s3", "times10100", icon: "multiply.circle.fill",
                     example: [.number(34), .times, .number(10)], limit: 10_000, free: free,
                     generator: draft(Section3.multiplyBy10And100)),
                make("s3", "twodigit", icon: "multiply.circle.fill",
                     example: [.number(23), .times, .number(4)], limit: 1_000, free: free,
                     generator: draft(Section3.twoDigitTimesOne)),
                make("s3", "truefalse", icon: "checkmark.circle.fill",
                     limit: 100, free: free,
                     generator: draft(equalFraction: 0.5, Section3.trueOrFalse)),
                make("s3", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 100, free: free, generator: WordProblems.section3),
            ]
        }())

    // MARK: - Section IV – The Summit

    private static let section4 = CampSection(
        id: "s4", number: 4, romanNumeral: "IV", icon: "flag.fill", accentHex: 0x6B4DE6,
        categories: {
            let free = 3
            return [
                make("s4", "hundreds", icon: "square.grid.3x3.fill", limit: 1_000, free: free,
                     generator: draft(Section4.hundredsTensOnes)),
                make("s4", "compare", icon: "arrow.left.arrow.right",
                     example: [.number(4_760), .greater, .number(4_670)], limit: 10_000, free: free,
                     generator: draft(equalFraction: 0.175, Section4.compare)),
                make("s4", "rounding", icon: "arrow.up.arrow.down", limit: 10_000, free: free,
                     generator: draft(Section4.rounding)),
                make("s4", "add3digit", icon: "plus.circle.fill",
                     example: [.number(347), .plus, .number(125)], limit: 1_000, free: free,
                     generator: draft(Section4.threeDigit)),
                make("s4", "column", icon: "plus.slash.minus", style: .interactive, exercises: 15,
                     limit: 10_000, free: free, generator: draft(Section4.columnAddSub)),
                make("s4", "columnmult", icon: "multiply.circle.fill", style: .interactive, exercises: 15,
                     limit: 10_000, free: free, generator: draft(Section4.columnMultiplication)),
                make("s4", "longdiv", icon: "divide.circle.fill",
                     example: [.number(458), .divide, .number(7)], limit: 1_000, free: free,
                     generator: draft(Section4.longDivision)),
                make("s4", "numberline", icon: "ruler.fill", style: .interactive, exercises: 15,
                     limit: 1_000, free: free, generator: draft(Section4.numberLine)),
                make("s4", "estimation", icon: "scope", limit: 10_000, free: free,
                     generator: draft(Section4.estimation)),
                make("s4", "multistep", icon: "parentheses",
                     example: [.number(250), .plus, .number(4), .times, .number(30)], limit: 10_000, free: free,
                     generator: draft(Section4.multiStep)),
                make("s4", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 1_000, free: free, generator: WordProblems.section4),
            ]
        }())

    // MARK: - Section V – Fraction Falls

    private static let section5 = CampSection(
        id: "s5", number: 5, romanNumeral: "V", icon: "drop.fill", accentHex: 0x1FB6C9,
        categories: {
            let free = 3
            return [
                make("s5", "fractionpics", icon: "chart.pie.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section5.fractionPictures)),
                make("s5", "comparefractions", icon: "arrow.left.arrow.right", limit: 100, free: free,
                     generator: draft(equalFraction: 0.175, Section5.compareFractions)),
                make("s5", "fractionline", icon: "ruler.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section5.fractionLine)),
                make("s5", "fractionof", icon: "chart.pie.fill", limit: 1_000, free: free,
                     generator: draft(Section5.fractionOfNumber)),
                make("s5", "addfractions", icon: "plus.circle.fill", limit: 100, free: free,
                     generator: draft(Section5.addFractions)),
                make("s5", "equivalent", icon: "equal.circle.fill", limit: 100, free: free,
                     generator: draft(Section5.equivalentFractions)),
                make("s5", "comparedecimals", icon: "arrow.left.arrow.right",
                     example: [.number(0), .less, .number(1)], limit: 100, free: free,
                     generator: draft(equalFraction: 0.175, Section5.compareDecimals)),
                make("s5", "decimalline", icon: "ruler.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section5.decimalLine)),
                make("s5", "adddecimals", icon: "plus.circle.fill", limit: 100, free: free,
                     generator: draft(Section5.addDecimals)),
                make("s5", "percent", icon: "percent", limit: 1_000, free: free,
                     generator: draft(Section5.percentages)),
                make("s5", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 1_000, free: free, generator: WordProblems.section5),
            ]
        }())

    // MARK: - Section VI – Ranger Station

    private static let section6 = CampSection(
        id: "s6", number: 6, romanNumeral: "VI", icon: "binoculars.fill", accentHex: 0xF5A524,
        categories: {
            let free = 3
            return [
                make("s6", "time", icon: "clock.fill", style: .interactive, exercises: 15,
                     limit: 60, free: free, generator: draft(Section6.tellingTime)),
                make("s6", "intervals", icon: "timer", limit: 1_000, free: free,
                     generator: draft(Section6.timeIntervals)),
                make("s6", "length", icon: "ruler.fill", limit: 100_000, free: free,
                     generator: draft(Section6.length)),
                make("s6", "massvolume", icon: "scalemass.fill", limit: 100_000, free: free,
                     generator: draft(Section6.massAndVolume)),
                make("s6", "calendar", icon: "calendar", style: .interactive, exercises: 15,
                     limit: 1_000, free: free, generator: draft(Section6.calendar)),
                make("s6", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 1_000, free: free, generator: WordProblems.section6),
            ]
        }())

    // MARK: - Section VII – The Expedition

    private static let section7 = CampSection(
        id: "s7", number: 7, romanNumeral: "VII", icon: "map.fill", accentHex: 0xF2579B,
        categories: {
            let free = 3
            return [
                make("s7", "patterns", icon: "list.number", style: .interactive, exercises: 15,
                     limit: 200, free: free, generator: draft(Section7.patterns)),
                make("s7", "balance", icon: "scalemass.fill", style: .interactive, exercises: 15,
                     limit: 100, free: free, generator: draft(Section7.balance)),
                make("s7", "equations", icon: "equal.circle.fill",
                     example: [.variable, .plus, .number(7), .equals, .number(15)], limit: 1_000, free: free,
                     generator: draft(Section7.equations)),
                make("s7", "magic", icon: "square.grid.3x3.fill", style: .interactive, exercises: 15,
                     limit: 200, free: free, generator: draft(Section7.magicSquares)),
                make("s7", "truefalsemix", icon: "checkmark.circle.fill", limit: 100, free: free,
                     generator: draft(equalFraction: 0.5, Section7.trueFalseMix)),
                make("s7", "negatives", icon: "minus.circle.fill",
                     example: [.number(3), .minus, .number(8)], limit: 100, negatives: true, free: free,
                     generator: draft(Section7.negatives)),
                make("s7", "words", icon: "text.book.closed.fill", style: .interactive, exercises: 6,
                     limit: 1_000, free: free, generator: WordProblems.section7),
            ]
        }())

    // MARK: - How to add a category
    //
    // 1. Write a generator function `(GenContext, inout SeededRandomNumberGenerator) -> Draft?`
    //    in the file of its section (or a new `WordProblemGenerator`).
    // 2. Add one `make(...)` line to the section above (the slug becomes part of the id – never rename it).
    // 3. Add `category.<id>.title` and `category.<id>.description` to Localizable.xcstrings.
    //
    // No view needs to change: the screens are chosen from the prompt types the generator produces.
    // Only a brand-new prompt type needs a new case in `ExercisePrompt`, its layout in
    // `PromptFormatter` (drill) or `InteractiveExerciseView`, and its answer in `ExpectedAnswer`.
}
