//
//  TaskView.swift
//  Math Camp
//

import SwiftUI
import SwiftData

/// Solving one task. "Next task" swaps the session in place, so the navigation stack stays untouched.
struct TaskView: View {
    let category: Category

    @State private var taskNumber: Int
    @State private var session: TaskSession
    @State private var showResults = false
    @State private var showPremium = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.mathNotation) private var notation
    @Environment(PremiumAccess.self) private var premium

    init(category: Category, taskNumber: Int) {
        self.category = category
        _taskNumber = State(initialValue: taskNumber)
        _session = State(initialValue: TaskSession(category: category, taskNumber: taskNumber))
    }

    private var formatter: PromptFormatter { PromptFormatter(notation: notation, locale: locale) }
    private var tier: Tier { Tier.tier(forTask: taskNumber) }
    private var hasNextTask: Bool { taskNumber < ContentCatalog.tasksPerCategory }

    var body: some View {
        ZStack {
            TrailBackground()

            VStack(spacing: 0) {
                switch category.style {
                case .drill: drillContent
                case .interactive: interactiveContent
                }
                bottomPanel
            }

            if showResults {
                ResultsOverlay(
                    correct: session.correctCount, total: session.total, stars: session.stars,
                    hasNextTask: hasNextTask,
                    onTryAgain: tryAgain, onNext: nextTask,
                    onReview: { withAnimation(.snappy) { showResults = false } })
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .navigationTitle(Text(LocalizedStringKey(category.titleKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPremium) { PaywallView() }
        .sensoryFeedback(.success, trigger: session.isChecked) { _, checked in checked && session.stars >= 2 }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: tier.symbolName)
                .foregroundStyle(Theme.yellow)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(tier.titleKey))
            Spacer()
            Text("task.number \(taskNumber)")
        }
        .font(Theme.font(.headline))
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 6)
    }

    // MARK: Drill: everything on one page

    private var drillContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    header
                    ForEach(session.exercises) { exercise in
                        ExerciseRow(session: session, index: exercise.id, formatter: formatter)
                            .id(exercise.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .readableContent()
            }
            .onChange(of: session.activeExercise) { _, newValue in
                withAnimation(.snappy) { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
    }

    // MARK: Interactive: one exercise at a time

    private var interactiveContent: some View {
        let index = session.activeExercise
        let answered = session.exercises.indices.filter { session.isAnswered($0) }.count

        return VStack(spacing: 14) {
            header

            HStack(spacing: 12) {
                pagerButton(systemImage: "chevron.left", label: "task.previous", target: index - 1)
                VStack(spacing: 6) {
                    Text("task.progress \(index + 1) \(session.total)")
                        .font(Theme.font(.title3))
                        .foregroundStyle(Theme.textPrimary)
                    ProgressView(value: Double(answered), total: Double(max(session.total, 1)))
                        .tint(Theme.yellow)
                        .accessibilityHidden(true)
                }
                pagerButton(systemImage: "chevron.right", label: "task.next", target: index + 1)
            }

            ScrollView {
                if session.exercises.indices.contains(index) {
                    InteractiveExerciseView(session: session, index: index, formatter: formatter)
                        .id(index)
                        .transition(.opacity)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .readableContent()
    }

    private func pagerButton(systemImage: String, label: LocalizedStringKey, target: Int) -> some View {
        Button {
            withAnimation(.snappy) { session.go(to: target) }
        } label: {
            Image(systemName: systemImage)
                .font(Theme.font(.title3))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.14), in: Circle())
        }
        .disabled(!session.exercises.indices.contains(target))
        .opacity(session.exercises.indices.contains(target) ? 1 : 0.35)
        .accessibilityLabel(Text(label))
    }

    // MARK: Bottom panel (Check + keypad, or the result actions)

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if session.isChecked {
                checkedActions
            } else {
                Button("task.check", action: check)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!session.isComplete)
                    .frame(maxWidth: 520)

                if let exercise = session.activeExerciseValue, exercise.needsKeypad {
                    NumericKeypad(kind: exercise.inputKind) { session.press($0) }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(Theme.navyDeep.opacity(0.94))
                .shadow(color: .black.opacity(0.35), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.snappy, value: session.isChecked)
    }

    private var checkedActions: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.snappy) { showResults = true }
            } label: {
                HStack(spacing: 8) {
                    Text("results.score \(session.correctCount) \(session.total)")
                    StarsLabel(count: session.stars)
                }
            }
            .buttonStyle(.plain)
            .font(Theme.font(.headline))
            .foregroundStyle(Theme.textPrimary)
            .frame(minHeight: Theme.minTouch)

            HStack(spacing: 12) {
                Button("results.tryAgain", action: tryAgain)
                    .buttonStyle(SecondaryButtonStyle())
                Button(LocalizedStringKey(hasNextTask ? "results.nextTask" : "results.backToCategory"), action: nextTask)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: 520)
        }
    }

    // MARK: Actions

    private func check() {
        session.check()
        guard session.isChecked else { return }
        TaskResult.record(correct: session.correctCount, total: session.total,
                          categoryID: category.id, taskNumber: taskNumber, in: modelContext)
        withAnimation(.spring(duration: 0.45, bounce: 0.3)) { showResults = true }
    }

    private func tryAgain() {
        withAnimation(.snappy) {
            session.retry()
            showResults = false
        }
    }

    private func nextTask() {
        let next = taskNumber + 1
        guard next <= ContentCatalog.tasksPerCategory else {
            dismiss()
            return
        }
        guard premium.isUnlocked(category, taskNumber: next) else {
            showPremium = true
            return
        }
        withAnimation(.snappy) {
            taskNumber = next
            session = TaskSession(category: category, taskNumber: next)
            showResults = false
        }
    }
}

// MARK: - Stars

/// Three small stars, `count` of them filled. Reads as "2 stars" to VoiceOver.
struct StarsLabel: View {
    let count: Int
    var maximum = 3

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maximum, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .foregroundStyle(index < count ? Theme.yellow : Color.white.opacity(0.35))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("stars.count \(count)"))
    }
}

// MARK: - Results

/// The result card shown after "Check": score, animated stars and what to do next.
struct ResultsOverlay: View {
    let correct: Int
    let total: Int
    let stars: Int
    let hasNextTask: Bool
    let onTryAgain: () -> Void
    let onNext: () -> Void
    let onReview: () -> Void

    @State private var shownStars = 0
    @ScaledMetric(relativeTo: .largeTitle) private var starSize: CGFloat = 52

    /// A plain `String` variable, so it is looked up as a key (not as an interpolated literal).
    private var messageKey: String { "results.message.\(stars)" }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(LocalizedStringKey(messageKey))
                    .font(Theme.font(.title2))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        let isOn = index < shownStars
                        Image(systemName: isOn ? "star.fill" : "star")
                            .font(.system(size: starSize))
                            .foregroundStyle(isOn ? Theme.yellow : Color.white.opacity(0.3))
                            .scaleEffect(isOn ? 1 : 0.7)
                            .symbolEffect(.bounce, value: isOn)
                            .shadow(color: isOn ? Theme.orange.opacity(0.6) : .clear, radius: 10)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("stars.count \(stars)"))

                Text("results.score \(correct) \(total)")
                    .font(Theme.font(.title))
                    .foregroundStyle(Theme.textPrimary)

                VStack(spacing: 10) {
                    Button(LocalizedStringKey(hasNextTask ? "results.nextTask" : "results.backToCategory"), action: onNext)
                        .buttonStyle(PrimaryButtonStyle())
                    HStack(spacing: 10) {
                        Button("results.tryAgain", action: onTryAgain)
                            .buttonStyle(SecondaryButtonStyle())
                        Button("results.review", action: onReview)
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Theme.navy)
                    .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
            }
            .padding(24)
        }
        .task {
            // Stars pop in one after another.
            for star in stride(from: 1, through: stars, by: 1) {
                try? await Task.sleep(for: .milliseconds(380))
                withAnimation(.spring(duration: 0.45, bounce: 0.55)) { shownStars = star }
            }
        }
    }
}
