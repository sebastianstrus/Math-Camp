//
//  CampSection.swift
//  Math Camp
//

import Foundation

/// How the exercises of a category are presented.
nonisolated enum ScreenStyle: Hashable, Sendable {
    /// All exercises on one scrolling page, one per row.
    case drill
    /// One exercise per screen with a "3 / 15" counter.
    case interactive
}

/// One concrete type of practice, for example "Addition with Regrouping".
///
/// `id` is part of every task seed and of the saved progress. **Never rename an id.**
nonisolated struct Category: Identifiable, Hashable, Sendable {
    let id: String
    let sectionID: String
    /// SF Symbol shown when there is no example.
    let icon: String
    /// A small sentence shown on the category card, for example `38 + 47`.
    let example: [MathToken]
    let style: ScreenStyle
    /// Number of exercises in one task (30 drill, 15 interactive, 6 word problems).
    let exercisesPerTask: Int
    /// Largest number any exercise may contain (checked by `ContentValidator`).
    let valueLimit: Int
    /// `true` for categories that practise negative numbers.
    let allowsNegatives: Bool
    /// Tasks `1...freeTaskCount` are free, the rest need Premium.
    let freeTaskCount: Int
    /// `nil` while the category is only announced ("Coming soon").
    let generator: (any ExerciseGenerator)?

    var titleKey: String { "category.\(id).title" }
    var descriptionKey: String { "category.\(id).description" }
    var isAvailable: Bool { generator != nil }

    func isFree(taskNumber: Int) -> Bool {
        taskNumber <= freeTaskCount
    }

    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A stage of the mountain trip, for example "Base Camp".
nonisolated struct CampSection: Identifiable, Hashable, Sendable {
    let id: String
    let number: Int
    let romanNumeral: String
    /// SF Symbol.
    let icon: String
    /// Accent colour as 0xRRGGBB (turned into a `Color` by `Theme`).
    let accentHex: UInt32
    let categories: [Category]

    var titleKey: String { "section.\(id).title" }
    var subtitleKey: String { "section.\(id).subtitle" }
    var isAvailable: Bool { categories.contains { $0.isAvailable } }
    var taskCount: Int { categories.filter(\.isAvailable).count * ContentCatalog.tasksPerCategory }
}
