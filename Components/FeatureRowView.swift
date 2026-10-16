import SwiftUI

struct FeatureRowView: View {
    let title: String
    let isIncluded: Bool
    var detail: String?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundStyle(isIncluded ? AppColors.success : AppColors.danger)
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
