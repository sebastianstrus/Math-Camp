//
//  CategoryView.swift
//  Math Camp
//

import SwiftUI
import SwiftData

/// The 30 tasks of a category in three groups: Warm-up, Climb, Peak.
struct CategoryView: View {
    let category: Category

    @Query private var results: [TaskResult]
    @Environment(PremiumAccess.self) private var premium
    @State private var showPremium = false

    private var accent: Color {
        ContentCatalog.section(id: category.sectionID).map { Theme.accent(for: $0) } ?? Theme.orange
    }

    var body: some View {
        let progress = ProgressSnapshot(results)
        let today = progress.nextTask(in: category)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(LocalizedStringKey(category.descriptionKey))
                    .font(Theme.font(.body, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                if let today {
                    todayBanner(today)
                }

                ForEach(Tier.allCases) { tier in
                    tierSection(tier, progress: progress, today: today)
                }
            }
            .padding(20)
            .readableContent()
        }
        .background(TrailBackground())
        .navigationTitle(Text(LocalizedStringKey(category.titleKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPremium) { PaywallView() }
        #if DEBUG
        .toolbar { ToolbarItem(placement: .topBarTrailing) { DebugUnlockToggle() } }
        #endif
    }

    // MARK: Today's task

    private func todayBanner(_ number: Int) -> some View {
        taskLink(number) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Theme.navyDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text("task.today")
                        .font(Theme.font(.caption))
                    Text("task.number \(number)")
                        .font(Theme.font(.title3))
                }
                .foregroundStyle(Theme.navyDeep)
                Spacer()
                Image(systemName: "play.fill")
                    .foregroundStyle(Theme.navyDeep)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Theme.sunset, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .shadow(color: Theme.orange.opacity(0.35), radius: 10, y: 4)
        }
    }

    // MARK: Tiers

    private func tierSection(_ tier: Tier, progress: ProgressSnapshot, today: Int?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: tier.symbolName)
                    .foregroundStyle(Theme.yellow)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey(tier.titleKey))
                        .font(Theme.font(.title3))
                        .foregroundStyle(Theme.textPrimary)
                    Text(LocalizedStringKey(tier.subtitleKey))
                        .font(Theme.font(.caption, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                ForEach(Array(tier.taskNumbers), id: \.self) { number in
                    let result = progress.result(categoryID: category.id, taskNumber: number)
                    let isLocked = !premium.isUnlocked(category, taskNumber: number)
                    taskLink(number) {
                        TaskTile(number: number, stars: result?.bestStars, isLocked: isLocked,
                                 isToday: today == number, accent: accent)
                    }
                }
            }
        }
    }

    /// Opens the task, or the Premium sheet if the task is locked.
    @ViewBuilder
    private func taskLink(_ number: Int, @ViewBuilder label: () -> some View) -> some View {
        if premium.isUnlocked(category, taskNumber: number) {
            NavigationLink(value: Route.task(categoryID: category.id, taskNumber: number)) { label() }
                .buttonStyle(.plain)
        } else {
            Button { showPremium = true } label: { label() }
                .buttonStyle(.plain)
        }
    }
}

/// One square of the task grid.
private struct TaskTile: View {
    let number: Int
    /// `nil` when the task was never finished.
    let stars: Int?
    let isLocked: Bool
    let isToday: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(number, format: .number)
                .font(Theme.font(.title2))
                .foregroundStyle(Theme.textPrimary)
            StarsLabel(count: stars ?? 0)
                .font(.caption2)
                .opacity(stars == nil ? 0.4 : 1)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(stars == nil ? Color.white.opacity(0.08) : accent.opacity(0.28))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isToday ? Theme.yellow : Color.white.opacity(0.15), lineWidth: isToday ? 3 : 1)
        }
        .shadow(color: isToday ? Theme.yellow.opacity(0.5) : .clear, radius: 8)
        .overlay(alignment: .topTrailing) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(8)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .top) {
            if isToday {
                Text("task.today.short")
                    .font(Theme.font(.caption2))
                    .foregroundStyle(Theme.navyDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.yellow, in: Capsule())
                    .offset(y: -9)
                    .accessibilityHidden(true)
            }
        }
        .opacity(isLocked ? 0.7 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("task.number \(number)"))
        .accessibilityValue(stars.map { Text("stars.count \($0)") } ?? Text("task.new"))
        .accessibilityHint(isLocked ? Text("task.locked") : (isToday ? Text("task.today") : Text("")))
    }
}

#if DEBUG
/// Debug switch that opens every locked task.
private struct DebugUnlockToggle: View {
    @Environment(PremiumAccess.self) private var premium

    var body: some View {
        @Bindable var premium = premium
        Toggle(isOn: $premium.debugUnlockAll) { Image(systemName: "lock.open.fill") }
            .toggleStyle(.button)
    }
}
#endif
