//
//  ProgressTransfer.swift
//  Math Camp
//
//  TEMPORARY: moves solved tasks between devices (e.g. iPad -> iPhone) for App Store screenshots.
//  Delete this file, its use in Math_CampApp and the rows in SettingsView when no longer needed.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ProgressTransfer {
    /// Plain-text (JSON) copy of every saved `TaskResult`.
    struct Entry: Codable {
        let categoryID: String
        let taskNumber: Int
        let bestCorrect: Int
        let total: Int
        let bestStars: Int
        let attempts: Int
        let lastCompletedAt: Date
    }

    static var fileURL: URL {
        URL.documentsDirectory.appending(path: "progress-transfer.json")
    }

    /// Simulator only: the same file on the Mac's Desktop.
    static var desktopFileURL: URL? {
        guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return nil }
        return URL(filePath: home).appending(path: "Desktop/progress-transfer.json")
    }

    /// Writes all results to `fileURL`. An empty store never overwrites an existing file,
    /// so launching on a fresh device cannot destroy the exported data.
    @MainActor
    @discardableResult
    static func export(from context: ModelContext) -> Int {
        guard let results = try? context.fetch(FetchDescriptor<TaskResult>()), !results.isEmpty else { return 0 }
        let entries = results.map {
            Entry(categoryID: $0.categoryID, taskNumber: $0.taskNumber, bestCorrect: $0.bestCorrect,
                  total: $0.total, bestStars: $0.bestStars, attempts: $0.attempts,
                  lastCompletedAt: $0.lastCompletedAt)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries),
              (try? data.write(to: fileURL, options: .atomic)) != nil else { return 0 }
        #if targetEnvironment(simulator)
        if let desktop = desktopFileURL { try? data.write(to: desktop, options: .atomic) }
        #endif
        return entries.count
    }

    /// Reads a transfer file into the store. Existing results are kept when they are better.
    /// Returns the number of tasks that were added or improved.
    @MainActor
    @discardableResult
    static func importResults(from url: URL, into context: ModelContext) -> Int {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url),
              let entries = try? decoder.decode([Entry].self, from: data) else { return 0 }

        let existing = (try? context.fetch(FetchDescriptor<TaskResult>())) ?? []
        var byKey: [String: TaskResult] = [:]
        for result in existing { byKey["\(result.categoryID)#\(result.taskNumber)"] = result }

        var changed = 0
        for entry in entries {
            let key = "\(entry.categoryID)#\(entry.taskNumber)"
            if let current = byKey[key] {
                guard entry.bestCorrect > current.bestCorrect else { continue }
                current.bestCorrect = entry.bestCorrect
                current.total = entry.total
                current.bestStars = entry.bestStars
                current.attempts = max(current.attempts, entry.attempts)
                current.lastCompletedAt = entry.lastCompletedAt
            } else {
                let result = TaskResult(categoryID: entry.categoryID, taskNumber: entry.taskNumber,
                                        bestCorrect: entry.bestCorrect, total: entry.total,
                                        bestStars: entry.bestStars, attempts: entry.attempts,
                                        lastCompletedAt: entry.lastCompletedAt)
                context.insert(result)
                byKey[key] = result
            }
            changed += 1
        }
        try? context.save()
        return changed
    }
}

private struct ExportProgressOnLaunch: ViewModifier {
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.task {
            #if targetEnvironment(simulator)
            // Simulators can reach the Mac's Desktop: import first (fresh device), then export.
            if let desktop = ProgressTransfer.desktopFileURL,
               FileManager.default.fileExists(atPath: desktop.path) {
                ProgressTransfer.importResults(from: desktop, into: context)
            }
            #endif
            ProgressTransfer.export(from: context)
        }
    }
}

extension View {
    /// Exports the saved progress to a text file once at launch.
    func exportProgressOnLaunch() -> some View {
        modifier(ExportProgressOnLaunch())
    }
}

/// Temporary Settings rows: share the exported file, or import one.
struct ProgressTransferRows: View {
    @Environment(\.modelContext) private var context
    @State private var showImporter = false
    @State private var message: String?

    var body: some View {
        VStack(spacing: 10) {
            // Re-export right before sharing so the file is current.
            if ProgressTransfer.export(from: context) > 0 || FileManager.default.fileExists(atPath: ProgressTransfer.fileURL.path) {
                ShareLink(item: ProgressTransfer.fileURL) {
                    Label { Text(verbatim: "Export progress file") } icon: { Image(systemName: "square.and.arrow.up") }
                }
            }
            Button { showImporter = true } label: {
                Label { Text(verbatim: "Import progress file") } icon: { Image(systemName: "square.and.arrow.down") }
            }
            if let message {
                Text(verbatim: message)
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .font(Theme.font(.headline))
        .foregroundStyle(Theme.textPrimary)
        .frame(maxWidth: .infinity)
        .themeCard()
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let count = ProgressTransfer.importResults(from: url, into: context)
            message = "Imported \(count) tasks"
        }
    }
}
