//
//  NumericKeypad.swift
//  Math Camp
//

import SwiftUI

private struct ScreenHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    /// Height of the screen content, so the keypad can use shorter keys on small phones.
    var screenHeight: CGFloat? {
        get { self[ScreenHeightKey.self] }
        set { self[ScreenHeightKey.self] = newValue }
    }
}

/// Our own big-button keypad (the system keyboard is never shown).
/// Shows digits, the `<` `=` `>` keys, or ✔ / ✘, depending on what the active exercise expects.
struct NumericKeypad: View {
    let kind: InputKind
    let onKey: (KeypadKey) -> Void

    @Environment(\.mathNotation) private var notation
    @ScaledMetric(relativeTo: .title) private var baseKeyHeight: CGFloat = 60
    @Environment(\.screenHeight) private var screenHeight

    /// True on short screens (iPhone SE and similar), where the layout is tightened to avoid scrolling.
    static func isCompact(screenHeight: CGFloat?) -> Bool {
        (screenHeight ?? .infinity) < 750
    }

    /// Full height on large phones, down to 72% (never below the 44pt touch target) on an iPhone SE.
    private var keyHeight: CGFloat {
        guard let screenHeight else { return baseKeyHeight }
        let progress = min(max((screenHeight - 667) / (900 - 667), 0), 1)
        return max(baseKeyHeight * (0.72 + 0.28 * progress), 44)
    }
    @State private var tapCount = 0

    var body: some View {
        Group {
            switch kind {
            case .number: numberPad
            case .signedNumber: VStack(spacing: 10) { extraKey(.negate, label: "±", voice: "keypad.negate"); numberPad }
            case .decimal:
                VStack(spacing: 10) {
                    extraKey(.point, label: notation.decimalSeparatorSymbol, voice: "keypad.point")
                    numberPad
                }
            case .comparison: signPad
            case .boolean: booleanPad
            }
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
    }

    // MARK: Pads

    private var numberPad: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(1...3, id: \.self) { column in
                        digitKey(row * 3 + column)
                    }
                }
            }
            GridRow {
                key(.delete, voice: Text("keypad.delete")) { Image(systemName: "delete.left.fill") }
                digitKey(0)
                key(.next, voice: Text("keypad.next")) { Image(systemName: "arrow.right") }
            }
        }
    }

    private var signPad: some View {
        HStack(spacing: 12) {
            ForEach([ComparisonSign.less, .equal, .greater], id: \.self) { sign in
                key(.sign(sign), voice: Text(notation.spoken(for: sign))) { Text(notation.symbol(for: sign)) }
            }
        }
    }

    private var booleanPad: some View {
        HStack(spacing: 12) {
            key(.boolean(true), voice: Text("answer.true"), tint: Theme.correct) { Image(systemName: "checkmark") }
            key(.boolean(false), voice: Text("answer.false"), tint: Theme.wrong) { Image(systemName: "xmark") }
        }
    }

    // MARK: Keys

    /// A slim key above the digits (± or the decimal separator).
    private func extraKey(_ key: KeypadKey, label: String, voice: LocalizedStringKey) -> some View {
        self.key(key, voice: Text(voice)) { Text(label) }
            .frame(maxHeight: keyHeight * 0.8)
    }

    private func digitKey(_ digit: Int) -> some View {
        key(.digit(digit), voice: Text(digit, format: .number)) { Text(digit, format: .number) }
    }

    private func key(_ key: KeypadKey, voice: Text, tint: Color = .white,
                     @ViewBuilder label: () -> some View) -> some View {
        Button {
            tapCount += 1
            SoundManager.shared.play(.keyTap)
            onKey(key)
        } label: {
            label()
                .font(Theme.font(.title))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                }
        }
        .buttonStyle(KeyPressStyle())
        .accessibilityLabel(voice)
    }
}

/// Dims a key while it is pressed.
private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}
