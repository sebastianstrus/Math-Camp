//
//  WordProblemTemplatesExtra.swift
//  Math Camp
//
//  Stories for Sections IV–VII. Same writing rules as `WordProblemTemplates.swift`.
//  Generated texts live in Localizable.xcstrings under `wp.<id>`.
//

import Foundation

nonisolated extension WordProblems {
    private static func tpl(_ id: String, _ kind: WordProblemKind, _ args: String) -> WordProblemTemplate {
        WordProblemTemplate(id: id, kind: kind, args: args)
    }

    static let section4 = WordProblemGenerator(
        templates: [
            tpl("s4.add.01", .addJoin, "pab"),
            tpl("s4.add.02", .addJoin, "ab"),
            tpl("s4.add.03", .addJoin, "ab"),
            tpl("s4.add.04", .addJoin, "pab"),
            tpl("s4.sub.01", .subtractAway, "ab"),
            tpl("s4.sub.02", .subtractAway, "pab"),
            tpl("s4.sub.03", .subtractAway, "ab"),
            tpl("s4.sub.04", .subtractAway, "ab"),
            tpl("s4.cmp.01", .compare, "pqab"),
            tpl("s4.cmp.02", .compare, "pqab"),
            tpl("s4.cmp.03", .compare, "ab"),
            tpl("s4.more.01", .moreThan, "pqab"),
            tpl("s4.more.02", .moreThan, "pqab"),
            tpl("s4.less.01", .lessThan, "pqab"),
            tpl("s4.less.02", .lessThan, "pqab"),
            tpl("s4.miss.01", .missingPart, "pab"),
            tpl("s4.miss.02", .missingPart, "pab"),
            tpl("s4.two.01", .twoStepAddSub, "abc"),
            tpl("s4.two.02", .twoStepSubSub, "pabc"),
            tpl("s4.two.03", .twoStepAddAdd, "pabc"),
            tpl("s4.two.04", .twoStepAddSub, "abc"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 500, minOperand: 20),
            plan: [[.addJoin], [.addJoin], [.subtractAway], [.subtractAway], [.addJoin, .subtractAway], [.addJoin, .subtractAway]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 1000, minOperand: 20),
            plan: [[.compare], [.compare], [.moreThan], [.lessThan], [.missingPart], [.addJoin, .subtractAway]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 1000, minOperand: 20),
            plan: [WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep, [.compare, .missingPart], [.moreThan, .lessThan]]))

    static let section5 = WordProblemGenerator(
        templates: [
            tpl("s5.half.01", .shareFraction(2), "pa"),
            tpl("s5.half.02", .shareFraction(2), "a"),
            tpl("s5.half.03", .shareFraction(2), "a"),
            tpl("s5.half.04", .shareFraction(2), "pa"),
            tpl("s5.quarter.01", .shareFraction(4), "pa"),
            tpl("s5.quarter.02", .shareFraction(4), "a"),
            tpl("s5.quarter.03", .shareFraction(4), "a"),
            tpl("s5.third.01", .shareFraction(3), "a"),
            tpl("s5.third.02", .shareFraction(3), "pa"),
            tpl("s5.fifth.01", .shareFraction(5), "a"),
            tpl("s5.tenth.01", .shareFraction(10), "a"),
            tpl("s5.resthalf.01", .fractionRest(2), "pa"),
            tpl("s5.resthalf.02", .fractionRest(2), "a"),
            tpl("s5.restquarter.01", .fractionRest(4), "pa"),
            tpl("s5.restquarter.02", .fractionRest(4), "a"),
            tpl("s5.restthird.01", .fractionRest(3), "a"),
            tpl("s5.pct10.01", .percentOf(10), "a"),
            tpl("s5.pct10.02", .percentOf(10), "pa"),
            tpl("s5.pct25.01", .percentOf(25), "a"),
            tpl("s5.pct25.02", .percentOf(25), "pa"),
            tpl("s5.pct50.01", .percentOf(50), "a"),
            tpl("s5.pct50.02", .percentOf(50), "pa"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 40, minOperand: 2),
            plan: [[.shareFraction(2)], [.shareFraction(2)], [.shareFraction(4)], [.shareFraction(4)], [.shareFraction(2), .shareFraction(4)], [.shareFraction(2), .shareFraction(4)]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 2),
            plan: [[.shareFraction(3), .shareFraction(5)], [.shareFraction(10), .shareFraction(3)], [.fractionRest(2)], [.fractionRest(4)], [.fractionRest(2), .fractionRest(3)], [.fractionRest(4), .fractionRest(3)]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 200, minOperand: 2),
            plan: [[.percentOf(10)], [.percentOf(10)], [.percentOf(25)], [.percentOf(25)], [.percentOf(50)], [.percentOf(50)]]))

    static let section6 = WordProblemGenerator(
        templates: [
            tpl("s6.add.01", .addJoin, "pab"),
            tpl("s6.add.02", .addJoin, "pab"),
            tpl("s6.add.03", .addJoin, "ab"),
            tpl("s6.add.04", .addJoin, "pab"),
            tpl("s6.sub.01", .subtractAway, "pab"),
            tpl("s6.sub.02", .subtractAway, "pab"),
            tpl("s6.sub.03", .subtractAway, "pab"),
            tpl("s6.sub.04", .subtractAway, "pab"),
            tpl("s6.cmp.01", .compare, "pqab"),
            tpl("s6.cmp.02", .compare, "pqab"),
            tpl("s6.cmp.03", .compare, "ab"),
            tpl("s6.more.01", .moreThan, "pqab"),
            tpl("s6.more.02", .moreThan, "ab"),
            tpl("s6.less.01", .lessThan, "pqab"),
            tpl("s6.less.02", .lessThan, "ab"),
            tpl("s6.miss.01", .missingPart, "pab"),
            tpl("s6.miss.02", .missingPart, "pab"),
            tpl("s6.two.01", .twoStepAddAdd, "pabc"),
            tpl("s6.two.02", .twoStepAddSub, "pabc"),
            tpl("s6.two.03", .twoStepSubSub, "pabc"),
            tpl("s6.two.04", .twoStepAddSub, "pabc"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 50, minOperand: 5),
            plan: [[.addJoin], [.addJoin], [.subtractAway], [.subtractAway], [.addJoin, .subtractAway], [.addJoin, .subtractAway]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 5),
            plan: [[.compare], [.compare], [.moreThan], [.lessThan], [.missingPart], [.addJoin, .subtractAway]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 200, minOperand: 5),
            plan: [WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep, [.compare, .missingPart], [.moreThan, .lessThan]]))

    static let section7 = WordProblemGenerator(
        templates: [
            tpl("s7.add.01", .addJoin, "pab"),
            tpl("s7.add.02", .addJoin, "ab"),
            tpl("s7.add.03", .addJoin, "ab"),
            tpl("s7.sub.01", .subtractAway, "ab"),
            tpl("s7.sub.02", .subtractAway, "pab"),
            tpl("s7.sub.03", .subtractAway, "ab"),
            tpl("s7.cmp.01", .compare, "pqab"),
            tpl("s7.cmp.02", .compare, "pqab"),
            tpl("s7.more.01", .moreThan, "pqab"),
            tpl("s7.more.02", .moreThan, "pqab"),
            tpl("s7.less.01", .lessThan, "pqab"),
            tpl("s7.less.02", .lessThan, "pqab"),
            tpl("s7.miss.01", .missingPart, "pab"),
            tpl("s7.miss.02", .missingPart, "pab"),
            tpl("s7.two.01", .twoStepAddSub, "pabc"),
            tpl("s7.two.02", .twoStepSubSub, "abc"),
            tpl("s7.two.03", .twoStepAddAdd, "pabc"),
            tpl("s7.grp.01", .equalGroups, "ab"),
            tpl("s7.grp.02", .equalGroups, "pab"),
            tpl("s7.shr.01", .shareEqually, "pab"),
            tpl("s7.shr.02", .shareEqually, "ab"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 50, minOperand: 5, factors: [2, 5, 10]),
            plan: [[.addJoin], [.addJoin], [.subtractAway], [.subtractAway], [.equalGroups], [.shareEqually]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 5),
            plan: [[.compare], [.moreThan], [.lessThan], [.missingPart], [.equalGroups], [.shareEqually]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 5),
            plan: [WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep, [.compare, .missingPart], [.moreThan, .lessThan], [.equalGroups, .shareEqually]]))
}
