import SwiftUI

struct PreviewModeView: View {
  @Binding var story: ChatStory
  @EnvironmentObject private var subscriptionManager: SubscriptionManager

  @State private var visibleCount = 0
  @State private var autoPlay = false
  @State private var playbackSpeed = 1.0
  @State private var typingCharacterID: UUID?
  @State private var showFullScreen = false
  @State private var showPaywall = false
  @State private var autoplayTask: Task<Void, Never>?

  private var isCompactDevice: Bool {
    DeviceSize.isCurrentCompactHeight
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
        previewStage(width: geometry.size.width, height: geometry.size.height)
        playbackPanel
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.bottom, DeviceSize.category(for: geometry.size.width) == .iPad ? 0 : isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
      .background(PremiumBackdrop())
    }
    .fullScreenCover(isPresented: $showFullScreen) {
      FullScreenPreview(
        story: story,
        visibleCount: $visibleCount,
        typingCharacterID: $typingCharacterID,
        revealNext: {
          Task { await revealNext() }
        }
      )
      .trackScreen(.fullscreenPreview)
    }
    .fullScreenCover(isPresented: $showPaywall) {
      NavigationStack { PaywallView() }
    }
    .onChange(of: autoPlay) { isEnabled in
      if isEnabled {
        startAutoplay()
      } else {
        autoplayTask?.cancel()
        autoplayTask = nil
      }
    }
    .trackScreen(.preview)
    .onDisappear {
      autoplayTask?.cancel()
    }
  }

  private func previewStage(width: CGFloat, height: CGFloat) -> some View {
    let isPad = DeviceSize.category(for: width) == .iPad
    let stageHeight =
      isPad
      ? max(590, height - 285)
      : max(isCompactDevice ? 270 : 330, min(height * (isCompactDevice ? 0.52 : 0.6), height - (isCompactDevice ? 230 : 235)))

    return VStack(spacing: AppSpacing.xs) {
      previewStatusBar

      ZStack {
        PreviewConversationCanvas(
          story: story,
          visibleCount: visibleCount,
          typingCharacterID: typingCharacterID,
          width: width,
          showControlsHint: false
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
            .stroke(AppColors.hairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, y: 10)

        VStack {
          Spacer()
          PreviewTapCue(
            title: cueTitle,
            subtitle: cueSubtitle,
            iconName: cueIconName,
            isComplete: visibleCount >= story.messages.count && !story.messages.isEmpty
          )
          .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
          .padding(.bottom, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
        }
      }
      .frame(height: stageHeight)
      .contentShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
      .onTapGesture {
        Task { await revealNext() }
      }
    }
    .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
    .padding(.top, isCompactDevice ? 0 : AppSpacing.xs)
  }

  private var previewStatusBar: some View {
    HStack(spacing: AppSpacing.sm) {
      Label("\(visibleCount) of \(story.messages.count)", systemImage: "rectangle.stack.fill")
        .font(.caption.weight(.heavy))
        .foregroundStyle(AppColors.appTint)
        .lineLimit(1)

      Spacer(minLength: AppSpacing.sm)

      Text(autoPlay ? "Auto playing" : "Manual preview")
        .font(.caption.weight(.heavy))
        .foregroundStyle(.primary.opacity(0.78))
        .lineLimit(1)
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, AppSpacing.xs)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
  }

  private var playbackPanel: some View {
    VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
      progressSegments

      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Playback")
            .font(.headline.weight(.heavy))
          Text("\(Int(progress * 100))% revealed")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text("\(playbackSpeed, specifier: "%.2g")x")
          .font(.caption.weight(.heavy))
          .foregroundStyle(AppColors.appTint)
          .padding(.horizontal, AppSpacing.sm)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.appTint.opacity(0.1), in: Capsule())
      }

      HStack(spacing: isCompactDevice ? AppSpacing.xs : AppSpacing.sm) {
        PreviewControlButton(title: "Reset", iconName: "arrow.counterclockwise") {
          reset()
        }
        PreviewControlButton(
          title: autoPlay ? "Pause" : "Auto Play",
          iconName: autoPlay ? "pause.fill" : "play.fill",
          isActive: autoPlay
        ) {
          toggleAutoplay()
        }
        PreviewControlButton(title: "Full", iconName: "arrow.up.left.and.arrow.down.right") {
          AppAnalytics.shared.track(.previewFullscreen)
          showFullScreen = true
        }
      }

      HStack(spacing: AppSpacing.xs) {
        Text("Speed")
          .font(.caption.weight(.heavy))
          .foregroundStyle(.secondary)
        ForEach(speedPresets, id: \.value) { preset in
          Button {
            selectSpeed(preset.value)
          } label: {
            Text(preset.title)
              .font(.caption.weight(.heavy))
              .frame(maxWidth: .infinity)
              .padding(.vertical, AppSpacing.xs)
              .foregroundStyle(playbackSpeed == preset.value ? .white : .primary)
              .background(
                playbackSpeed == preset.value
                  ? AnyShapeStyle(AppColors.appTint)
                  : AnyShapeStyle(AppColors.panelBackground.opacity(0.7)),
                in: Capsule()
              )
          }
          .buttonStyle(InteractiveScaleButtonStyle())
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
    .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
  }

  private var progressSegments: some View {
    HStack(spacing: 5) {
      ForEach(0..<progressSegmentCount, id: \.self) { index in
        Capsule()
          .fill(
            segmentIsFilled(index) ? AppColors.appTint : AppColors.panelBackground.opacity(0.72)
          )
          .frame(height: 6)
      }
    }
  }

  private var speedPresets: [(title: String, value: Double)] {
    [
      ("Calm", 0.75),
      ("Normal", 1.0),
      ("Fast", 1.5),
    ]
  }

  private var progress: Double {
    guard !story.messages.isEmpty else { return 0 }
    return Double(visibleCount) / Double(story.messages.count)
  }

  private var progressSegmentCount: Int {
    min(max(story.messages.count, 1), 12)
  }

  private var cueTitle: String {
    if story.messages.isEmpty { return "Add messages first" }
    if visibleCount >= story.messages.count { return "Preview complete" }
    if visibleCount == 0 { return "Tap to reveal the first message" }
    return "Tap for the next message"
  }

  private var cueSubtitle: String {
    if story.messages.isEmpty { return "Open Write and create the conversation." }
    if visibleCount >= story.messages.count { return "Reset or open full screen to replay it." }
    return "The story reveals one message at a time."
  }

  private var cueIconName: String {
    if story.messages.isEmpty { return "text.bubble" }
    if visibleCount >= story.messages.count { return "checkmark.circle.fill" }
    return "hand.tap.fill"
  }

  private func segmentIsFilled(_ index: Int) -> Bool {
    guard progressSegmentCount > 0 else { return false }
    let segmentProgress = Double(index + 1) / Double(progressSegmentCount)
    return progress >= segmentProgress || (visibleCount > 0 && index == 0)
  }

  private func revealNext() async {
    guard visibleCount < story.messages.count else { return }
    if !autoPlay { AppAnalytics.shared.track(.previewReveal, ["source": "manual"]) }
    let nextMessage = story.messages[visibleCount]
    let shouldType = ![MessageType.timestamp, .system, .typingIndicator, .reaction, .sticker]
      .contains(nextMessage.type)

    if shouldType, nextMessage.typingDelay > 0 {
      typingCharacterID = nextMessage.characterID
      let delay = max(0.15, nextMessage.typingDelay / playbackSpeed)
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      typingCharacterID = nil
    }

    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
      visibleCount += 1
      if visibleCount == story.messages.count {
        AppAnalytics.shared.track(.previewComplete, ["message_count": story.messages.count, "source": autoPlay ? "autoplay" : "manual"])
      }
    }
  }

  private func reset() {
    AppAnalytics.shared.track(.previewReset)
    autoplayTask?.cancel()
    autoplayTask = nil
    autoPlay = false
    typingCharacterID = nil
    withAnimation(.easeInOut(duration: 0.25)) {
      visibleCount = 0
    }
  }

  private func toggleAutoplay() {
    if autoPlay {
      AppAnalytics.shared.track(.previewAutoplay, ["value": "stop"])
      autoPlay = false
    } else if subscriptionManager.canUse(feature: .autoplay) {
      AppAnalytics.shared.track(.previewAutoplay, ["value": "start"])
      autoPlay = true
    } else {
      AppAnalytics.shared.track(.featureLocked, ["source": "PreviewModeView"])
      showPaywall = true
    }
  }

  private func selectSpeed(_ speed: Double) {
    guard speed == 1.0 || subscriptionManager.canUse(feature: .adjustablePlaybackSpeed) else {
      AppAnalytics.shared.track(.featureLocked, ["source": "PreviewModeView"])
      showPaywall = true
      return
    }
    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
      AppAnalytics.shared.track(.previewSpeed, ["speed": speed])
      playbackSpeed = speed
    }
  }

  private func startAutoplay() {
    autoplayTask?.cancel()
    autoplayTask = Task {
      while !Task.isCancelled && visibleCount < story.messages.count {
        await revealNext()
        let wait = max(0.25, 1.0 / playbackSpeed)
        try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
      }
      await MainActor.run {
        autoPlay = false
      }
    }
  }
}

private struct PreviewTapCue: View {
  let title: String
  let subtitle: String
  let iconName: String
  let isComplete: Bool

  var body: some View {
    HStack(spacing: AppSpacing.sm) {
      Image(systemName: iconName)
        .font(.headline.weight(.heavy))
        .frame(width: 40, height: 40)
        .foregroundStyle(isComplete ? AppColors.success : AppColors.appTint)
        .background(.white.opacity(0.92), in: Circle())

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(.white)
          .fixedSize(horizontal: false, vertical: true)
        Text(subtitle)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white.opacity(0.76))
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .padding(AppSpacing.sm)
    .background(
      Color.black.opacity(0.42),
      in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        .stroke(.white.opacity(0.14), lineWidth: 1)
    )
  }
}

private struct PreviewControlButton: View {
  let title: String
  let iconName: String
  var isActive = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: iconName)
          .font(.headline.weight(.heavy))
        Text(title)
          .font(.caption.weight(.heavy))
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity, minHeight: 62)
      .foregroundStyle(isActive ? .white : AppColors.appTint)
      .background(background, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
          .stroke(
            isActive ? Color.white.opacity(0.2) : AppColors.appTint.opacity(0.16), lineWidth: 1)
      )
    }
    .buttonStyle(InteractiveScaleButtonStyle())
  }

  private var background: some ShapeStyle {
    isActive ? AnyShapeStyle(AppColors.appTint) : AnyShapeStyle(AppColors.appTint.opacity(0.08))
  }
}

struct PreviewConversationCanvas: View {
  let story: ChatStory
  let visibleCount: Int
  let typingCharacterID: UUID?
  let width: CGFloat
  var showControlsHint: Bool = false
  var includeWatermark: Bool = false
  var watermarkText: String?
  var includeInputBar: Bool = false
  var onBackTap: (() -> Void)? = nil

  private var theme: ChatTheme { story.theme }
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(spacing: 0) {
      ChatHeaderView(
        story: story,
        theme: theme,
        showsControls: !includeWatermark,
        onBackTap: onBackTap
      )
      GeometryReader { messageGeometry in
        ScrollView {
          LazyVStack(spacing: theme.compactMessageSpacing) {
            let visibleMessages = Array(story.messages.prefix(visibleCount))
            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
              if let character = character(for: message) {
                let group = messageGroup(at: index, in: visibleMessages)
                ChatBubbleView(
                  message: message,
                  character: character,
                  theme: theme,
                  maxWidth: DeviceSize.chatBubbleMaxWidth(for: width),
                  showMeta: true,
                  isFirstInGroup: group.isFirst,
                  isLastInGroup: group.isLast
                )
              }
            }

            if let typingCharacterID,
              let character = story.characters.first(where: { $0.id == typingCharacterID })
            {
              ChatBubbleView(
                message: ChatMessage(
                  characterID: character.id, type: .typingIndicator, text: "typing..."),
                character: character,
                theme: theme,
                maxWidth: DeviceSize.chatBubbleMaxWidth(for: width),
                showMeta: false
              )
            }

            if story.messages.isEmpty {
              EmptyStateView(
                title: "Nothing to preview", message: "Add messages in the editor first.",
                systemImage: "play.rectangle"
              )
              .frame(maxWidth: .infinity)
              .frame(minHeight: messageGeometry.size.height, alignment: .center)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, story.messages.isEmpty ? 0 : AppSpacing.md)
        }
      }
      .background(canvasBackground)

      if showControlsHint {
        Text(
          visibleCount < story.messages.count
            ? "Tap preview to reveal next message" : "All messages revealed"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial)
      }

      if includeWatermark, let watermarkText {
        Text(watermarkText)
          .font(.caption.weight(.bold))
          .foregroundStyle(.white)
          .padding(.horizontal, AppSpacing.sm)
          .padding(.vertical, AppSpacing.xs)
          .background(Color.black.opacity(0.36), in: Capsule())
          .padding(.bottom, AppSpacing.sm)
      }

      if includeInputBar {
        ChatInputBarPreview(
          theme: theme,
          roundedCorners: [.bottomLeft, .bottomRight],
          cornerRadius: 0,
          isDockedInChatFrame: true
        )
      }
    }
    .background(canvasBackground)
  }

  private var canvasBackground: some View {
    ThemeWallpaperView(
      theme: theme,
      intensity: theme.id == "midnight-doodle" ? 0.92 : (theme.isPaperPlaneStyleTheme ? 0.88 : 0.48)
    )
  }

  private func character(for message: ChatMessage) -> ChatCharacter? {
    story.characters.first { $0.id == message.characterID } ?? story.characters.first
  }

  private func messageGroup(at index: Int, in messages: [ChatMessage]) -> (isFirst: Bool, isLast: Bool) {
    let message = messages[index]
    let previousMatches =
      index > 0 && messages[index - 1].isGroupedWith(message)
    let nextMatches =
      index < messages.count - 1 && messages[index + 1].isGroupedWith(message)
    return (!previousMatches, !nextMatches)
  }
}

private struct FullScreenPreview: View {
  let story: ChatStory
  @Binding var visibleCount: Int
  @Binding var typingCharacterID: UUID?
  let revealNext: () -> Void

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  private var theme: ChatTheme { story.theme }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        PreviewConversationCanvas(
          story: story,
          visibleCount: visibleCount,
          typingCharacterID: typingCharacterID,
          width: geometry.size.width,
          showControlsHint: false,
          includeInputBar: true,
          onBackTap: { dismiss() }
        )
        .ignoresSafeArea(.container, edges: [.horizontal])
        .onTapGesture(perform: revealNext)
      }
      .background(headerChromeColor.ignoresSafeArea(edges: .top))
      .background(bottomSafeAreaColor.ignoresSafeArea(edges: .bottom))
    }
  }

  private var headerChromeColor: Color {
    if theme.isWhatsAppStyleTheme {
      if theme.id == "green-bubble" && colorScheme == .light {
        return Color(hex: theme.style.headerHex)
      }
      return Color(hex: "#111111")
    }
    if theme.isSocialMetaStyleTheme {
      return colorScheme == .dark ? Color(hex: theme.style.darkHeaderHex) : .white
    }
    if theme.isGradientDMStyleTheme {
      return colorScheme == .dark ? Color(hex: "#070A10") : .white
    }
    if theme.isPaperPlaneStyleTheme {
      return colorScheme == .dark
        ? Color(hex: "#05060B").opacity(0.96)
        : Color(hex: theme.style.headerHex).opacity(0.86)
    }
    if theme.isSnapStyleTheme {
      return colorScheme == .dark ? Color(hex: "#070A10") : .white
    }
    return Color(hex: colorScheme == .dark ? theme.style.darkHeaderHex : theme.style.headerHex)
  }

  private var bottomSafeAreaColor: Color {
    if theme.isWhatsAppStyleTheme {
      if theme.id == "green-bubble" && colorScheme == .light {
        return Color(hex: theme.style.headerHex)
      }
      return Color(hex: "#0B0B0B")
    }
    if theme.isSocialMetaStyleTheme {
      return colorScheme == .dark ? Color(hex: theme.style.darkHeaderHex) : .white
    }
    if theme.isGradientDMStyleTheme {
      return colorScheme == .dark ? Color(hex: "#070A10") : .white
    }
    if theme.isPaperPlaneStyleTheme {
      return colorScheme == .dark ? Color(hex: "#05060B").opacity(0.98) : Color(hex: theme.style.backgroundHex)
    }
    if theme.isSnapStyleTheme {
      return colorScheme == .dark ? Color(hex: "#070A10") : .white
    }
    return Color(hex: colorScheme == .dark ? theme.style.darkInputBarHex : theme.style.inputBarHex)
  }
}
