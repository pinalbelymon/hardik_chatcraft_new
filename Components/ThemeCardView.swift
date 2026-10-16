import SwiftUI

struct ThemeCardView: View {
  let theme: ChatTheme
  let isSelected: Bool
  let isLocked: Bool

  private var isCompactDevice: Bool {
    DeviceSize.isCurrentCompactHeight
  }

  var body: some View {
    HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
      ThemeIdentityBadge(theme: theme)
        .frame(width: isCompactDevice ? 46 : 58, height: isCompactDevice ? 46 : 58)

      VStack(alignment: .leading, spacing: isCompactDevice ? 4 : 6) {
        HStack(spacing: AppSpacing.xs) {
          Text(theme.name)
            .font((isCompactDevice ? Font.subheadline : Font.headline).weight(.heavy))
            .foregroundStyle(titleColor)
            .lineLimit(isCompactDevice ? 1 : 2)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)

          if isSelected {
            Image(systemName: "checkmark.seal.fill")
              .font(.caption.weight(.heavy))
              .foregroundStyle(AppColors.appTint)
          }
        }

        Text(theme.subtitle)
          .font((isCompactDevice ? Font.caption2 : Font.caption).weight(.semibold))
          .foregroundStyle(subtitleColor)
          .lineLimit(isCompactDevice ? 1 : 2)
          .minimumScaleFactor(0.84)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: AppSpacing.xs) {
          ThemeSwatchStrip(theme: theme)
          ThemeTraitPill(title: theme.category.title, isSelected: isSelected)
          if theme.requiredPlan != .free {
            ThemeTraitPill(
              title: theme.requiredPlan.title,
              iconName: isLocked ? "lock.fill" : "crown.fill",
              isSelected: isSelected
            )
          }
        }
      }
      .layoutPriority(1)

      Spacer(minLength: AppSpacing.xs)

      Image(systemName: isLocked ? "lock.fill" : "chevron.right")
        .font(.caption.weight(.heavy))
        .foregroundStyle(isLocked ? AppColors.amber : trailingIconColor)
    }
    .padding(isCompactDevice ? AppSpacing.sm : AppSpacing.md)
    .background(surfaceFill, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(
          isSelected ? AppColors.appTint.opacity(0.72) : AppColors.hairline,
          lineWidth: isSelected ? 2 : 1)
    )
    .shadow(
      color: isSelected ? AppColors.appTint.opacity(0.14) : Color.black.opacity(0.04),
      radius: isSelected ? 16 : 8, y: 7)
  }

  private var surfaceFill: Color {
    isSelected ? AppColors.appTint.opacity(0.13) : AppColors.panelBackground.opacity(0.58)
  }

  private var titleColor: Color {
    isSelected ? .primary : .primary
  }

  private var subtitleColor: Color {
    isSelected ? Color.primary.opacity(0.72) : Color.secondary
  }

  private var trailingIconColor: Color {
    isSelected ? AppColors.appTint.opacity(0.72) : Color.secondary
  }
}

struct ThemeIdentityBadge: View {
  let theme: ChatTheme

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(hex: theme.style.backgroundHex),
              Color(hex: theme.style.wallpaperAccentHex),
              Color(hex: theme.style.accentHex).opacity(0.78),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      VStack(spacing: 5) {
        Capsule()
          .fill(Color(hex: theme.style.incomingBubbleHex))
          .frame(width: 32, height: 12)
          .frame(maxWidth: .infinity, alignment: .leading)
        Capsule()
          .fill(outgoingFill)
          .frame(width: 38, height: 12)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(10)
    }
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        .stroke(.white.opacity(0.2), lineWidth: 1)
    )
  }

  private var outgoingFill: AnyShapeStyle {
    if theme.style.usesGradientOutgoing {
      return AnyShapeStyle(
        LinearGradient(
          colors: [Color(hex: theme.style.outgoingBubbleHex), Color(hex: theme.style.accentHex)],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
    }
    return AnyShapeStyle(Color(hex: theme.style.outgoingBubbleHex))
  }
}

struct ThemeSwatchStrip: View {
  let theme: ChatTheme

  var body: some View {
    HStack(spacing: -4) {
      Circle().fill(Color(hex: theme.style.backgroundHex))
      Circle().fill(Color(hex: theme.style.incomingBubbleHex))
      Circle().fill(Color(hex: theme.style.outgoingBubbleHex))
      Circle().fill(Color(hex: theme.style.accentHex))
    }
    .frame(width: 44, height: 16)
    .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 0.8))
  }
}

private struct ThemeTraitPill: View {
  let title: String
  var iconName: String?
  var isSelected = false

  var body: some View {
    HStack(spacing: 4) {
      if let iconName {
        Image(systemName: iconName)
          .font(.caption2.weight(.heavy))
      }
      Text(title)
        .font(.caption2.weight(.heavy))
    }
    .foregroundStyle(isSelected ? Color.primary.opacity(0.72) : Color.secondary)
    .padding(.horizontal, 7)
    .padding(.vertical, 4)
    .background(.thinMaterial, in: Capsule())
  }
}
