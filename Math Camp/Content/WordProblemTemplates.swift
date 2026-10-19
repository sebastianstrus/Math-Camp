//
//  WordProblemTemplates.swift
//  Math Camp
//
//  The list of stories per section. The English texts are in Localizable.xcstrings
//  under the key `wp.<id>`; the kind decides how numbers are drawn and how the answer is computed.
//
//  Writing rules for every text (they make translation easy):
//  present tense · names only as the subject · no he/she/him/her · short sentences ·
//  no idioms, money, imperial units or country-specific holidays/sports ·
//  the object noun is part of the text, only names and numbers are substituted.
//

import Foundation

nonisolated enum WordProblems {
    private static func t(_ id: String, _ kind: WordProblemKind, _ args: String) -> WordProblemTemplate {
        WordProblemTemplate(id: id, kind: kind, args: args)
    }

    /// Every word-problem generator, one per section.
    static var all: [WordProblemGenerator] {
        [section1, section2, section3, section4, section5, section6, section7]
    }

    static func template(id: String) -> WordProblemTemplate? {
        all.lazy.flatMap(\.templates).first { $0.id == id }
    }

    // MARK: Section I – Word Problems to 20

    static let section1 = WordProblemGenerator(
        templates: [
            t("s1.add.01", .addJoin, "pab"), t("s1.add.02", .addJoin, "ab"), t("s1.add.03", .addJoin, "pab"), t("s1.add.04", .addJoin, "ab"),
            t("s1.sub.01", .subtractAway, "ab"), t("s1.sub.02", .subtractAway, "pab"),
            t("s1.sub.03", .subtractAway, "ab"), t("s1.sub.04", .subtractAway, "pab"),
            t("s1.cmp.01", .compare, "pqab"), t("s1.cmp.02", .compare, "pqab"), t("s1.cmp.03", .compare, "ab"),
            t("s1.more.01", .moreThan, "pqab"), t("s1.more.02", .moreThan, "pqab"),
            t("s1.less.01", .lessThan, "pqab"), t("s1.less.02", .lessThan, "pqab"),
            t("s1.miss.01", .missingPart, "pab"), t("s1.miss.02", .missingPart, "pab"),
            t("s1.two.01", .twoStepAddSub, "pabc"), t("s1.two.02", .twoStepAddSub, "abc"),
            t("s1.two.03", .twoStepSubSub, "pabc"), t("s1.two.04", .twoStepAddAdd, "pabc"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 10),
            plan: [[.addJoin], [.addJoin], [.subtractAway], [.subtractAway],
                   [.addJoin, .subtractAway], [.addJoin, .subtractAway]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 20),
            plan: [[.addJoin], [.subtractAway], [.moreThan], [.lessThan],
                   [.addJoin, .subtractAway], [.moreThan, .lessThan]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 20),
            plan: [[.compare], [.compare], [.missingPart], [.missingPart, .compare],
                   WordProblemKind.twoStep, WordProblemKind.twoStep]))

    // MARK: Section II – Word Problems to 100

    static let section2 = WordProblemGenerator(
        templates: [
            t("s2.add.01", .addJoin, "ab"), t("s2.add.02", .addJoin, "pab"), t("s2.add.03", .addJoin, "ab"), t("s2.add.04", .addJoin, "pab"),
            t("s2.sub.01", .subtractAway, "ab"), t("s2.sub.02", .subtractAway, "pab"),
            t("s2.sub.03", .subtractAway, "ab"), t("s2.sub.04", .subtractAway, "ab"),
            t("s2.cmp.01", .compare, "pqab"), t("s2.cmp.02", .compare, "pqab"), t("s2.cmp.03", .compare, "ab"),
            t("s2.more.01", .moreThan, "pqab"), t("s2.more.02", .moreThan, "pqab"),
            t("s2.less.01", .lessThan, "pqab"), t("s2.less.02", .lessThan, "pqab"),
            t("s2.miss.01", .missingPart, "pab"), t("s2.miss.02", .missingPart, "pab"),
            t("s2.two.01", .twoStepAddSub, "abc"), t("s2.two.02", .twoStepSubSub, "pabc"),
            t("s2.two.03", .twoStepAddAdd, "pabc"), t("s2.two.04", .twoStepAddSub, "abc"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 50, minOperand: 5),
            plan: [[.addJoin], [.addJoin], [.subtractAway], [.subtractAway],
                   [.addJoin, .subtractAway], [.addJoin, .subtractAway]]),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 5),
            plan: [[.compare], [.compare], [.moreThan], [.lessThan], [.missingPart],
                   [.addJoin, .subtractAway]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(limit: 100, minOperand: 5),
            plan: [WordProblemKind.twoStep, WordProblemKind.twoStep, WordProblemKind.twoStep,
                   WordProblemKind.twoStep, [.compare, .missingPart], [.moreThan, .lessThan]]))

    // MARK: Section III – Word Problems: Groups & Sharing

    static let section3 = WordProblemGenerator(
        templates: [
            t("s3.grp.01", .equalGroups, "ab"), t("s3.grp.02", .equalGroups, "pab"), t("s3.grp.03", .equalGroups, "ab"),
            t("s3.grp.04", .equalGroups, "ab"), t("s3.grp.05", .equalGroups, "pab"), t("s3.grp.06", .equalGroups, "ab"),
            t("s3.shr.01", .shareEqually, "pab"), t("s3.shr.02", .shareEqually, "ab"), t("s3.shr.03", .shareEqually, "pab"),
            t("s3.div.01", .divideGroups, "pab"), t("s3.div.02", .divideGroups, "ab"), t("s3.div.03", .divideGroups, "pab"),
            t("s3.tms.01", .timesMore, "pqab"), t("s3.tms.02", .timesMore, "pqab"), t("s3.tms.03", .timesMore, "ab"),
            t("s3.rem.01", .remainder, "pab"), t("s3.rem.02", .remainder, "ab"),
            t("s3.up.01", .roundUp, "ab"), t("s3.up.02", .roundUp, "pab"), t("s3.up.03", .roundUp, "ab"),
            t("s3.mad.01", .mulAdd, "pabc"), t("s3.mad.02", .mulAdd, "abc"),
            t("s3.msb.01", .mulSub, "pabc"), t("s3.msb.02", .mulSub, "abc"),
        ],
        easy: WordProblemTierRule(
            numbers: WordProblemNumbers(factors: [2, 5, 10]),
            plan: Array(repeating: [.equalGroups], count: 6)),
        medium: WordProblemTierRule(
            numbers: WordProblemNumbers(),
            plan: [[.shareEqually], [.shareEqually], [.divideGroups], [.divideGroups],
                   [.timesMore], [.timesMore]]),
        hard: WordProblemTierRule(
            numbers: WordProblemNumbers(),
            plan: [[.remainder], [.roundUp], [.roundUp], [.mulAdd, .mulSub], [.mulAdd, .mulSub],
                   [.remainder, .roundUp]]))
}
