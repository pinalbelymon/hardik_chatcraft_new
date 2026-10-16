import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    private var isCompactDevice: Bool {
        DeviceSize.isCurrentCompactHeight
    }

    init(title: String, message: String, systemImage: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: isCompactDevice ? 34 : 44, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
                .frame(width: isCompactDevice ? 58 : 74, height: isCompactDevice ? 58 : 74)
                .background(AppColors.brandGradient, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .shadow(color: AppColors.appTint.opacity(0.18), radius: 18, y: 10)

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font((isCompactDevice ? Font.headline : Font.title3).weight(.bold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(isCompactDevice ? .caption : .callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, isCompactDevice ? AppSpacing.md : AppSpacing.lg)
                        .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
                        .background(AppColors.appTint.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompactDevice ? AppSpacing.lg : AppSpacing.xxl)
        .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.lg)
    }
}
