import SwiftUI

struct LockBadgeView: View {
    var label: String = "Locked"

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "lock.fill")
            Text(label)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
        .background(Color.black.opacity(0.68), in: Capsule())
        .accessibilityLabel(label)
    }
}
