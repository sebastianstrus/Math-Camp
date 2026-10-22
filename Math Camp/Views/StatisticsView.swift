//
//  StatisticsView.swift
//  Math Camp
//

import SwiftUI
import SwiftData

/// Stars earned in total, per section and per category.
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var results: [TaskResult]
    @State private var showResetConfirmation = false

    var body: some View {
        let progress = ProgressSnapshot(results)
        let sections = ContentCatalog.sections.filter(\.isAvailable)
        let stars = sections.reduce(0) { $0 + progress.stars(in: $1) }
        let maxStars = sections.reduce(0) { $0 + progress.maxStars(in: $1) }
        let done = sections.reduce(0) { $0 + progress.completedTasks(in: $1) }
        let tasks = sections.reduce(0) { $0 + $1.taskCount }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                totalCard(stars: stars, maxStars: maxStars, done: done, tasks: tasks)

                ForEach(sections) { section in
                    sectionCard(section, progress: progress)
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("stats.reset.button", systemImage: "arrow.counterclockwise")
                        .font(Theme.font(.headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(results.isEmpty)
            }
            .padding(20)
            .readableContent()
        }
        .background(TrailBackground())
        .navigationTitle(Text("stats.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("stats.reset.title", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("stats.reset.confirm", role: .destructive, action: resetProgress)
        } message: {
            Text("stats.reset.message")
        }
    }

    /// Deletes every saved task result.
    private func resetProgress() {
        try? modelContext.delete(model: TaskResult.self)
        try? modelContext.save()
    }

    private func totalCard(stars: Int, maxStars: Int, done: Int, tasks: Int) -> some View {
        VStack(spacing: 8) {
            Text("stats.total")
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .accessibilityHidden(true)
                Text(stars, format: .number)
            }
            .font(Theme.font(.largeTitle))
            .foregroundStyle(Theme.yellow)
            Text("stats.starsOfMax \(stars) \(maxStars)")
                .font(Theme.font(.subheadline, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            ProgressView(value: Double(stars), total: Double(max(maxStars, 1)))
                .tint(Theme.yellow)
            Text("progress.tasks \(done) \(tasks)")
                .font(Theme.font(.footnote))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .themeCard(accent: Theme.yellow)
        .accessibilityElement(children: .combine)
    }

    private func sectionCard(_ section: CampSection, progress: ProgressSnapshot) -> some View {
        let accent = Theme.accent(for: section)
        let categories = section.categories.filter(\.isAvailable)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.navyDeep)
                    .frame(width: 44, height: 44)
                    .background(accent, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("section.number \(section.romanNumeral)")
                        .font(Theme.font(.caption))
                        .foregroundStyle(accent)
                    Text(LocalizedStringKey(section.titleKey))
                        .font(Theme.font(.headline))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer(minLength: 8)
                starsLabel(progress.stars(in: section), of: progress.maxStars(in: section))
                    .font(Theme.font(.headline))
            }

            ForEach(categories) { category in
                let earned = progress.stars(in: category)
                let possible = ContentCatalog.tasksPerCategory * 3

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizedStringKey(category.titleKey))
                            .font(Theme.font(.subheadline, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer(minLength: 8)
                        starsLabel(earned, of: possible)
                            .font(Theme.font(.footnote))
                    }
                    ProgressView(value: Double(earned), total: Double(possible))
                        .tint(accent)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCard()
    }

    private func starsLabel(_ stars: Int, of maxStars: Int) -> some View {
        Label { Text("stats.starsOfMax \(stars) \(maxStars)") } icon: { Image(systemName: "star.fill") }
            .foregroundStyle(Theme.yellow)
    }
}
