import SwiftUI
import UIKit

struct ChatBubbleView: View {
  let message: ChatMessage
  let character: ChatCharacter
  let theme: ChatTheme
  let maxWidth: CGFloat
  var showMeta: Bool = true
  var isFirstInGroup: Bool = true
  var isLastInGroup: Bool = true

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    if message.type == .timestamp || message.type == .system {
      centeredMessage
    } else if theme.isSnapStyleTheme {
      snapMessageRow
    } else {
      HStack(alignment: .bottom, spacing: AppSpacing.xs) {
        if isOutgoing { Spacer(minLength: maxWidth * 0.12) }

        if !isOutgoing && theme.style.showAvatars {
          if theme.isSocialMetaStyleTheme || theme.isGradientDMStyleTheme {
            socialBlueAvatarSlot
          } else {
            miniAvatar
          }
        }

        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: AppSpacing.xxs) {
          bubbleContent
          if showMeta && !theme.isSocialMetaStyleTheme && !theme.isGradientDMStyleTheme
            && (!theme.usesInlineMessageMeta || !showsInlineMeta)
          {
            metaRow
          }
        }
        .frame(maxWidth: maxWidth, alignment: isOutgoing ? .trailing : .leading)

        if !isOutgoing { Spacer(minLength: maxWidth * 0.12) }
      }
      .padding(.horizontal, AppSpacing.sm)
      .padding(.top, compactMessengerTopPadding)
      .transition(
        .asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
    }
  }

  @ViewBuilder
  private var bubbleContent: some View {
    if theme.isSocialMetaStyleTheme {
      socialBlueBubbleContent
    } else if theme.isGradientDMStyleTheme {
      gradientDMBubbleContent
    } else if theme.isPaperPlaneStyleTheme {
      paperPlaneBubbleContent
    } else if theme.usesCompactMessengerLayout {
      compactMessengerBubbleContent
    } else {
      standardBubbleContent
    }
  }

  private var standardBubbleContent: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      switch message.type {
      case .text:
        Text(message.text)
          .font(
            .system(size: 16 + theme.style.fontSizeAdjustment, weight: .regular, design: .rounded)
          )
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
      case .image:
        imageMessage
      case .video:
        videoMessage
      case .voice:
        voiceBubble
      case .typingIndicator:
        TypingDotsView(color: textColor)
          .padding(.vertical, 3)
      case .reaction:
        Text(message.text.isEmpty ? message.reaction : message.text)
          .font(.system(size: 30))
      case .missedCall:
        HStack(spacing: AppSpacing.xs) {
          Image(systemName: "phone.down.fill")
          Text(message.text.isEmpty ? "Missed call" : message.text)
        }
        .font(.callout.weight(.semibold))
        .foregroundStyle(textColor)
      case .sticker:
        Text(message.text.isEmpty ? "✨" : message.text)
          .font(.system(size: 42))
      case .timestamp, .system:
        EmptyView()
      }

      if showMeta && theme.usesInlineMessageMeta && showsInlineMeta {
        inlineMetaRow
      }
    }
    .padding(.horizontal, bubbleHorizontalPadding)
    .padding(.vertical, bubbleVerticalPadding)
    .background(
      bubbleStyle,
      in: RoundedRectangle(
        cornerRadius: CGFloat(theme.style.bubbleCornerRadius), style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: CGFloat(theme.style.bubbleCornerRadius), style: .continuous)
        .stroke(Color(hex: theme.style.accentHex).opacity(theme.bubbleBorderOpacity), lineWidth: 1)
    )
    .overlay(alignment: isOutgoing ? .bottomTrailing : .bottomLeading) {
      if theme.style.hasMessageTail {
        BubbleTail(isOutgoing: isOutgoing)
          .fill(bubbleColor)
          .frame(width: 12, height: 14)
          .offset(x: isOutgoing ? 5 : -5, y: 1)
      }
    }
    .shadow(
      color: theme.style.glowOutgoing && isOutgoing
        ? Color(hex: theme.style.accentHex).opacity(0.42) : .clear, radius: 12)
  }

  @ViewBuilder
  private var compactMessengerBubbleContent: some View {
    switch message.type {
    case .image:
      compactMessengerMediaBubble(isVideo: false)
    case .video:
      compactMessengerMediaBubble(isVideo: true)
    case .sticker:
      Text(message.text.isEmpty ? "✨" : message.text)
        .font(.system(size: 42))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    case .reaction:
      Text(message.text.isEmpty ? message.reaction : message.text)
        .font(.system(size: 30))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    default:
      compactMessengerTextBubble
    }
  }

  @ViewBuilder
  private var socialBlueBubbleContent: some View {
    switch message.type {
    case .image:
      socialBlueMediaBubble(isVideo: false)
    case .video:
      socialBlueMediaBubble(isVideo: true)
    case .sticker:
      Text(message.text.isEmpty ? "✨" : message.text)
        .font(.system(size: 42))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    case .reaction:
      Text(message.text.isEmpty ? message.reaction : message.text)
        .font(.system(size: 42))
        .foregroundStyle(Color(hex: theme.style.accentHex))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    default:
      socialBlueTextBubble
    }
  }

  @ViewBuilder
  private var gradientDMBubbleContent: some View {
    switch message.type {
    case .image:
      gradientDMMediaBubble(isVideo: false)
    case .video:
      gradientDMMediaBubble(isVideo: true)
    case .sticker:
      Text(message.text.isEmpty ? "✨" : message.text)
        .font(.system(size: 44))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    case .reaction:
      Text(message.text.isEmpty ? message.reaction : message.text)
        .font(.system(size: 40))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    default:
      gradientDMTextBubble
    }
  }

  @ViewBuilder
  private var paperPlaneBubbleContent: some View {
    switch message.type {
    case .image:
      paperPlaneMediaBubble(isVideo: false)
    case .video:
      paperPlaneMediaBubble(isVideo: true)
    case .sticker:
      Text(message.text.isEmpty ? "✨" : message.text)
        .font(.system(size: 42))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    case .reaction:
      Text(message.text.isEmpty ? message.reaction : message.text)
        .font(.system(size: 32))
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
    default:
      paperPlaneTextBubble
    }
  }

  private var snapMessageRow: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack(alignment: .leading, spacing: snapContentSpacing) {
        if isFirstInGroup {
          Text(snapSenderLabel)
            .font(.caption.weight(.bold))
            .foregroundStyle(snapRailColor)
            .lineLimit(1)
        }

        snapMessageContent
      }
      .padding(.leading, 11)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, snapRowTopPadding)
    .padding(.bottom, snapRowBottomPadding)
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 1.5, style: .continuous)
        .fill(snapRailColor)
        .frame(width: 3)
        .padding(.top, snapRailTopInset)
    }
    .padding(.horizontal, 14)
    .transition(.opacity.combined(with: .move(edge: .bottom)))
  }

  @ViewBuilder
  private var snapMessageContent: some View {
    switch message.type {
    case .text:
      Text(message.text)
        .font(.system(size: snapBodyFontSize, weight: .regular))
        .foregroundStyle(snapTextColor)
        .fixedSize(horizontal: false, vertical: true)
    case .image:
      snapMediaContent(isVideo: false)
    case .video:
      snapMediaContent(isVideo: true)
    case .voice:
      HStack(spacing: AppSpacing.sm) {
        Image(systemName: "mic.fill")
        Text(message.text.isEmpty ? "Voice note" : message.text)
        Spacer(minLength: AppSpacing.xs)
        Text("0:12")
          .font(.caption.weight(.bold))
      }
      .font(.system(size: snapAuxiliaryFontSize, weight: .semibold))
      .foregroundStyle(snapTextColor)
      .padding(.vertical, 5)
    case .typingIndicator:
      TypingDotsView(color: snapRailColor)
        .padding(.vertical, 5)
    case .reaction:
      Text(message.text.isEmpty ? message.reaction : message.text)
        .font(.system(size: 34))
    case .missedCall:
      HStack(spacing: AppSpacing.xs) {
        Image(systemName: "phone.down.fill")
        Text(message.text.isEmpty ? "Missed call" : message.text)
      }
      .font(.system(size: snapAuxiliaryFontSize, weight: .semibold))
      .foregroundStyle(snapTextColor)
    case .sticker:
      Text(message.text.isEmpty ? "✨" : message.text)
        .font(.system(size: 42))
    case .timestamp, .system:
      EmptyView()
    }
  }

  private func snapMediaContent(isVideo: Bool) -> some View {
    let shareButtonSize: CGFloat = 42
    let shareButtonSpacing: CGFloat = 9
    let mediaSize = snapMediaDisplaySize(
      isVideo: isVideo,
      reservedTrailingWidth: shareButtonSize + shareButtonSpacing
    )

    return VStack(alignment: .leading, spacing: 7) {
      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.system(size: snapBodyFontSize, weight: .regular))
          .foregroundStyle(snapTextColor)
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack(alignment: .center, spacing: shareButtonSpacing) {
        ZStack(alignment: .center) {
          if let data = message.mediaData, let image = UIImage(data: data) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .frame(width: mediaSize.width, height: mediaSize.height)
              .clipped()
              .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
          } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(snapMediaPlaceholderFill)
              .frame(width: mediaSize.width, height: mediaSize.height)
              .overlay {
                VStack(spacing: AppSpacing.xs) {
                  Image(systemName: isVideo ? "play.rectangle.fill" : "photo.fill")
                    .font(.title.weight(.semibold))
                  Text(isVideo ? "Video snap" : "Image snap")
                    .font(.caption.weight(.semibold))
                }
                .foregroundStyle(snapMediaPlaceholderTextColor)
              }
          }

          if isVideo {
            Image(systemName: "play.fill")
              .font(.title3.weight(.black))
              .foregroundStyle(.white)
              .frame(width: 48, height: 48)
              .background(Color.black.opacity(0.42), in: Circle())
          }
        }

        snapShareButton
      }
    }
  }

  private var snapShareButton: some View {
    Image(systemName: "arrowshape.turn.up.right.fill")
      .font(.system(size: 18, weight: .bold))
      .foregroundStyle(snapShareIconColor)
      .frame(width: 42, height: 42)
      .background(snapShareButtonFill, in: Circle())
      .accessibilityHidden(true)
  }

  private var snapBodyFontSize: CGFloat {
    18 + theme.style.fontSizeAdjustment
  }

  private var snapAuxiliaryFontSize: CGFloat {
    15 + theme.style.fontSizeAdjustment
  }

  private var snapMediaWidth: CGFloat {
    guard maxWidth >= 180 else {
      return maxWidth * 0.94
    }

    let widthCap: CGFloat = maxWidth > 420 ? 320 : 258
    return max(184, min(maxWidth * 0.78, widthCap))
  }

  private func snapMediaDisplaySize(isVideo: Bool, reservedTrailingWidth: CGFloat = 0) -> CGSize {
    let availableWidth = maxWidth - reservedTrailingWidth - 12
    let mediaWidth = min(snapMediaWidth, max(120, availableWidth))
    let defaultRatio: CGFloat = isVideo ? 1.12 : 0.78
    let rawRatio: CGFloat
    if let data = message.mediaData, let image = UIImage(data: data) {
      rawRatio = image.size.height / max(image.size.width, 1)
    } else {
      rawRatio = defaultRatio
    }
    let minRatio: CGFloat = isVideo ? 0.76 : 0.58
    let maxRatio: CGFloat = isVideo ? 1.36 : 1.42
    let ratio = min(max(rawRatio, minRatio), maxRatio)
    return CGSize(width: mediaWidth, height: mediaWidth * ratio)
  }

  private var socialBlueTextBubble: some View {
    VStack(alignment: .leading, spacing: 4) {
      switch message.type {
      case .text:
        Text(message.text)
          .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .medium))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
      case .voice:
        voiceBubble
      case .typingIndicator:
        TypingDotsView(color: textColor.opacity(0.72))
          .padding(.vertical, 4)
      case .missedCall:
        HStack(spacing: AppSpacing.xs) {
          Image(systemName: "phone.down.fill")
          Text(message.text.isEmpty ? "Missed call" : message.text)
        }
        .font(.callout.weight(.semibold))
        .foregroundStyle(textColor)
      default:
        Text(message.text)
          .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(socialBlueBubbleColor, in: socialBlueBubbleShape)
  }

  private func socialBlueMediaBubble(isVideo: Bool) -> some View {
    let mediaWidth = min(maxWidth, 292)
    return VStack(alignment: isOutgoing ? .trailing : .leading, spacing: message.text.isEmpty ? 0 : 5) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        ZStack {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: mediaWidth, height: mediaWidth * 1.08)
            .clipped()

          if isVideo {
            Image(systemName: "play.fill")
              .font(.title2.weight(.heavy))
              .foregroundStyle(.white)
              .frame(width: 54, height: 54)
              .background(Color.black.opacity(0.42), in: Circle())
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      } else {
        socialBlueMediaPlaceholder(isVideo: isVideo)
          .frame(width: mediaWidth, height: mediaWidth * 0.74)
      }

      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.callout.weight(.regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(socialBlueBubbleColor, in: socialBlueBubbleShape)
      }
    }
  }

  private func socialBlueMediaPlaceholder(isVideo: Bool) -> some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
      .fill(isOutgoing ? Color(hex: theme.style.accentHex).opacity(0.14) : Color(hex: "#F0F2F5"))
      .overlay {
        VStack(spacing: AppSpacing.xs) {
          Image(systemName: isVideo ? "play.rectangle.fill" : "photo.fill")
            .font(.title.weight(.semibold))
          Text(message.text.isEmpty ? (isVideo ? "Video" : "Photo") : message.text)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color(hex: theme.style.accentHex))
        .padding(AppSpacing.sm)
      }
  }

  private var gradientDMTextBubble: some View {
    VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
      VStack(alignment: .leading, spacing: 4) {
        switch message.type {
        case .text:
          Text(message.text)
            .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
            .foregroundStyle(textColor)
            .fixedSize(horizontal: false, vertical: true)
        case .voice:
          voiceBubble
        case .typingIndicator:
          TypingDotsView(color: textColor.opacity(0.78))
            .padding(.vertical, 4)
        case .missedCall:
          HStack(spacing: AppSpacing.xs) {
            Image(systemName: "phone.down.fill")
            Text(message.text.isEmpty ? "Missed call" : message.text)
          }
          .font(.callout.weight(.semibold))
          .foregroundStyle(textColor)
        default:
          Text(message.text)
            .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
            .foregroundStyle(textColor)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(gradientDMBubbleFill, in: gradientDMBubbleShape)

      gradientDMSeenRow
    }
  }

  private func gradientDMMediaBubble(isVideo: Bool) -> some View {
    let mediaWidth = min(maxWidth, 254)
    let mediaHeight = isVideo ? mediaWidth * 1.42 : mediaWidth * 1.08

    return VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 5) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: mediaWidth, height: mediaHeight)
            .clipped()

          if isVideo {
            Image(systemName: "play.fill")
              .font(.title2.weight(.heavy))
              .foregroundStyle(.white)
              .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
              .padding(12)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      } else {
        gradientDMMediaPlaceholder(isVideo: isVideo)
          .frame(width: mediaWidth, height: isVideo ? mediaWidth * 1.18 : mediaWidth * 0.82)
      }

      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.callout.weight(.regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 15)
          .padding(.vertical, 9)
          .background(gradientDMBubbleFill, in: gradientDMBubbleShape)
      }

      gradientDMSeenRow
    }
  }

  private func gradientDMMediaPlaceholder(isVideo: Bool) -> some View {
    RoundedRectangle(cornerRadius: 22, style: .continuous)
      .fill(
        LinearGradient(
          colors: [
            Color(hex: "#20242C"),
            Color(hex: isVideo ? "#2A213A" : "#232936")
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        VStack(spacing: AppSpacing.xs) {
          Image(systemName: isVideo ? "play.fill" : "photo.fill")
            .font(.title.weight(.semibold))
          Text(message.text.isEmpty ? (isVideo ? "Video" : "Photo") : message.text)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.86))
        .padding(AppSpacing.sm)
      }
  }

  private var paperPlaneTextBubble: some View {
    HStack(alignment: .lastTextBaseline, spacing: 6) {
      paperPlaneMessageBody
        .layoutPriority(1)

      if paperPlaneShouldShowMeta {
        paperPlaneMetaRow(onMedia: false)
          .fixedSize(horizontal: true, vertical: true)
      }
    }
    .padding(.leading, paperPlaneShowsIncomingTail ? 14 : 12)
    .padding(.trailing, paperPlaneShowsOutgoingTail ? 14 : 12)
    .padding(.vertical, paperPlaneVerticalPadding)
    .background(paperPlaneBubbleFill, in: paperPlaneTextShape)
    .overlay(
      paperPlaneTextShape
        .stroke(paperPlaneStrokeColor, lineWidth: paperPlaneStrokeWidth)
    )
    .overlay(alignment: isOutgoing ? .bottomTrailing : .bottomLeading) {
      if paperPlaneShowsTextTail {
        PaperPlaneBubbleTail(isOutgoing: isOutgoing)
          .fill(paperPlaneBubbleColor)
          .frame(width: 12, height: 13)
          .offset(x: isOutgoing ? 7 : -7, y: 1)
      }
    }
  }

  @ViewBuilder
  private var paperPlaneMessageBody: some View {
    switch message.type {
    case .text:
      Text(message.text)
        .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
        .foregroundStyle(textColor)
        .fixedSize(horizontal: false, vertical: true)
    case .voice:
      voiceBubble
    case .typingIndicator:
      TypingDotsView(color: textColor.opacity(0.82))
        .padding(.vertical, 4)
    case .missedCall:
      HStack(spacing: AppSpacing.xs) {
        Image(systemName: "phone.down.fill")
        Text(message.text.isEmpty ? "Missed call" : message.text)
      }
      .font(.callout.weight(.semibold))
      .foregroundStyle(textColor)
    default:
      Text(message.text)
        .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
        .foregroundStyle(textColor)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func paperPlaneMediaBubble(isVideo: Bool) -> some View {
    let mediaWidth = min(maxWidth, 312)
    let hasCaption = !message.text.isEmpty && message.mediaData != nil

    return VStack(alignment: .leading, spacing: 0) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        let ratio = image.size.height / max(image.size.width, 1)
        let mediaHeight = mediaWidth * min(max(ratio, isVideo ? 1.08 : 0.72), isVideo ? 1.42 : 1.36)

        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: mediaWidth, height: mediaHeight)
            .clipped()

          LinearGradient(
            colors: [.clear, .black.opacity(0.36)],
            startPoint: .center,
            endPoint: .bottom
          )

          if isVideo {
            Image(systemName: "play.fill")
              .font(.title2.weight(.black))
              .foregroundStyle(.white)
              .shadow(color: .black.opacity(0.55), radius: 4, y: 1)
              .padding(12)
          }
        }
        .frame(width: mediaWidth, height: mediaHeight)
        .clipShape(paperPlaneMediaShape)
        .overlay(alignment: .bottomTrailing) {
          if paperPlaneShouldShowMeta && !hasCaption {
            paperPlaneMetaRow(onMedia: true)
              .padding(.trailing, 8)
              .padding(.bottom, 7)
          }
        }
      } else {
        paperPlaneMediaPlaceholder(isVideo: isVideo)
          .frame(width: mediaWidth, height: isVideo ? mediaWidth * 1.16 : mediaWidth * 0.82)
      }

      if hasCaption {
        Text(message.text)
          .font(.system(size: 16 + theme.style.fontSizeAdjustment, weight: .regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 12)
          .padding(.top, 8)
          .padding(.bottom, paperPlaneShouldShowMeta ? 20 : 9)
          .padding(.trailing, paperPlaneShouldShowMeta ? paperPlaneMetaReserve : 0)
      }
    }
    .background(hasCaption ? paperPlaneBubbleFill : AnyShapeStyle(Color.clear), in: paperPlaneMediaShape)
    .overlay(
      paperPlaneMediaShape
        .stroke(paperPlaneMediaStrokeColor, lineWidth: paperPlaneMediaStrokeWidth)
    )
    .overlay(alignment: .bottomTrailing) {
      if paperPlaneShouldShowMeta && hasCaption {
        paperPlaneMetaRow(onMedia: false)
          .padding(.trailing, 8)
          .padding(.bottom, 6)
      }
    }
    .overlay(alignment: isOutgoing ? .bottomTrailing : .bottomLeading) {
      if paperPlaneShowsMediaTail {
        PaperPlaneBubbleTail(isOutgoing: isOutgoing)
          .fill(paperPlaneBubbleColor)
          .frame(width: 12, height: 13)
          .offset(x: isOutgoing ? 7 : -7, y: 1)
      }
    }
  }

  private func paperPlaneMediaPlaceholder(isVideo: Bool) -> some View {
    RoundedRectangle(cornerRadius: 13, style: .continuous)
      .fill(paperPlaneBubbleFill)
      .overlay {
        VStack(spacing: AppSpacing.xs) {
          Image(systemName: isVideo ? "play.rectangle.fill" : "photo.fill")
            .font(.title.weight(.semibold))
          Text(message.text.isEmpty ? (isVideo ? "Video" : "Photo") : message.text)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(textColor.opacity(0.86))
        .padding(AppSpacing.sm)
      }
      .overlay(alignment: .bottomTrailing) {
        if paperPlaneShouldShowMeta {
          paperPlaneMetaRow(onMedia: false)
            .padding(.trailing, 8)
            .padding(.bottom, 6)
        }
      }
  }

  private func paperPlaneMetaRow(onMedia: Bool) -> some View {
    HStack(spacing: 3) {
      Text(message.displayTime)
      receiptView(onMedia: onMedia)
    }
    .font(.caption2.weight(.medium))
    .foregroundStyle(paperPlaneMetaColor(onMedia: onMedia))
    .shadow(color: onMedia ? .black.opacity(0.72) : .clear, radius: 2, y: 1)
  }

  @ViewBuilder
  private var gradientDMSeenRow: some View {
    if gradientDMShowsSeen {
      Text("Seen just now")
        .font(.caption.weight(.medium))
        .foregroundStyle(
          colorScheme == .dark ? .white.opacity(0.58) : Color(hex: "#6F7480")
        )
        .padding(.trailing, 6)
    }
  }

  private var compactMessengerTextBubble: some View {
    VStack(alignment: .leading, spacing: 3) {
      switch message.type {
      case .text:
        Text(message.text)
          .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
      case .voice:
        voiceBubble
      case .typingIndicator:
        TypingDotsView(color: textColor)
          .padding(.vertical, 4)
      case .missedCall:
        HStack(spacing: AppSpacing.xs) {
          Image(systemName: "phone.down.fill")
          Text(message.text.isEmpty ? "Missed call" : message.text)
        }
        .font(.callout.weight(.semibold))
        .foregroundStyle(textColor)
      default:
        Text(message.text)
          .font(.system(size: 17 + theme.style.fontSizeAdjustment, weight: .regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
      }

      if showMeta && showsInlineMeta && !theme.isWhatsAppStyleTheme && !theme.isPaperPlaneStyleTheme {
        compactMessengerTrailingMetaRow(onMedia: false)
      }
    }
    .padding(.horizontal, compactMessengerHorizontalPadding)
    .padding(.vertical, compactMessengerVerticalPadding)
    .padding(
      .trailing,
      compactMessengerUsesOverlayMeta && showMeta && showsInlineMeta ? compactMessengerMetaReserve : 0
    )
    .padding(.bottom, compactMessengerUsesOverlayMeta && showMeta && showsInlineMeta ? 12 : 0)
    .background(
      compactMessengerBubbleStyle,
      in: compactMessengerShape
    )
    .overlay(
      compactMessengerShape
        .stroke(compactMessengerStrokeColor, lineWidth: compactMessengerStrokeWidth)
    )
    .overlay(alignment: .bottomTrailing) {
      if compactMessengerUsesOverlayMeta, showMeta && showsInlineMeta {
        compactMessengerMetaRow(onMedia: false)
          .padding(.trailing, 9)
          .padding(.bottom, 5)
      }
    }
    .overlay(alignment: compactTailAlignment) {
      if showCompactMessengerTail {
        CompactBubbleTail(isOutgoing: isOutgoing)
          .fill(compactMessengerBubbleColor)
          .frame(width: 10, height: 12)
          .offset(x: isOutgoing ? 7 : -7, y: 0)
      }
    }
  }

  private func compactMessengerMediaBubble(isVideo: Bool) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        ZStack {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: maxWidth, minHeight: 230, maxHeight: 330)
            .clipped()

          LinearGradient(
            colors: [.clear, .black.opacity(0.46)],
            startPoint: .center,
            endPoint: .bottom
          )

          if isVideo {
            Image(systemName: "play.fill")
              .font(.title2.weight(.heavy))
              .foregroundStyle(.white)
              .frame(width: 54, height: 54)
              .background(Color.black.opacity(0.48), in: Circle())
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
          compactMessengerMetaRow(onMedia: true)
            .padding(.trailing, 8)
            .padding(.bottom, 7)
        }
      } else {
        compactMessengerMediaPlaceholder(isVideo: isVideo)
      }

      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.callout.weight(.regular))
          .foregroundStyle(textColor)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 8)
          .padding(.top, 7)
          .padding(.bottom, 4)
      }
    }
    .padding(3)
    .background(
      compactMessengerBubbleStyle,
      in: compactMessengerShape
    )
    .overlay(
      compactMessengerShape
        .stroke(compactMessengerMediaStrokeColor, lineWidth: compactMessengerMediaStrokeWidth)
    )
    .overlay(alignment: compactTailAlignment) {
      if showCompactMessengerTail {
        CompactBubbleTail(isOutgoing: isOutgoing)
          .fill(compactMessengerBubbleColor)
          .frame(width: 10, height: 12)
          .offset(x: isOutgoing ? 7 : -7, y: 0)
      }
    }
  }

  private func compactMessengerMediaPlaceholder(isVideo: Bool) -> some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .fill(Color.white.opacity(0.08))
      .frame(maxWidth: maxWidth, minHeight: 150)
      .overlay {
        VStack(spacing: AppSpacing.xs) {
          Image(systemName: isVideo ? "play.rectangle.fill" : "photo.fill")
            .font(.title.weight(.semibold))
          Text(message.text.isEmpty ? (isVideo ? "Video message" : "Image message") : message.text)
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(textColor.opacity(0.82))
        .padding(AppSpacing.sm)
      }
  }

  private func compactMessengerMetaRow(onMedia: Bool) -> some View {
    HStack(spacing: 4) {
      Text(message.displayTime)
      receiptView(onMedia: onMedia)
    }
    .font(.caption2.weight(.semibold))
    .foregroundStyle(compactMessengerMetaColor(onMedia: onMedia))
    .shadow(color: onMedia ? Color.black.opacity(0.7) : .clear, radius: 2, y: 1)
  }

  private func compactMessengerTrailingMetaRow(onMedia: Bool) -> some View {
    HStack(spacing: 0) {
      Spacer(minLength: AppSpacing.lg)
      compactMessengerMetaRow(onMedia: onMedia)
    }
  }

  @ViewBuilder
  private var centeredMessage: some View {
    if theme.isSnapStyleTheme {
      Text(message.text.uppercased())
        .font(.caption.weight(.heavy))
        .foregroundStyle(snapDateColor)
        .tracking(1.3)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    } else if theme.isPaperPlaneStyleTheme {
      Text(message.text)
        .font(.caption.weight(.heavy))
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
    } else if theme.isSocialMetaStyleTheme || theme.isGradientDMStyleTheme {
      Text(message.text.uppercased())
        .font(.caption.weight(.medium))
        .foregroundStyle(
          theme.isGradientDMStyleTheme && colorScheme == .dark
            ? .white.opacity(0.52)
            : Color(hex: theme.style.dateSeparatorHex)
        )
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
    } else if theme.id == "midnight-doodle" {
      if message.type == .system {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
          Image(systemName: "lock.fill")
            .font(.caption2.weight(.bold))
            .padding(.top, 2)
          Text(message.text)
            .font(.caption.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color(hex: "#FFD98A"))
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color(hex: "#1B1710").opacity(0.96), in: RoundedRectangle(cornerRadius: 7))
        .frame(maxWidth: maxWidth * 1.04)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
      } else {
        Text(message.text)
          .font(.caption.weight(.heavy))
          .foregroundStyle(Color.white.opacity(0.94))
          .padding(.horizontal, AppSpacing.md)
          .padding(.vertical, 7)
          .background(Color.black.opacity(0.42), in: Capsule())
          .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
          .frame(maxWidth: .infinity)
          .padding(.vertical, AppSpacing.xs)
      }
    } else {
      Text(message.text)
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color(hex: theme.style.dateSeparatorHex))
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 4)//AppSpacing.xs
        .background(Color(hex: theme.style.dateSeparatorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
    }
  }

  private var voiceBubble: some View {
    HStack(spacing: AppSpacing.sm) {
      Image(systemName: "play.fill")
        .font(.caption.weight(.bold))
        .frame(width: 26, height: 26)
        .background(textColor.opacity(0.16), in: Circle())
      HStack(spacing: 3) {
        ForEach(0..<18, id: \.self) { index in
          Capsule()
            .fill(textColor.opacity(index % 3 == 0 ? 0.95 : 0.45))
            .frame(width: 3, height: CGFloat(8 + (index % 5) * 3))
        }
      }
      Text("0:12")
        .font(.caption.weight(.bold))
        .foregroundStyle(textColor.opacity(0.78))
    }
  }

  private func mediaBox(systemImage: String, title: String) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
        .fill(textColor.opacity(0.14))
        .frame(minHeight: 120)
        .overlay {
          VStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
              .font(.largeTitle.weight(.semibold))
            Text(title)
              .font(.caption.weight(.semibold))
              .multilineTextAlignment(.center)
          }
          .foregroundStyle(textColor.opacity(0.85))
          .padding(AppSpacing.sm)
        }
    }
  }

  private var imageMessage: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(minHeight: 150)
          .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
      } else {
        mediaBox(
          systemImage: "photo.fill", title: message.text.isEmpty ? "Image message" : message.text)
      }

      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.caption.weight(.semibold))
          .foregroundStyle(textColor.opacity(0.88))
      }
    }
  }

  private var videoMessage: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      if let data = message.mediaData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(minHeight: 150)
          .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
          .overlay {
            ZStack {
              LinearGradient(
                colors: [.black.opacity(0.18), .black.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
              )
              Image(systemName: "play.fill")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.5), in: Circle())
            }
          }
          .overlay(alignment: .bottomTrailing) {
            Label("0:12", systemImage: "video.fill")
              .font(.caption2.weight(.heavy))
              .foregroundStyle(.white)
              .padding(.horizontal, 7)
              .padding(.vertical, 4)
              .background(Color.black.opacity(0.44), in: Capsule())
              .padding(7)
          }
      } else {
        mediaBox(
          systemImage: "play.rectangle.fill",
          title: message.text.isEmpty ? "Video placeholder" : message.text)
      }

      if !message.text.isEmpty && message.mediaData != nil {
        Text(message.text)
          .font(.caption.weight(.semibold))
          .foregroundStyle(textColor.opacity(0.88))
      }
    }
  }

  private var metaRow: some View {
    HStack(spacing: AppSpacing.xxs) {
      Text(message.displayTime)
      receiptView()
    }
    .font(.caption2.weight(.medium))
    .foregroundStyle(.secondary)
    .padding(.horizontal, AppSpacing.xs)
  }

  private var inlineMetaRow: some View {
    HStack(spacing: AppSpacing.xxs) {
      Spacer(minLength: AppSpacing.md)
      Text(message.displayTime)
      receiptView()
    }
    .font(.caption2.weight(.bold))
    .foregroundStyle(textColor.opacity(0.62))
  }

  @ViewBuilder
  private func receiptView(onMedia: Bool = false) -> some View {
    if isOutgoing && shouldShowReceipt {
      switch theme.receiptPresentation {
      case .doubleCheck:
        if theme.isWhatsAppStyleTheme {
          WhatsAppReceiptTicks(
            status: whatsAppReceiptStatus,
            sentColor: whatsAppSentTickColor(onMedia: onMedia),
            readColor: Color(hex: "#53BDEB")
          )
            .frame(width: whatsAppReceiptStatus == .sent ? 9 : 16, height: 10)
        } else if theme.isPaperPlaneStyleTheme {
          Image(systemName: "checkmark")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(paperPlaneReceiptColor(onMedia: onMedia))
        } else {
          HStack(spacing: -4) {
            Image(systemName: "checkmark")
            Image(systemName: "checkmark")
          }
          .font(.caption2.weight(.heavy))
          .foregroundStyle(
            message.readReceipt == .read || message.readReceipt == .seen
              ? Color(hex: theme.id == "midnight-doodle" ? "#58C7FF" : theme.style.accentHex)
              : .secondary)
        }
      case .seenBubble:
        Text(message.readReceipt == .delivered ? "Sent" : "Seen")
          .font(.caption2.weight(.heavy))
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color(hex: theme.style.accentHex).opacity(0.12), in: Capsule())
      case .compact:
        Circle()
          .fill(Color(hex: theme.style.accentHex).opacity(0.8))
          .frame(width: 5, height: 5)
      case .neon:
        Image(systemName: "checkmark.seal.fill")
          .foregroundStyle(Color(hex: theme.style.accentHex))
          .shadow(color: Color(hex: theme.style.accentHex).opacity(0.45), radius: 4)
      case .textLabel:
        Text("·")
        Text(message.readReceipt.shortLabel)
      }
    }
  }

  private var shouldShowReceipt: Bool {
    guard isOutgoing else { return false }
    if theme.isWhatsAppStyleTheme {
      return message.isDelivered || message.isSeen || message.readReceipt != .none
    }
    if theme.isPaperPlaneStyleTheme {
      return message.isDelivered || message.isSeen || message.readReceipt != .none
    }
    return message.readReceipt != .none
  }

  private var whatsAppReceiptStatus: WhatsAppReceiptStatus {
    if message.isSeen || message.readReceipt == .seen || message.readReceipt == .read {
      return .read
    }
    if message.readReceipt == .delivered {
      return .delivered
    }
    return .sent
  }

  private func whatsAppSentTickColor(onMedia: Bool) -> Color {
    if onMedia {
      return .white.opacity(0.9)
    }
    if colorScheme == .dark {
      return .white.opacity(0.68)
    }
    return Color(hex: "#667781")
  }

  private func paperPlaneReceiptColor(onMedia: Bool) -> Color {
    if onMedia {
      return .white.opacity(0.92)
    }
    return colorScheme == .dark ? .white.opacity(0.68) : Color(hex: theme.style.accentHex).opacity(0.82)
  }

  private var miniAvatar: some View {
    Circle()
      .fill(avatarAccentColor.opacity(0.22))
      .frame(width: 28, height: 28)
      .overlay {
        if let data = character.avatarImageData, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
        } else {
          Image(systemName: character.avatarSymbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(avatarAccentColor)
        }
      }
  }

  @ViewBuilder
  private var socialBlueAvatarSlot: some View {
    if isLastInGroup {
      Circle()
        .fill(socialBlueAvatarSlotBackground)
        .frame(width: 28, height: 28)
        .overlay {
          if let data = character.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .clipShape(Circle())
          } else {
            Image(systemName: character.avatarSymbol)
              .font(.caption.weight(.bold))
              .foregroundStyle(Color(hex: theme.style.accentHex))
          }
        }
    } else {
      Color.clear.frame(width: 28, height: 28)
    }
  }

  private var isOutgoing: Bool {
    character.side == .right
  }

  private var customBubbleColor: Color? {
    guard let hex = character.customBubbleColorHex else { return nil }
    return Color(hex: hex)
  }

  private var customTextColor: Color? {
    guard let hex = character.customTextColorHex else { return nil }
    return Color(hex: hex)
  }

  private var avatarAccentColor: Color {
    customBubbleColor ?? Color(hex: theme.style.accentHex)
  }

  private var snapRailColor: Color {
    customBubbleColor ?? (isOutgoing ? Color(hex: "#E63A62") : Color(hex: "#17A8E8"))
  }

  private var snapTextColor: Color {
    customTextColor ?? (colorScheme == .dark ? .white.opacity(0.95) : Color(hex: "#17191D"))
  }

  private var snapDateColor: Color {
    colorScheme == .dark ? .white.opacity(0.42) : Color(hex: "#A7ABB2")
  }

  private var snapMediaPlaceholderFill: Color {
    colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "#F5F6F8")
  }

  private var snapMediaPlaceholderTextColor: Color {
    colorScheme == .dark ? .white.opacity(0.62) : Color(hex: "#5E6570")
  }

  private var snapShareButtonFill: Color {
    colorScheme == .dark ? Color.white.opacity(0.14) : Color(hex: "#EEF0F3")
  }

  private var snapShareIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.78) : Color(hex: "#4D5662")
  }

  private var snapSenderLabel: String {
    isOutgoing ? "Me" : character.name
  }

  private var snapContentSpacing: CGFloat {
    isFirstInGroup ? 3 : 1
  }

  private var snapRailTopInset: CGFloat {
    isFirstInGroup ? 18 : 0
  }

  private var snapRowTopPadding: CGFloat {
    guard isFirstInGroup else { return 0 }
    switch message.type {
    case .image, .video:
      return 4
    default:
      return 2
    }
  }

  private var snapRowBottomPadding: CGFloat {
    guard isLastInGroup else {
      switch message.type {
      case .image, .video:
        return 7
      default:
        return 0
      }
    }

    switch message.type {
    case .image, .video:
      return 9
    default:
      return 5
    }
  }

  private var bubbleHorizontalPadding: CGFloat {
    if message.type == .sticker || message.type == .reaction {
      return AppSpacing.xs
    }
    return theme.style.playfulBlocks ? AppSpacing.lg : AppSpacing.md
  }

  private var bubbleVerticalPadding: CGFloat {
    if message.type == .sticker || message.type == .reaction {
      return AppSpacing.xxs
    }
    return theme.style.playfulBlocks ? AppSpacing.md : AppSpacing.sm
  }

  private var textColor: Color {
    if let customTextColor {
      return customTextColor
    }
    if theme.isSocialMetaStyleTheme {
      return isOutgoing ? .white : Color(hex: "#050505")
    }
    if theme.isGradientDMStyleTheme {
      return isOutgoing ? .white : (colorScheme == .dark ? .white.opacity(0.96) : Color(hex: "#111318"))
    }
    if theme.isPaperPlaneStyleTheme {
      if colorScheme == .dark {
        return isOutgoing ? .white : .white.opacity(0.96)
      }
      return isOutgoing ? Color(hex: theme.style.outgoingTextHex) : Color(hex: theme.style.incomingTextHex)
    }
    if theme.id == "midnight-doodle" {
      return .white
    }
    if theme.isWhatsAppStyleTheme {
      if colorScheme == .dark {
        return .white.opacity(0.95)
      }
      return isOutgoing
        ? Color(hex: theme.style.outgoingTextHex)
        : Color(hex: theme.style.incomingTextHex)
    }
    if theme.usesCompactMessengerLayout {
      if isOutgoing {
        return Color(hex: theme.style.outgoingTextHex)
      }
      return colorScheme == .dark ? .white.opacity(0.95) : Color(hex: theme.style.incomingTextHex)
    }
    if isOutgoing {
      return Color(hex: theme.style.outgoingTextHex)
    }
    return colorScheme == .dark ? .white.opacity(0.94) : Color(hex: theme.style.incomingTextHex)
  }

  private var bubbleColor: Color {
    if let customBubbleColor {
      return customBubbleColor
    }
    if theme.isSocialMetaStyleTheme {
      return Color(
        hex: colorScheme == .dark
          ? (isOutgoing ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex)
          : (isOutgoing ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex)
      )
    }
    if theme.isGradientDMStyleTheme {
      return Color(
        hex: colorScheme == .dark
          ? (isOutgoing ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex)
          : (isOutgoing ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex)
      )
    }
    if theme.isPaperPlaneStyleTheme {
      return Color(
        hex: colorScheme == .dark
          ? (isOutgoing ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex)
          : (isOutgoing ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex)
      )
    }
    if theme.usesThemeBubbleColors {
      return Color(
        hex: colorScheme == .dark
          ? (isOutgoing ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex)
          : (isOutgoing ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex)
      )
    }
    if isOutgoing {
      return Color(hex: colorScheme == .dark ? theme.style.outgoingDarkBubbleHex : theme.style.outgoingBubbleHex)
    }
    return Color(
      hex: colorScheme == .dark ? theme.style.incomingDarkBubbleHex : theme.style.incomingBubbleHex)
  }

  private var bubbleStyle: AnyShapeStyle {
    if isOutgoing && theme.style.usesGradientOutgoing {
      let leadingColor =
        character.customBubbleColorHex
          ?? (colorScheme == .dark ? theme.style.outgoingDarkBubbleHex : theme.style.outgoingBubbleHex)
      return AnyShapeStyle(
        LinearGradient(
          colors: [Color(hex: leadingColor), Color(hex: theme.style.accentHex)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }
    if !isOutgoing && colorScheme == .dark && theme.style.glowOutgoing {
      return AnyShapeStyle(Color.white.opacity(0.08))
    }
    return AnyShapeStyle(bubbleColor)
  }

  private var compactMessengerBubbleStyle: AnyShapeStyle {
    AnyShapeStyle(compactMessengerBubbleColor)
  }

  private var compactMessengerBubbleColor: Color {
    bubbleColor
  }

  private var socialBlueBubbleColor: Color {
    bubbleColor
  }

  private var socialBlueAvatarSlotBackground: Color {
    colorScheme == .dark ? Color(hex: theme.style.incomingDarkBubbleHex) : Color(hex: "#EAF2FF")
  }

  private var socialBlueBubbleShape: UnevenRoundedRectangle {
    let loose: CGFloat = max(theme.style.bubbleCornerRadius, 18)
    let tight: CGFloat = 5

    if isOutgoing {
      return UnevenRoundedRectangle(
        topLeadingRadius: loose,
        bottomLeadingRadius: loose,
        bottomTrailingRadius: isLastInGroup ? loose : tight,
        topTrailingRadius: isFirstInGroup ? loose : tight,
        style: .continuous
      )
    }

    return UnevenRoundedRectangle(
      topLeadingRadius: isFirstInGroup ? loose : tight,
      bottomLeadingRadius: isLastInGroup ? loose : tight,
      bottomTrailingRadius: loose,
      topTrailingRadius: loose,
      style: .continuous
    )
  }

  private var gradientDMBubbleFill: AnyShapeStyle {
    if isOutgoing {
      if let customBubbleColor {
        return AnyShapeStyle(
          LinearGradient(
            colors: [customBubbleColor, Color(hex: theme.style.accentHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      }
      return AnyShapeStyle(
        LinearGradient(
          colors: [Color(hex: "#4F5CFF"), Color(hex: "#8E35FF"), Color(hex: "#C429D8")],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }

    return AnyShapeStyle(
      Color(hex: colorScheme == .dark ? theme.style.incomingDarkBubbleHex : theme.style.incomingBubbleHex)
    )
  }

  private var gradientDMBubbleShape: UnevenRoundedRectangle {
    let loose: CGFloat = 20
    let tight: CGFloat = 5

    if isOutgoing {
      return UnevenRoundedRectangle(
        topLeadingRadius: loose,
        bottomLeadingRadius: loose,
        bottomTrailingRadius: isLastInGroup ? loose : tight,
        topTrailingRadius: isFirstInGroup ? loose : tight,
        style: .continuous
      )
    }

    return UnevenRoundedRectangle(
      topLeadingRadius: isFirstInGroup ? loose : tight,
      bottomLeadingRadius: isLastInGroup ? loose : tight,
      bottomTrailingRadius: loose,
      topTrailingRadius: loose,
      style: .continuous
    )
  }

  private var gradientDMShowsSeen: Bool {
    isOutgoing && isLastInGroup
      && (message.isSeen || message.readReceipt == .seen || message.readReceipt == .read)
      && (message.type == .text || message.type == .image || message.type == .video)
  }

  private var paperPlaneBubbleColor: Color {
    if let customBubbleColor {
      return customBubbleColor
    }
    return Color(
      hex: colorScheme == .dark
        ? (isOutgoing ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex)
        : (isOutgoing ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex)
    )
  }

  private var paperPlaneBubbleFill: AnyShapeStyle {
    AnyShapeStyle(paperPlaneBubbleColor)
  }

  private var paperPlaneTextShape: UnevenRoundedRectangle {
    let loose: CGFloat = 15
    let tight: CGFloat = 5

    if isOutgoing {
      return UnevenRoundedRectangle(
        topLeadingRadius: loose,
        bottomLeadingRadius: loose,
        bottomTrailingRadius: isLastInGroup ? 12 : tight,
        topTrailingRadius: isFirstInGroup ? loose : tight,
        style: .continuous
      )
    }

    return UnevenRoundedRectangle(
      topLeadingRadius: isFirstInGroup ? loose : tight,
      bottomLeadingRadius: isLastInGroup ? loose : tight,
      bottomTrailingRadius: loose,
      topTrailingRadius: loose,
      style: .continuous
    )
  }

  private var paperPlaneMediaShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 13, style: .continuous)
  }

  private var paperPlaneVerticalPadding: CGFloat {
    message.type == .typingIndicator ? 8 : 7
  }

  private var paperPlaneShouldShowMeta: Bool {
    showMeta && showsInlineMeta
  }

  private var paperPlaneMetaReserve: CGFloat {
    isOutgoing ? 55 : 50
  }

  private var paperPlaneShowsTextTail: Bool {
    isLastInGroup
      && (message.type == .text || message.type == .voice || message.type == .typingIndicator)
  }

  private var paperPlaneShowsOutgoingTail: Bool {
    isOutgoing && paperPlaneShowsTextTail
  }

  private var paperPlaneShowsIncomingTail: Bool {
    !isOutgoing && paperPlaneShowsTextTail
  }

  private var paperPlaneShowsMediaTail: Bool {
    isLastInGroup && (message.type == .image || message.type == .video)
  }

  private var paperPlaneStrokeColor: Color {
    colorScheme == .dark ? Color.white.opacity(0.035) : Color.black.opacity(0.045)
  }

  private var paperPlaneStrokeWidth: CGFloat {
    0.5
  }

  private var paperPlaneMediaStrokeColor: Color {
    if isOutgoing {
      let hex = colorScheme == .dark ? theme.style.outgoingDarkBubbleHex : theme.style.outgoingBubbleHex
      return Color(hex: hex).opacity(colorScheme == .dark ? 0.36 : 0.30)
    }
    return colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
  }

  private var paperPlaneMediaStrokeWidth: CGFloat {
    0.6
  }

  private func paperPlaneMetaColor(onMedia: Bool) -> Color {
    if onMedia {
      return .white.opacity(0.92)
    }
    if isOutgoing {
      return colorScheme == .dark ? .white.opacity(0.62) : Color(hex: theme.style.accentHex).opacity(0.82)
    }
    return colorScheme == .dark ? .white.opacity(0.48) : Color(hex: "#6E7E90")
  }

  private var compactMessengerStrokeColor: Color {
    if theme.id == "midnight-doodle" {
      return isOutgoing ? Color(hex: "#167A5A").opacity(0.88) : Color.white.opacity(0.04)
    }
    if theme.isPaperPlaneStyleTheme {
      return colorScheme == .dark
        ? (isOutgoing ? Color.white.opacity(0.08) : Color.white.opacity(0.045))
        : (isOutgoing ? Color(hex: theme.style.accentHex).opacity(0.18) : Color.black.opacity(0.045))
    }
    return Color(hex: theme.style.accentHex).opacity(isOutgoing ? 0.28 : 0.06)
  }

  private var compactMessengerStrokeWidth: CGFloat {
    theme.id == "midnight-doodle" && isOutgoing ? 0.7 : 0.5
  }

  private var compactMessengerMediaStrokeColor: Color {
    if theme.id == "midnight-doodle" {
      return Color(hex: "#167A5A").opacity(isOutgoing ? 0.95 : 0.2)
    }
    if theme.isPaperPlaneStyleTheme {
      return isOutgoing ? Color.white.opacity(0.10) : Color.white.opacity(0.06)
    }
    return Color(hex: theme.style.accentHex).opacity(isOutgoing ? 0.42 : 0.12)
  }

  private var compactMessengerMediaStrokeWidth: CGFloat {
    isOutgoing ? 1.2 : 0.8
  }

  private var compactMessengerCornerRadius: CGFloat {
    theme.isWhatsAppStyleTheme ? 7 : CGFloat(theme.style.bubbleCornerRadius)
  }

  private var compactMessengerShape: UnevenRoundedRectangle {
    if theme.isPaperPlaneStyleTheme {
      let loose: CGFloat = 16
      let tight: CGFloat = 5

      if isOutgoing {
        return UnevenRoundedRectangle(
          topLeadingRadius: loose,
          bottomLeadingRadius: loose,
          bottomTrailingRadius: isLastInGroup ? loose : tight,
          topTrailingRadius: isFirstInGroup ? loose : tight,
          style: .continuous
        )
      }

      return UnevenRoundedRectangle(
        topLeadingRadius: isFirstInGroup ? loose : tight,
        bottomLeadingRadius: isLastInGroup ? loose : tight,
        bottomTrailingRadius: loose,
        topTrailingRadius: loose,
        style: .continuous
      )
    }

    guard theme.isWhatsAppStyleTheme else {
      return UnevenRoundedRectangle(
        topLeadingRadius: compactMessengerCornerRadius,
        bottomLeadingRadius: compactMessengerCornerRadius,
        bottomTrailingRadius: compactMessengerCornerRadius,
        topTrailingRadius: compactMessengerCornerRadius,
        style: .continuous
      )
    }

    let loose: CGFloat = 8
    let tight: CGFloat = 3

    if isOutgoing {
      return UnevenRoundedRectangle(
        topLeadingRadius: loose,
        bottomLeadingRadius: loose,
        bottomTrailingRadius: isLastInGroup ? loose : tight,
        topTrailingRadius: isFirstInGroup ? loose : tight,
        style: .continuous
      )
    }

    return UnevenRoundedRectangle(
      topLeadingRadius: isFirstInGroup ? loose : tight,
      bottomLeadingRadius: isLastInGroup ? loose : tight,
      bottomTrailingRadius: loose,
      topTrailingRadius: loose,
      style: .continuous
    )
  }

  private var compactMessengerHorizontalPadding: CGFloat {
    if theme.isPaperPlaneStyleTheme {
      return 12
    }
    return theme.isWhatsAppStyleTheme ? AppSpacing.sm : AppSpacing.md
  }

  private var compactMessengerVerticalPadding: CGFloat {
    if theme.isPaperPlaneStyleTheme {
      return 7
    }
    return theme.isWhatsAppStyleTheme ? 7 : AppSpacing.sm
  }

  private var compactMessengerTopPadding: CGFloat {
    guard isFirstInGroup else { return 0 }

    if theme.isPaperPlaneStyleTheme {
      return 6
    }

    if theme.isGradientDMStyleTheme {
      return 5
    }

    if theme.isSocialMetaStyleTheme || theme.isWhatsAppStyleTheme {
      return 4
    }

    if message.type == .image || message.type == .video {
      return 5
    }

    if message.type == .reaction || message.type == .sticker {
      return 4
    }

    return 5
  }

  private var compactMessengerMetaReserve: CGFloat {
    if theme.isPaperPlaneStyleTheme {
      return isOutgoing ? 58 : 52
    }
    return isOutgoing ? 72 : 54
  }

  private var compactMessengerUsesOverlayMeta: Bool {
    theme.isWhatsAppStyleTheme || theme.isPaperPlaneStyleTheme
  }

  private var compactTailAlignment: Alignment {
    isOutgoing ? .bottomTrailing : .bottomLeading
  }

  private var showCompactMessengerTail: Bool {
    theme.isWhatsAppStyleTheme && theme.style.hasMessageTail && isLastInGroup
      && (message.type == .text || message.type == .image || message.type == .video || message.type == .voice)
  }

  private func compactMessengerMetaColor(onMedia: Bool) -> Color {
    if theme.id == "midnight-doodle" {
      return onMedia ? .white.opacity(0.94) : .white.opacity(0.66)
    }
    if theme.isPaperPlaneStyleTheme {
      return onMedia ? .white.opacity(0.92) : .white.opacity(0.56)
    }
    if theme.isWhatsAppStyleTheme {
      if colorScheme == .dark {
        return onMedia ? .white.opacity(0.94) : .white.opacity(0.66)
      }
      return onMedia ? .white.opacity(0.94) : Color(hex: "#5D7569")
    }
    return onMedia ? Color.white.opacity(0.92) : textColor.opacity(0.58)
  }

  private var showsInlineMeta: Bool {
    switch message.type {
    case .text, .image, .video, .voice:
      return true
    case .typingIndicator, .timestamp, .reaction, .missedCall, .system, .sticker:
      return false
    }
  }
}

struct TypingDotsView: View {
  let color: Color
  @State private var activeIndex = 0

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(color.opacity(index == activeIndex ? 0.95 : 0.35))
          .frame(width: 7, height: 7)
          .scaleEffect(index == activeIndex ? 1.16 : 0.92)
      }
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
        activeIndex = 2
      }
    }
  }
}

private enum WhatsAppReceiptStatus {
  case sent
  case delivered
  case read
}

private struct WhatsAppReceiptTicks: View {
  let status: WhatsAppReceiptStatus
  let sentColor: Color
  let readColor: Color

  var body: some View {
    ZStack(alignment: .leading) {
      WhatsAppCheckmarkShape()
        .stroke(tickColor, style: StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))
        .frame(width: 8, height: 7)
        .offset(x: status == .sent ? 0 : 0)

      if status != .sent {
        WhatsAppCheckmarkShape()
          .stroke(tickColor, style: StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))
          .frame(width: 8, height: 7)
          .offset(x: 6)
      }
    }
    .accessibilityLabel(accessibilityLabel)
  }

  private var tickColor: Color {
    switch status {
    case .sent, .delivered:
      return sentColor
    case .read:
      return readColor
    }
  }

  private var accessibilityLabel: String {
    switch status {
    case .sent: return "Sent"
    case .delivered: return "Delivered"
    case .read: return "Read"
    }
  }
}

private struct WhatsAppCheckmarkShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.58))
    path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.86))
    path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.94, y: rect.minY + rect.height * 0.16))
    return path
  }
}

struct BubbleTail: Shape {
  let isOutgoing: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    if isOutgoing {
      path.move(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
    } else {
      path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.72))
    }
    path.closeSubpath()
    return path
  }
}

struct CompactBubbleTail: Shape {
  let isOutgoing: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    if isOutgoing {
      path.move(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.68))
    } else {
      path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.68))
    }
    path.closeSubpath()
    return path
  }
}

struct PaperPlaneBubbleTail: Shape {
  let isOutgoing: Bool

  func path(in rect: CGRect) -> Path {
    var path = Path()
    if isOutgoing {
      path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.16))
      path.addQuadCurve(
        to: CGPoint(x: rect.maxX, y: rect.maxY),
        control: CGPoint(x: rect.maxX * 0.52, y: rect.maxY * 0.74)
      )
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
    } else {
      path.move(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.16))
      path.addQuadCurve(
        to: CGPoint(x: rect.minX, y: rect.maxY),
        control: CGPoint(x: rect.maxX * 0.48, y: rect.maxY * 0.74)
      )
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.72))
    }
    path.closeSubpath()
    return path
  }
}
