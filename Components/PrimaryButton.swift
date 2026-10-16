import SwiftUI

enum PrimaryButtonIconPlacement {
    case leading
    case trailing
}

struct PrimaryButton: View {
    let title: String
    var iconName: String?
    var iconPlacement: PrimaryButtonIconPlacement = .leading
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let iconName, iconPlacement == .leading {
                    Image(systemName: iconName)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let iconName, iconPlacement == .trailing {
                    Image(systemName: iconName)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .foregroundStyle(.white)
            .background(
                isEnabled
                    ? LinearGradient(colors: [AppColors.appTint, Color(hex: "#1D4ED8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
            )
            .shadow(color: isEnabled ? AppColors.appTint.opacity(0.18) : .clear, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(InteractiveScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityAddTraits(.isButton)
    }
}
