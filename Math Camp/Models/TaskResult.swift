//
//  TaskResult.swift
//  Math Camp
//

import Foundation
import SwiftData

/// The best result of one task. There is at most one per `categoryID` + `taskNumber`.
@Model
final class TaskResult {
    var categoryID: String
    var taskNumber: Int
    var bestCorrect: Int
    var total: Int
    var bestStars: Int
    var attempts: Int
    var lastCompletedAt: Date

    init(categoryID: String, taskNumber: Int, bestCorrect: Int, total: Int, bestStars: Int,
         attempts: Int = 1, lastCompletedAt: Date = .now) {
        self.categoryID = categoryID
        self.taskNumber = taskNumber
        self.bestCorrect = bestCorrect
        self.total = total
        self.bestStars = bestStars
        self.attempts = attempts
        self.lastCompletedAt = lastCompletedAt
    }

    /// 3 stars from 90 %, 2 from 70 %, 1 from 50 %.
    static func stars(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        if correct * 10 >= total * 9 { return 3 }
        if correct * 10 >= total * 7 { return 2 }
        if correct * 2 >= total { return 1 }
        return 0
    }

    /// Stores the outcome of a finished attempt, keeping the best result.
    @MainActor
    static func record(correct: Int, total: Int, categoryID: String, taskNumber: Int, in context: ModelContext) {
        let descriptor = FetchDescriptor<TaskResult>(
            predicate: #Predicate { $0.categoryID == categoryID && $0.taskNumber == taskNumber })
        let earned = stars(correct: correct, total: total)

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.attempts += 1
            existing.lastCompletedAt = .now
            if correct > existing.bestCorrect {
                existing.bestCorrect = correct
                existing.total = total
                existing.bestStars = earned
            }
        } else {
            context.insert(TaskResult(categoryID: categoryID, taskNumber: taskNumber,
                                      bestCorrect: correct, total: total, bestStars: earned))
        }
        try? context.save()
    }
}

/// Progress numbers computed from the saved results. Cheap to rebuild whenever the results change.
struct ProgressSnapshot {
    private let results: [String: [Int: TaskResult]]

    init(_ all: [TaskResult]) {
        var grouped: [String: [Int: TaskResult]] = [:]
        for result in all {
            let existing = grouped[result.categoryID]?[result.taskNumber]
            if existing == nil || result.bestCorrect > existing?.bestCorrect ?? -1 {
                grouped[result.categoryID, default: [:]][result.taskNumber] = result
            }
        }
        results = grouped
    }

    func result(categoryID: String, taskNumber: Int) -> TaskResult? {
        results[categoryID]?[taskNumber]
    }

    /// Number of tasks finished at least once.
    func completedTasks(in category: Category) -> Int {
        results[category.id]?.count ?? 0
    }

    func stars(in category: Category) -> Int {
        results[category.id]?.values.reduce(0) { $0 + $1.bestStars } ?? 0
    }

    func completedTasks(in section: CampSection) -> Int {
        section.categories.reduce(0) { $0 + completedTasks(in: $1) }
    }

    func stars(in section: CampSection) -> Int {
        section.categories.reduce(0) { $0 + stars(in: $1) }
    }

    func maxStars(in section: CampSection) -> Int {
        section.taskCount * 3
    }

    /// The recommended next task: the first one that was never finished.
    func nextTask(in category: Category) -> Int? {
        (1...ContentCatalog.tasksPerCategory).first { result(categoryID: category.id, taskNumber: $0) == nil }
    }
}
