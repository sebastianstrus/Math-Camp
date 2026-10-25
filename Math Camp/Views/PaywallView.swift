//
//  PaywallView.swift
//  Math Camp
//

import SwiftUI
import StoreKit

/// The Premium offer: monthly, yearly and lifetime.
struct PaywallView: View {
    @Environment(PremiumAccess.self) private var premium
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID: String?
    /// True on short screens (e.g. iPhone SE), where text and spacing shrink so the whole offer fits.
    @State private var isCompact = false

    private static let compactHeight: CGFloat = 700

    private var selectedProduct: Product? {
        premium.products.first { $0.id == selectedID }
            ?? premium.products.first { $0.id == PremiumPlan.yearly.rawValue }
            ?? premium.products.first
    }

    var body: some View {
        ZStack {
            TrailBackground()

            ScrollView {
                VStack(spacing: isCompact ? 16 : 22) {
                    header
                    benefits

                    if premium.isPremium {
                        Text("premium.active")
                            .font(Theme.font(.title3))
                            .foregroundStyle(Theme.correct)
                            .multilineTextAlignment(.center)
                        Button("common.close") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                    } else {
                        offer
                    }
                }
                .padding(18)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.height < Self.compactHeight
        } action: { compact in
            isCompact = compact
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.16), in: Circle())
            }
            .padding(isCompact ? 8 : 16)
            .accessibilityLabel(Text("common.close"))
        }
        .task {
            if premium.products.isEmpty { await premium.loadProducts() }
        }
        .onChange(of: premium.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }

    // MARK: Header and benefits

    private var header: some View {
        VStack(spacing: isCompact ? 6 : 10) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: isCompact ? 40 : 54))
                .foregroundStyle(Theme.sunset)
                .accessibilityHidden(true)
            Text("premium.title")
                .font(Theme.font(isCompact ? .title2 : .largeTitle))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("premium.subtitle")
                .font(Theme.font(isCompact ? .subheadline : .body, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, isCompact ? 12 : 24)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: isCompact ? 9 : 12) {
            benefit("premium.benefit.1")
            benefit("premium.benefit.2")
            benefit("premium.benefit.3")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isCompact ? 16 : 18)
        .themeCard()
    }

    private func benefit(_ key: LocalizedStringKey) -> some View {
        Label {
            Text(key)
                .font(Theme.font(isCompact ? .subheadline : .body, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        } icon: {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.correct)
        }
    }

    // MARK: Offer

    @ViewBuilder
    private var offer: some View {
        switch premium.loadState {
        case .idle, .loading:
            ProgressView().tint(Theme.textPrimary).padding(.vertical, 24)
        case .failed:
            VStack(spacing: 12) {
                Text("premium.unavailable")
                    .font(Theme.font(.body, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("premium.retry") { Task { await premium.loadProducts() } }
                    .buttonStyle(SecondaryButtonStyle())
            }
        case .loaded:
            VStack(spacing: 12) {
                ForEach(premium.products) { product in plan(product) }

                Button {
                    guard let product = selectedProduct else { return }
                    Task { await premium.purchase(product) }
                } label: {
                    if premium.purchasingID != nil {
                        ProgressView().tint(Theme.navyDeep)
                    } else {
                        Text("premium.continue")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(premium.purchasingID != nil || selectedProduct == nil)
                .padding(.top, 6)
            }
        }

        if let message = premium.errorMessage {
            Text(message)
                .font(Theme.font(.footnote, weight: .medium))
                .foregroundStyle(Theme.wrong)
                .multilineTextAlignment(.center)
        }

        Button("premium.restore") { Task { await premium.restorePurchases() } }
            .font(Theme.font(.subheadline))
            .foregroundStyle(Theme.textSecondary)
            .frame(minHeight: isCompact ? 40 : Theme.minTouch)
    }

    private func plan(_ product: Product) -> some View {
        let isSelected = product.id == selectedProduct?.id
        let kind = PremiumPlan(rawValue: product.id)

        return Button {
            selectedID = product.id
        } label: {
            HStack(spacing: isCompact ? 10 : 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(isCompact ? .body : .title3)
                    .foregroundStyle(isSelected ? Theme.yellow : Theme.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(Theme.font(isCompact ? .subheadline : .headline))
                        .foregroundStyle(Theme.textPrimary)
                    Text(LocalizedStringKey(periodKey(for: kind)))
                        .font(Theme.font(isCompact ? .caption2 : .caption, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                Text(product.displayPrice)
                    .font(Theme.font(isCompact ? .headline : .title3))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(isCompact ? 13 : 16)
            .frame(maxWidth: .infinity, minHeight: isCompact ? 56 : 64)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.16 : 0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isSelected ? Theme.yellow : Color.white.opacity(0.16),
                                          lineWidth: isSelected ? 2.5 : 1)
                    }
            }
            // The badge sits on the card's top edge so it doesn't make the card taller.
            .overlay(alignment: .topTrailing) {
                if kind == .yearly {
                    Text("premium.badge.best")
                        .font(Theme.font(.caption2))
                        .foregroundStyle(Theme.navyDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.yellow, in: Capsule())
                        .offset(x: -16, y: -7)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func periodKey(for plan: PremiumPlan?) -> String {
        switch plan {
        case .monthly: "premium.period.monthly"
        case .yearly: "premium.period.yearly"
        case .lifetime, nil: "premium.period.lifetime"
        }
    }
}
