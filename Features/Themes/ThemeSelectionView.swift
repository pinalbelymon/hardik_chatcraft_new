import SwiftUI

struct ThemeSelectionView: View {
  @Binding private var selectedThemeID: String
  private var storyBinding: Binding<ChatStory>?

  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedCategory: ChatThemeCategory
  @State private var previewThemeID: String
  @State private var customStyle: ChatThemeStyle
  @State private var showPaywall = false

  private var isCompactDevice: Bool {
    DeviceSize.isCurrentCompactHeight
  }

  init(selectedThemeID: Binding<String>) {
    self._selectedThemeID = selectedThemeID
    self.storyBinding = nil
    let normalizedThemeID = ChatTheme.normalizedID(for: selectedThemeID.wrappedValue)
    let theme = ChatTheme.theme(for: normalizedThemeID)
    self._selectedCategory = State(initialValue: theme.category)
    self._previewThemeID = State(initialValue: normalizedThemeID)
    self._customStyle = State(initialValue: theme.style)
  }

  init(story: Binding<ChatStory>) {
    self._selectedThemeID = story.themeID
    self.storyBinding = story
    let value = story.wrappedValue
    let theme = value.theme
    let normalizedThemeID = ChatTheme.normalizedID(for: value.themeID)
    self._selectedCategory = State(initialValue: theme.category)
    self._previewThemeID = State(initialValue: normalizedThemeID)
    self._customStyle = State(initialValue: value.customThemeStyle ?? theme.style)
  }

  private var filteredThemes: [ChatTheme] {
    ChatTheme.all.filter { $0.category == selectedCategory }
  }

  private var previewTheme: ChatTheme {
    var theme = ChatTheme.theme(for: previewThemeID)
    if theme.isCustom {
      theme.style = customStyle
    }
    return theme
  }

  var body: some View {
    ResponsiveContainer(maxWidth: 980) { width in
      VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
        header(width: width)
        selectedThemePanel(width: width)
        categoryPicker
        themeGrid(width: width)
        if shouldShowCustomBuilder {
          customBuilder
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
    }
    .detailAds()
    .trackScreen(.themes)
    .navigationTitle("Themes")
    .navigationBarTitleDisplayMode(.inline)
    .background(PremiumBackdrop())
    .fullScreenCover(isPresented: $showPaywall) {
      NavigationStack { PaywallView() }
    }
  }

  private func header(width: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
        Image(systemName: "paintpalette.fill")
          .font((isCompactDevice ? Font.subheadline : Font.headline).weight(.heavy))
          .frame(width: isCompactDevice ? 38 : 44, height: isCompactDevice ? 38 : 44)
          .foregroundStyle(.white)
          .background(
            AppColors.brandGradient,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

        VStack(alignment: .leading, spacing: 3) {
          Text("Theme Studio")
            .font(AppFont.font(isCompactDevice ? 27 : 34, weight: .heavy, width: width))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
          Text("Pick an original chat style, then open a full preview before applying.")
            .font(AppFont.caption(width: width))
            .foregroundStyle(.secondary)
            .lineLimit(isCompactDevice ? 2 : nil)
            .minimumScaleFactor(0.84)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private func selectedThemePanel(width: CGFloat) -> some View {
    let isLocked = !subscriptionManager.canUseTheme(previewTheme)

    return VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
      HStack(alignment: .top, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
        ThemeIdentityBadge(theme: previewTheme)
          .frame(width: isCompactDevice ? 56 : 72, height: isCompactDevice ? 56 : 72)

        VStack(alignment: .leading, spacing: isCompactDevice ? 4 : 6) {
          Text("Selected Theme")
            .font(.caption.weight(.heavy))
            .foregroundStyle(AppColors.appTint)
            .textCase(.uppercase)
          Text(previewTheme.name)
            .font(AppFont.font(isCompactDevice ? 20 : 26, weight: .heavy, width: width))
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)
          Text(previewTheme.subtitle)
            .font((isCompactDevice ? Font.caption2 : Font.caption).weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.84)
            .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
      }

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        ThemeSwatchStrip(theme: previewTheme)
          .frame(height: 18)

        ViewThatFits(in: .horizontal) {
          HStack(spacing: AppSpacing.xs) {
            selectedThemeChips(isLocked: isLocked)
          }

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
              ThemeInfoChip(
                title: previewTheme.category.title, iconName: iconName(for: previewTheme.category))
              ThemePlanBadge(plan: previewTheme.requiredPlan, isLocked: isLocked)
            }
            if isLocked {
              ThemeAccessBadge(title: "Upgrade required")
            }
          }
        }
      }

      HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
        NavigationLink {
          ThemePreviewDetailView(
            theme: previewTheme,
            isLocked: !subscriptionManager.canUseTheme(previewTheme),
            applyAction: applySelectedTheme,
            upgradeAction: {
                AppAnalytics.shared.track(.featureLocked, ["source": "ThemeSelectionView"])
                showPaywall = true
            }
          )
        } label: {
          Label("Preview", systemImage: "rectangle.stack.fill")
            .font((isCompactDevice ? Font.caption : Font.subheadline).weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
            .foregroundStyle(AppColors.appTint)
            .background(
              AppColors.appTint.opacity(0.1),
              in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(InteractiveScaleButtonStyle())

        Button(action: applySelectedTheme) {
          Label(
            isLocked ? "Upgrade" : "Apply",
            systemImage: isLocked ? "lock.fill" : "checkmark.circle.fill"
          )
          .font((isCompactDevice ? Font.caption : Font.subheadline).weight(.heavy))
          .lineLimit(1)
          .minimumScaleFactor(0.86)
          .frame(maxWidth: .infinity)
          .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
          .foregroundStyle(.white)
          .background(
            isLocked ? AppColors.amber : AppColors.appTint,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(InteractiveScaleButtonStyle())
      }
    }
    .padding(isCompactDevice ? AppSpacing.sm : AppSpacing.md)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
  }

  @ViewBuilder
  private func selectedThemeChips(isLocked: Bool) -> some View {
    ThemeInfoChip(
      title: previewTheme.category.title, iconName: iconName(for: previewTheme.category))
    ThemePlanBadge(plan: previewTheme.requiredPlan, isLocked: isLocked)
    if isLocked {
      ThemeAccessBadge(title: "Upgrade required")
    }
  }

  private var categoryPicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: isCompactDevice ? AppSpacing.xxs : AppSpacing.xs) {
        ForEach(ChatThemeCategory.allCases) { category in
          Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
              selectCategory(category)
            }
          } label: {
            HStack(spacing: AppSpacing.xs) {
              Image(systemName: iconName(for: category))
            .font((isCompactDevice ? Font.caption2 : Font.caption).weight(.heavy))
              Text(category.title)
                .font(.caption.weight(.heavy))
            }
            .foregroundStyle(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
              selectedCategory == category
                ? AnyShapeStyle(AppColors.brandGradient)
                : AnyShapeStyle(.thinMaterial),
              in: Capsule()
            )
            .overlay(
              Capsule()
                .stroke(
                  selectedCategory == category ? Color.white.opacity(0.24) : AppColors.hairline,
                  lineWidth: 1)
            )
          }
          .buttonStyle(InteractiveScaleButtonStyle())
        }
      }
    }
  }

  private func themeGrid(width: CGFloat) -> some View {
    let columns = Array(
      repeating: GridItem(.flexible(), spacing: AppSpacing.sm),
      count: DeviceSize.category(for: width) == .iPad ? 2 : 1
    )

    return VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
      HStack {
        Text(selectedCategory.title)
          .font((isCompactDevice ? Font.subheadline : Font.headline).weight(.heavy))
        Text("\(filteredThemes.count)")
          .font(.caption.weight(.heavy))
          .foregroundStyle(AppColors.appTint)
          .padding(.horizontal, AppSpacing.xs)
          .padding(.vertical, 4)
          .background(AppColors.appTint.opacity(0.1), in: Capsule())
        Spacer()
      }

      AdSupportedGrid(items: filteredThemes, columns: columns.count, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) { theme in
          Button {
            select(theme)
          } label: {
            ThemeCardView(
              theme: styledTheme(theme),
              isSelected: previewThemeID == theme.id,
              isLocked: !subscriptionManager.canUseTheme(theme)
            )
          }
          .buttonStyle(.plain)
      }
    }
  }

  private var customBuilder: some View {
    VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Custom Builder")
            .font(.headline.weight(.heavy))
          Text("Fine tune colors, corners, avatars, and effects.")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        Spacer()
        if !subscriptionManager.canUse(feature: .customThemes) {
          LockBadgeView(label: "Pro")
        }
      }

      if subscriptionManager.canUse(feature: .customThemes) {
        VStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
          HStack {
            ColorPicker("Background", selection: styleColorBinding(\.backgroundHex))
            ColorPicker("Accent", selection: styleColorBinding(\.accentHex))
          }
          HStack {
            ColorPicker("Outgoing", selection: styleColorBinding(\.outgoingBubbleHex))
            ColorPicker("Incoming", selection: styleColorBinding(\.incomingBubbleHex))
          }
          HStack {
            ColorPicker("Outgoing Text", selection: styleColorBinding(\.outgoingTextHex))
            ColorPicker("Incoming Text", selection: styleColorBinding(\.incomingTextHex))
          }

          Stepper(
            "Bubble radius: \(Int(customStyle.bubbleCornerRadius))",
            value: $customStyle.bubbleCornerRadius, in: 8...34, step: 1)
          Stepper(
            "Font adjustment: \(customStyle.fontSizeAdjustment, specifier: "%.1f")",
            value: $customStyle.fontSizeAdjustment, in: -2...3, step: 0.5)
          Toggle("Show avatars", isOn: $customStyle.showAvatars)
          Toggle("Message tails", isOn: $customStyle.hasMessageTail)
          Toggle("Gradient outgoing bubbles", isOn: $customStyle.usesGradientOutgoing)
          Toggle("Glow effect", isOn: $customStyle.glowOutgoing)
        }
        .font(.subheadline.weight(.semibold))
      } else {
        Button {
          AppAnalytics.shared.track(.featureLocked, ["source": "ThemeSelectionView"])
          showPaywall = true
        } label: {
          Label(
            "Upgrade to unlock custom colors and advanced theme controls.", systemImage: "lock.fill"
          )
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppColors.appTint)
        }
      }
    }
    .padding(isCompactDevice ? AppSpacing.sm : AppSpacing.md)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
  }

  private func select(_ theme: ChatTheme) {
    AppAnalytics.shared.track(.themeSelect, ["theme_id": theme.id])
    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
      previewThemeID = theme.id
      if theme.isCustom {
        customStyle = storyBinding?.wrappedValue.customThemeStyle ?? theme.style
      }
    }
    if !subscriptionManager.canUseTheme(theme) {
      AppAnalytics.shared.track(.featureLocked, ["source": "ThemeSelectionView"])
      showPaywall = true
      return
    }

    commitSelectedTheme()
  }

  private var shouldShowCustomBuilder: Bool {
    selectedCategory == .custom && previewTheme.isCustom
  }

  private func selectCategory(_ category: ChatThemeCategory) {
    AppAnalytics.shared.track(.themeCategory, ["category": category.rawValue])
    selectedCategory = category
  }

  private func styledTheme(_ theme: ChatTheme) -> ChatTheme {
    var styled = theme
    if styled.isCustom {
      styled.style = customStyle
    }
    return styled
  }

  private func applySelectedTheme() {
    guard subscriptionManager.canUseTheme(previewTheme) else {
      AppAnalytics.shared.track(.featureLocked, ["source": "ThemeSelectionView"])
      showPaywall = true
      return
    }

    commitSelectedTheme()
    dismiss()
  }

  private func commitSelectedTheme() {
    AppAnalytics.shared.track(.themeApply, ["theme_id": previewThemeID])
    let normalizedThemeID = ChatTheme.normalizedID(for: previewThemeID)
    selectedThemeID = normalizedThemeID
    storyBinding?.wrappedValue.themeID = normalizedThemeID
    storyBinding?.wrappedValue.updatedAt = Date()
    if previewTheme.isCustom {
      storyBinding?.wrappedValue.customThemeStyle = customStyle
    } else {
      storyBinding?.wrappedValue.customThemeStyle = nil
    }
  }

  private func styleColorBinding(_ keyPath: WritableKeyPath<ChatThemeStyle, String>) -> Binding<
    Color
  > {
    Binding(
      get: { Color(hex: customStyle[keyPath: keyPath]) },
      set: { customStyle[keyPath: keyPath] = $0.toHex() }
    )
  }

  private func iconName(for category: ChatThemeCategory) -> String {
    switch category {
    case .basic: return "circle.grid.2x2.fill"
    case .social: return "bubble.left.and.bubble.right.fill"
    case .premium: return "sparkles"
    case .dark: return "moon.stars.fill"
    case .custom: return "slider.horizontal.3"
    }
  }
}

private struct ThemeInfoChip: View {
  let title: String
  let iconName: String

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: iconName)
        .font(.caption2.weight(.heavy))
      Text(title)
        .font(.caption.weight(.heavy))
    }
    .foregroundStyle(.secondary)
    .padding(.horizontal, AppSpacing.xs)
    .padding(.vertical, 5)
    .background(.thinMaterial, in: Capsule())
  }
}

private struct ThemePlanBadge: View {
  let plan: UserPlan
  let isLocked: Bool

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: isLocked ? "lock.fill" : planIcon)
        .font(.caption2.weight(.heavy))
      Text(plan.title)
        .font(.caption.weight(.heavy))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
    .foregroundStyle(isLocked ? AppColors.amber : .secondary)
    .padding(.horizontal, AppSpacing.xs)
    .padding(.vertical, 5)
    .background(
      (isLocked ? AppColors.amber.opacity(0.12) : Color.primary.opacity(0.05)),
      in: Capsule()
    )
    .overlay(
      Capsule()
        .stroke(isLocked ? AppColors.amber.opacity(0.28) : AppColors.hairline, lineWidth: 1)
    )
  }

  private var planIcon: String {
    switch plan {
    case .free:
      return "checkmark.circle.fill"
    case .lite:
      return "crown.fill"
    case .pro:
      return "sparkles"
    }
  }
}

private struct ThemeAccessBadge: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.caption.weight(.heavy))
      .lineLimit(1)
      .minimumScaleFactor(0.82)
      .foregroundStyle(AppColors.amber)
      .padding(.horizontal, AppSpacing.xs)
      .padding(.vertical, 5)
      .background(AppColors.amber.opacity(0.12), in: Capsule())
      .overlay(Capsule().stroke(AppColors.amber.opacity(0.28), lineWidth: 1))
  }
}

private struct ThemePreviewDetailView: View {
  let theme: ChatTheme
  let isLocked: Bool
  let applyAction: () -> Void
  let upgradeAction: () -> Void

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(theme.name)
              .font(AppFont.title(width: geometry.size.width))
              .fixedSize(horizontal: false, vertical: true)
            Text("Full-screen theme preview")
              .font(AppFont.caption(width: geometry.size.width))
              .foregroundStyle(.secondary)
          }

          ThemePreviewView(theme: theme)
            .frame(height: DeviceSize.category(for: geometry.size.width) == .compact ? 430 : 500)
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(AppColors.hairline, lineWidth: 1)
            )

          themeDetails

          Button(action: isLocked ? upgradeAction : applyAction) {
            Label(
              isLocked ? "Upgrade to Use Theme" : "Apply Theme",
              systemImage: isLocked ? "lock.fill" : "checkmark.circle.fill"
            )
            .font(.headline.weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .foregroundStyle(.white)
            .background(
              isLocked ? AppColors.amber : AppColors.appTint,
              in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
          }
          .buttonStyle(InteractiveScaleButtonStyle())
        }
        .padding(.horizontal, DeviceSize.horizontalPadding(for: geometry.size.width))
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: DeviceSize.contentMaxWidth(for: geometry.size.width))
        .frame(maxWidth: .infinity)
      }
      .background(PremiumBackdrop())
    }
    .trackScreen(.themePreview)
    .navigationTitle("Preview")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var themeDetails: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      HStack {
        ThemeIdentityBadge(theme: theme)
          .frame(width: 54, height: 54)
        VStack(alignment: .leading, spacing: 4) {
          Text("Theme Details")
            .font(.headline.weight(.heavy))
          Text(theme.subtitle)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      HStack(spacing: AppSpacing.xs) {
        ThemeSwatchStrip(theme: theme)
        Text("Bubbles, wallpaper, header, input bar, and receipts are controlled by this theme.")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(AppSpacing.md)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
  }
}
