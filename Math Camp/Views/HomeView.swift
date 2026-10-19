//
//  HomeView.swift
//  Math Camp
//

import SwiftUI
import SwiftData

/// Where every screen can go.
enum Route: Hashable {
    case section(String)
    case category(String)
    case task(categoryID: String, taskNumber: Int)
}

/// "The Trail Map": the sections as stops on a mountain trail.
struct HomeView: View {
    @Query private var results: [TaskResult]
    @Environment(PremiumAccess.self) private var premium
    @State private var showPaywall = false
    @State private var showIntro = false

    var body: some View {
        let progress = ProgressSnapshot(results)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(progress)
                    VStack(spacing: 0) {
                        ForEach(ContentCatalog.sections) { section in
                            SectionTrailRow(section: section, progress: progress,
                                            isLast: section.id == ContentCatalog.sections.last?.id)
                        }
                    }
                }
                .padding(20)
                .readableContent()
            }
            .background(TrailBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(isPresented: $showIntro) { OnboardingView { showIntro = false } }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .section(let id):
                    if let section = ContentCatalog.section(id: id) { SectionView(section: section) }
                case .category(let id):
                    if let category = ContentCatalog.category(id: id) { CategoryView(category: category) }
                case .task(let categoryID, let taskNumber):
                    if let category = ContentCatalog.category(id: categoryID) {
                        TaskView(category: category, taskNumber: taskNumber)
                    }
                }
            }
        }
    }

    private func header(_ progress: ProgressSnapshot) -> some View {
        let available = ContentCatalog.sections.filter(\.isAvailable)
        let done = available.reduce(0) { $0 + progress.completedTasks(in: $1) }
        let total = available.reduce(0) { $0 + $1.taskCount }
        let stars = available.reduce(0) { $0 + progress.stars(in: $1) }

        return VStack(alignment: .leading, spacing: 10) {
            Text("home.title")
                .font(Theme.font(.largeTitle))
                .foregroundStyle(Theme.textPrimary)
            Text("home.subtitle")
                .font(Theme.font(.title3, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 16) {
                Label("progress.fraction \(done) \(total)", systemImage: "figure.hiking")
                Label { Text(stars, format: .number) } icon: { Image(systemName: "star.fill") }
                    .accessibilityLabel(Text("stars.count \(stars)"))
            }
            .font(Theme.font(.headline))
            .foregroundStyle(Theme.yellow)
            .padding(.top, 4)

            HStack(spacing: 10) {
                Button { showPaywall = true } label: {
                    Label(LocalizedStringKey(premium.isPremium ? "premium.status.active" : "premium.status.get"),
                          systemImage: premium.isPremium ? "checkmark.seal.fill" : "lock.open.fill")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: Theme.minTouch)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)

                Button { showIntro = true } label: {
                    Image(systemName: "questionmark")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: Theme.minTouch, height: Theme.minTouch)
                        .background(Color.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("home.howItWorks"))
            }
        }
    }
}

/// One stop of the trail: a node on the dashed path and a card.
private struct SectionTrailRow: View {
    let section: CampSection
    let progress: ProgressSnapshot
    let isLast: Bool

    var body: some View {
        let accent = Theme.accent(for: section)

        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(section.isAvailable ? Theme.navyDeep : Theme.textSecondary)
                    .frame(width: 56, height: 56)
                    .background(section.isAvailable ? accent : Color.white.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
                if !isLast {
                    DashedLine()
                        .stroke(Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 8]))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                }
            }

            Group {
                if section.isAvailable {
                    NavigationLink(value: Route.section(section.id)) { card(accent: accent) }
                        .buttonStyle(.plain)
                } else {
                    card(accent: accent)
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }

    private func card(accent: Color) -> some View {
        let done = progress.completedTasks(in: section)
        let total = section.taskCount

        return VStack(alignment: .leading, spacing: 8) {
            Text("section.number \(section.romanNumeral)")
                .font(Theme.font(.caption))
                .foregroundStyle(accent)
            Text(LocalizedStringKey(section.titleKey))
                .font(Theme.font(.title2))
                .foregroundStyle(Theme.textPrimary)
            Text(LocalizedStringKey(section.subtitleKey))
                .font(Theme.font(.subheadline, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            if section.isAvailable {
                ProgressView(value: Double(done), total: Double(max(total, 1)))
                    .tint(accent)
                    .padding(.top, 4)
                HStack {
                    Text("progress.tasks \(done) \(total)")
                    Spacer()
                    Label { Text(progress.stars(in: section), format: .number) } icon: { Image(systemName: "star.fill") }
                        .foregroundStyle(Theme.yellow)
                }
                .font(Theme.font(.footnote))
                .foregroundStyle(Theme.textSecondary)
            } else {
                Text("common.comingSoon")
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.14), in: Capsule())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .themeCard(accent: section.isAvailable ? accent : nil)
        .opacity(section.isAvailable ? 1 : 0.65)
        .accessibilityElement(children: .combine)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
