//
//  SectionView.swift
//  Math Camp
//

import SwiftUI
import SwiftData

/// The categories of one section.
struct SectionView: View {
    let section: CampSection

    @Query private var results: [TaskResult]
    @Environment(\.locale) private var locale
    @Environment(\.mathNotation) private var notation

    var body: some View {
        let progress = ProgressSnapshot(results)
        let accent = Theme.accent(for: section)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(systemName: section.icon)
                        .font(.title)
                        .foregroundStyle(Theme.navyDeep)
                        .frame(width: 60, height: 60)
                        .background(accent, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("section.number \(section.romanNumeral)")
                            .font(Theme.font(.caption))
                            .foregroundStyle(accent)
                        Text(LocalizedStringKey(section.subtitleKey))
                            .font(Theme.font(.headline, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                    ForEach(section.categories) { category in
                        if category.isAvailable {
                            NavigationLink(value: Route.category(category.id)) {
                                card(category, accent: accent, progress: progress)
                            }
                            .buttonStyle(.plain)
                        } else {
                            card(category, accent: accent, progress: progress)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .background(TrailBackground())
        .navigationTitle(Text(LocalizedStringKey(section.titleKey)))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func card(_ category: Category, accent: Color, progress: ProgressSnapshot) -> some View {
        let done = progress.completedTasks(in: category)
        let total = ContentCatalog.tasksPerCategory
        let stars = progress.stars(in: category)

        return HStack(spacing: 14) {
            visual(category, accent: accent)
                .frame(width: 96, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.titleKey))
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                if category.isAvailable {
                    Text(LocalizedStringKey(category.descriptionKey))
                        .font(Theme.font(.caption, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                    ProgressView(value: Double(done), total: Double(total))
                        .tint(accent)
                    HStack {
                        Text("progress.fraction \(done) \(total)")
                        Spacer()
                        Label { Text(stars, format: .number) } icon: { Image(systemName: "star.fill") }
                            .foregroundStyle(Theme.yellow)
                    }
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("common.comingSoon")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCard()
        .opacity(category.isAvailable ? 1 : 0.6)
        .accessibilityElement(children: .combine)
    }

    /// A tiny example sentence such as `38 + 47`, or the category icon.
    @ViewBuilder
    private func visual(_ category: Category, accent: Color) -> some View {
        if category.example.isEmpty {
            Image(systemName: category.icon)
                .font(.title)
                .foregroundStyle(accent)
        } else {
            let text = category.example
                .map { notation.symbol(for: $0, locale: locale) }
                .joined(separator: " ")
            Text(text)
                .font(Theme.font(.title3))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityHidden(true)
        }
    }
}
