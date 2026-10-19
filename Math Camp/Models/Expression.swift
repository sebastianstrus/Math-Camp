//
//  Expression.swift
//  Math Camp
//

import Foundation

/// One symbol of a displayed math sentence. Generators never produce strings;
/// views turn tokens into text through `MathNotation` (symbols) and `L10n` (spoken words).
nonisolated enum MathToken: Hashable, Sendable {
    case number(Int)
    case plus, minus, times, divide
    case equals, less, greater
    case openParen, closeParen
    case blank
    /// The unknown `x` in `x + 7 = 15`.
    case variable
}

/// A structured arithmetic expression.
///
/// Printing never adds brackets by itself: brackets appear only where a `.parenthesized` node
/// exists. Generators must therefore build trees whose printed form means the same thing
/// (`ContentValidator` checks this for every exercise).
nonisolated indirect enum Expression: Hashable, Sendable, ExpressibleByIntegerLiteral {
    case number(Int)
    case add(Expression, Expression)
    case subtract(Expression, Expression)
    case multiply(Expression, Expression)
    case divide(Expression, Expression)
    case parenthesized(Expression)

    init(integerLiteral value: Int) {
        self = .number(value)
    }

    // MARK: Convenience builders

    static func n(_ value: Int) -> Expression { .number(value) }

    /// Left-associative sum: `a + b + c`.
    static func sum(_ values: Int...) -> Expression { sum(values) }

    static func sum(_ values: [Int]) -> Expression {
        values.dropFirst().reduce(Expression.number(values[0])) { .add($0, .number($1)) }
    }

    static func diff(_ a: Int, _ b: Int) -> Expression { .subtract(.number(a), .number(b)) }
    static func prod(_ a: Int, _ b: Int) -> Expression { .multiply(.number(a), .number(b)) }
    static func quot(_ a: Int, _ b: Int) -> Expression { .divide(.number(a), .number(b)) }

    // MARK: Evaluation

    /// Value of the expression, or `nil` when a division is not exact (or by zero).
    func evaluate() -> Int? {
        switch self {
        case .number(let value):
            return value
        case .add(let l, let r):
            guard let a = l.evaluate(), let b = r.evaluate() else { return nil }
            return a + b
        case .subtract(let l, let r):
            guard let a = l.evaluate(), let b = r.evaluate() else { return nil }
            return a - b
        case .multiply(let l, let r):
            guard let a = l.evaluate(), let b = r.evaluate() else { return nil }
            return a * b
        case .divide(let l, let r):
            guard let a = l.evaluate(), let b = r.evaluate(), b != 0, a % b == 0 else { return nil }
            return a / b
        case .parenthesized(let inner):
            return inner.evaluate()
        }
    }

    /// `true` when every sub-result is a non-negative integer and every division is exact.
    var isWellFormed: Bool {
        switch self {
        case .number(let value):
            return value >= 0
        case .parenthesized(let inner):
            return inner.isWellFormed
        case .add(let l, let r), .subtract(let l, let r), .multiply(let l, let r), .divide(let l, let r):
            guard l.isWellFormed, r.isWellFormed, let value = evaluate() else { return false }
            return value >= 0
        }
    }

    /// Every number written in the expression, left to right.
    var numberLeaves: [Int] {
        switch self {
        case .number(let value): [value]
        case .parenthesized(let inner): inner.numberLeaves
        case .add(let l, let r), .subtract(let l, let r), .multiply(let l, let r), .divide(let l, let r):
            l.numberLeaves + r.numberLeaves
        }
    }

    /// Every intermediate and final value (used for range checks).
    var allValues: [Int] {
        switch self {
        case .number(let value):
            return [value]
        case .parenthesized(let inner):
            return inner.allValues
        case .add(let l, let r), .subtract(let l, let r), .multiply(let l, let r), .divide(let l, let r):
            return l.allValues + r.allValues + [evaluate()].compactMap { $0 }
        }
    }

    // MARK: Tokens

    /// Appends the tokens of this expression. `blank` decides whether the leaf with the given
    /// global index (counted across the whole equation) is replaced by a blank.
    func appendTokens(to tokens: inout [MathToken], leafIndex: inout Int, blank: (Int) -> Bool) {
        switch self {
        case .number(let value):
            tokens.append(blank(leafIndex) ? .blank : .number(value))
            leafIndex += 1
        case .parenthesized(let inner):
            tokens.append(.openParen)
            inner.appendTokens(to: &tokens, leafIndex: &leafIndex, blank: blank)
            tokens.append(.closeParen)
        case .add(let l, let r):
            appendBinary(l, .plus, r, to: &tokens, leafIndex: &leafIndex, blank: blank)
        case .subtract(let l, let r):
            appendBinary(l, .minus, r, to: &tokens, leafIndex: &leafIndex, blank: blank)
        case .multiply(let l, let r):
            appendBinary(l, .times, r, to: &tokens, leafIndex: &leafIndex, blank: blank)
        case .divide(let l, let r):
            appendBinary(l, .divide, r, to: &tokens, leafIndex: &leafIndex, blank: blank)
        }
    }

    private func appendBinary(_ l: Expression, _ op: MathToken, _ r: Expression,
                              to tokens: inout [MathToken], leafIndex: inout Int,
                              blank: (Int) -> Bool) {
        l.appendTokens(to: &tokens, leafIndex: &leafIndex, blank: blank)
        tokens.append(op)
        r.appendTokens(to: &tokens, leafIndex: &leafIndex, blank: blank)
    }

    /// Tokens with no blanks.
    var tokens: [MathToken] {
        var result: [MathToken] = []
        var index = 0
        appendTokens(to: &result, leafIndex: &index, blank: { _ in false })
        return result
    }

    /// What a child would get by reading the printed form while ignoring the brackets
    /// (standard precedence). `nil` for non-integer results.
    var valueIgnoringParentheses: Int? {
        InfixEvaluator.evaluate(tokens.filter { $0 != .openParen && $0 != .closeParen })
    }
}

/// Evaluates a printed token sequence with the usual precedence (× ÷ before + −) and brackets.
/// Used to prove that what is *displayed* means what the expression tree says.
nonisolated enum InfixEvaluator {
    static func evaluate(_ tokens: [MathToken]) -> Int? {
        var position = 0
        guard let value = parseSum(tokens, &position), position == tokens.count else { return nil }
        return value
    }

    private static func parseSum(_ tokens: [MathToken], _ position: inout Int) -> Int? {
        guard var value = parseProduct(tokens, &position) else { return nil }
        while position < tokens.count {
            let token = tokens[position]
            guard token == .plus || token == .minus else { break }
            position += 1
            guard let rhs = parseProduct(tokens, &position) else { return nil }
            value = token == .plus ? value + rhs : value - rhs
        }
        return value
    }

    private static func parseProduct(_ tokens: [MathToken], _ position: inout Int) -> Int? {
        guard var value = parseAtom(tokens, &position) else { return nil }
        while position < tokens.count {
            let token = tokens[position]
            guard token == .times || token == .divide else { break }
            position += 1
            guard let rhs = parseAtom(tokens, &position) else { return nil }
            if token == .times {
                value *= rhs
            } else {
                guard rhs != 0, value % rhs == 0 else { return nil }
                value /= rhs
            }
        }
        return value
    }

    private static func parseAtom(_ tokens: [MathToken], _ position: inout Int) -> Int? {
        guard position < tokens.count else { return nil }
        switch tokens[position] {
        case .number(let value):
            position += 1
            return value
        case .openParen:
            position += 1
            guard let value = parseSum(tokens, &position),
                  position < tokens.count, tokens[position] == .closeParen else { return nil }
            position += 1
            return value
        default:
            return nil
        }
    }
}
