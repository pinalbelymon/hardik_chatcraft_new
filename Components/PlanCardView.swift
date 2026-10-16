import SwiftUI
import UIKit

struct PlanCardView: View {
    let plan: UserPlan
    let price: String
    let subtitle: String
    let isSelected: Bool
    let badge: String?
    var trialText: String?
    var highlights: [String] = []

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var isCompactDevice: Bool {
        DeviceSize.isCurrentCompactHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
            HStack(alignment: .center, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
                planIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: isPad ? 6 : AppSpacing.xs) {
                        Text(plan.title)
                            .font((isPad ? Font.title3 : isCompactDevice ? Font.subheadline : Font.headline).weight(.heavy))
                            .lineLimit(1)
                            .layoutPriority(2)

                        if let badge {
                            Text(badge)
                                .font((isPad ? Font.caption : Font.caption2).weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(plan == .pro ? AppColors.warning : AppColors.success, in: Capsule())
                        }
                    }

                    Text(price)
                        .font((isPad ? Font.title3 : isCompactDevice ? Font.headline : Font.title3).weight(.heavy))
                        .minimumScaleFactor(0.68)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .layoutPriority(3)
                }
                .layoutPriority(2)

                Spacer(minLength: AppSpacing.xs)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(isSelected ? planTint : .secondary.opacity(0.55))
            }

            if let trialText {
                Label(trialText, systemImage: plan == .free ? "checkmark.seal.fill" : "gift.fill")
                    .font((isPad ? Font.headline : isCompactDevice ? Font.caption : Font.subheadline).weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundStyle(planTint)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, 7)
                    .background(planTint.opacity(0.12), in: Capsule())
            }

            Text(subtitle)
                .font((isPad ? Font.subheadline : isCompactDevice ? Font.caption2 : Font.caption).weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(isCompactDevice ? 1 : 2)
                .minimumScaleFactor(0.84)
                .fixedSize(horizontal: false, vertical: true)

            if !highlights.isEmpty {
                VStack(alignment: .leading, spacing: isCompactDevice ? 3 : 5) {
                    ForEach(highlights.prefix(2), id: \.self) { title in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(planTint)

                            Text(title)
                                .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                    }
                }
            }
        }
        .padding(isPad ? AppSpacing.md : isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(isSelected ? planTint.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(isSelected ? planTint : AppColors.hairline, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? planTint.opacity(0.14) : .clear, radius: 12, y: 6)
    }

    private var planIcon: some View {
        Image(systemName: plan == .pro ? "crown.fill" : (plan == .lite ? "bolt.fill" : "sparkles"))
            .font((isPad ? Font.headline : isCompactDevice ? Font.caption : Font.subheadline).weight(.bold))
            .frame(width: isPad ? 48 : isCompactDevice ? 32 : 38, height: isPad ? 48 : isCompactDevice ? 32 : 38)
            .foregroundStyle(.white)
            .background(planTint, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }

    private var planTint: Color {
        switch plan {
        case .free: return AppColors.electricBlue
        case .lite: return AppColors.mint
        case .pro: return AppColors.amber
        }
    }
}
