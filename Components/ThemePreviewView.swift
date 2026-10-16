import SwiftUI
import UIKit

struct ThemePreviewView: View {
  let theme: ChatTheme
  var compact: Bool = false

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    GeometryReader { geometry in
      if compact {
        compactPreview(width: geometry.size.width)
      } else {
        fullPreview(width: geometry.size.width)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
        .stroke(previewStroke, lineWidth: 1)
    )
  }

  private func fullPreview(width: CGFloat) -> some View {
    VStack(spacing: 0) {
      ChatHeaderView(
        story: previewStory,
        theme: theme,
        cornerRadius: previewCornerRadius,
        roundedCorners: [.topLeft, .topRight]
      )

      ScrollView {
        LazyVStack(spacing: theme.compactMessageSpacing) {
          ForEach(Array(fullMessages.enumerated()), id: \.element.id) { index, message in
            if let character = character(for: message) {
              let group = messageGroup(at: index, in: fullMessages)
              ChatBubbleView(
                message: message,
                character: character,
                theme: theme,
                maxWidth: bubbleMaxWidth(for: width),
                isFirstInGroup: group.isFirst,
                isLastInGroup: group.isLast
              )
            }
          }
        }
        .padding(.vertical, fullVerticalPadding)
      }
      .scrollIndicators(.hidden)
      .background(themeBackground)

      ChatInputBarPreview(
        theme: theme,
        placeholder: theme.inputPlaceholder,
        roundedCorners: [.bottomLeft, .bottomRight],
        cornerRadius: previewCornerRadius,
        isDockedInChatFrame: true
      )
    }
    .background(chatFrameBackground)
  }

  private func compactPreview(width: CGFloat) -> some View {
    ZStack {
      themeBackground

      VStack(spacing: max(theme.compactMessageSpacing * 0.65, 2)) {
        ForEach(Array(compactMessages.enumerated()), id: \.element.id) { index, message in
          if let character = character(for: message) {
            let group = messageGroup(at: index, in: compactMessages)
            ChatBubbleView(
              message: message,
              character: character,
              theme: theme,
              maxWidth: max(width * 0.68, 68),
              showMeta: false,
              isFirstInGroup: group.isFirst,
              isLastInGroup: group.isLast
            )
            .scaleEffect(compactBubbleScale, anchor: character.side == .right ? .trailing : .leading)
          }
        }
      }
      .padding(AppSpacing.xs)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    .background(chatFrameBackground)
  }

  private var previewStory: ChatStory {
    ChatStory(
      title: theme.name,
      themeID: theme.id,
      characters: previewCharacters,
      messages: fullMessages,
      format: .normalChat
    )
  }

  private var previewCharacters: [ChatCharacter] {
    [
      ChatCharacter(
        id: ThemePreviewSample.incomingCharacterID,
        name: incomingName,
        avatarSymbol: incomingAvatar,
        bubbleColorHex: theme.style.incomingBubbleHex,
        textColorHex: theme.style.incomingTextHex,
        side: .left,
        isOnline: true,
        statusText: incomingStatus
      ),
      ChatCharacter(
        id: ThemePreviewSample.outgoingCharacterID,
        name: outgoingName,
        avatarSymbol: outgoingAvatar,
        bubbleColorHex: theme.style.outgoingBubbleHex,
        textColorHex: theme.style.outgoingTextHex,
        side: .right,
        isOnline: true,
        statusText: "online"
      ),
    ]
  }

  private var compactMessages: [ChatMessage] {
    switch theme.id {
    case "snap-style":
      return [
        sampleMessage(.incomingOne, .text, "New snap idea?"),
        sampleMessage(.outgoingOne, .text, "Make it dramatic."),
      ]
    case "paper-plane":
      return [
        sampleMessage(.incomingOne, .text, "Hello", time: "9:35 AM"),
        sampleMessage(.outgoingOne, .text, "On the way", time: "9:40 AM", receipt: .delivered),
      ]
    case "social-blue", "gradient-bubble":
      return [
        sampleMessage(.incomingOne, .text, "Quick update?"),
        sampleMessage(.outgoingOne, .text, "Sending it now", receipt: .seen, seen: true),
      ]
    case "green-bubble", "midnight-doodle":
      return [
        sampleMessage(.incomingOne, .text, "Can we talk?", time: "4:26 PM"),
        sampleMessage(.outgoingOne, .text, "Yes, send details", time: "4:27 PM", receipt: .read, seen: true),
      ]
    default:
      return [
        sampleMessage(.incomingOne, .text, "Scene starts here"),
        sampleMessage(.outgoingOne, .text, "Perfect hook.", receipt: .delivered),
      ]
    }
  }

  private var fullMessages: [ChatMessage] {
    switch theme.id {
    case "blue-bubble":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "You will not believe what just happened.", time: "8:47 AM"),
        sampleMessage(.outgoingOne, .text, "That sounds like the start of a suspicious story.", time: "8:47 AM", receipt: .delivered),
        sampleMessage(.incomingTwo, .typingIndicator, "", time: "8:48 AM"),
        sampleMessage(.incomingThree, .text, "The locked room had a second key.", time: "8:48 AM"),
      ]
    case "green-bubble":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "Can we make this dramatic?", time: "4:26 PM"),
        sampleMessage(.outgoingOne, .text, "Already writing the twist.", time: "4:27 PM", receipt: .read, seen: true),
        sampleMessage(.outgoingTwo, .image, "Location clue", mediaData: ThemePreviewSample.mediaData, time: "4:28 PM", receipt: .read, seen: true),
        sampleMessage(.incomingTwo, .voice, "Voice note", time: "4:29 PM"),
      ]
    case "midnight-doodle":
      return [
        sampleMessage(.systemOne, .system, "Private fictional chat preview. Only your story cast appears here."),
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.outgoingOne, .text, "Total = 3541", time: "12:54 PM", receipt: .delivered),
        sampleMessage(.outgoingTwo, .image, "Receipt photo", mediaData: ThemePreviewSample.mediaData, time: "12:56 PM", receipt: .read, seen: true),
        sampleMessage(.incomingOne, .text, "Got it.", time: "12:57 PM"),
      ]
    case "social-blue":
      return [
        sampleMessage(.incomingOne, .text, "Hii", time: "12:25 PM"),
        sampleMessage(.dateOne, .timestamp, "18 Jun 2018 at 12:25"),
        sampleMessage(.outgoingOne, .text, "Can you check this?", time: "12:26 PM", receipt: .seen, seen: true),
        sampleMessage(.outgoingTwo, .image, "Image message", mediaData: ThemePreviewSample.mediaData, time: "12:27 PM", receipt: .seen, seen: true),
        sampleMessage(.incomingTwo, .text, "Looks good", time: "12:28 PM"),
      ]
    case "gradient-bubble":
      return [
        sampleMessage(.incomingOne, .text, "Sara's hoo", time: "9:08 AM"),
        sampleMessage(.outgoingOne, .text, "Okay saru kevay", time: "9:09 AM", receipt: .seen, seen: true),
        sampleMessage(.outgoingTwo, .text, "App bane che", time: "9:09 AM", receipt: .seen, seen: true),
        sampleMessage(.outgoingThree, .video, "Pool day clip", mediaData: ThemePreviewSample.tallMediaData, time: "9:10 AM", receipt: .seen, seen: true),
      ]
    case "paper-plane":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "Hello", time: "9:35 AM"),
        sampleMessage(.incomingTwo, .text, "How are you?", time: "9:36 AM"),
        sampleMessage(.incomingThree, .image, "", mediaData: ThemePreviewSample.mediaData, time: "9:36 AM"),
        sampleMessage(.outgoingOne, .text, "Hi", time: "9:40 AM", receipt: .delivered),
        sampleMessage(.outgoingTwo, .text, "All good", time: "9:40 AM", receipt: .delivered),
      ]
    case "snap-style":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "Hello"),
        sampleMessage(.outgoingOne, .text, "Ha bol ne"),
        sampleMessage(.incomingTwo, .text, "How are you?"),
        sampleMessage(.outgoingTwo, .image, "x", mediaData: ThemePreviewSample.wideMediaData),
      ]
    case "dark-neon":
      return [
        sampleMessage(.dateOne, .timestamp, "Live Scene"),
        sampleMessage(.incomingOne, .text, "Signal found in the archive.", time: "11:12 PM"),
        sampleMessage(.outgoingOne, .voice, "Voice imprint", time: "11:13 PM", receipt: .read, seen: true),
        sampleMessage(.incomingTwo, .typingIndicator, "", time: "11:13 PM"),
        sampleMessage(.outgoingTwo, .reaction, "⚡️", time: "11:14 PM", receipt: .read, seen: true),
      ]
    case "minimal-white":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "A quiet setup works best.", time: "10:10 AM"),
        sampleMessage(.outgoingOne, .text, "Clean, readable, and calm.", time: "10:11 AM", receipt: .delivered),
        sampleMessage(.incomingTwo, .reaction, "✓", time: "10:12 AM"),
      ]
    case "creator-dark":
      return [
        sampleMessage(.dateOne, .timestamp, "Export Preview"),
        sampleMessage(.incomingOne, .text, "Make this reel readable.", time: "7:40 PM"),
        sampleMessage(.outgoingOne, .video, "Vertical scene", mediaData: ThemePreviewSample.tallMediaData, time: "7:41 PM", receipt: .read, seen: true),
        sampleMessage(.systemOne, .system, "9:16 layout ready"),
      ]
    case "candy-pop":
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .sticker, "🍭", time: "2:14 PM"),
        sampleMessage(.outgoingOne, .text, "This scene needs sparkle.", time: "2:15 PM", receipt: .seen, seen: true),
        sampleMessage(.incomingTwo, .reaction, "💖", time: "2:15 PM"),
      ]
    default:
      return [
        sampleMessage(.dateOne, .timestamp, "Today"),
        sampleMessage(.incomingOne, .text, "Can we make this dramatic?", time: "4:26 PM"),
        sampleMessage(.outgoingOne, .text, "Already writing the twist.", time: "4:27 PM", receipt: .read, seen: true),
        sampleMessage(.incomingTwo, .typingIndicator, "", time: "4:28 PM"),
      ]
    }
  }

  private func sampleMessage(
    _ id: ThemePreviewSample.MessageID,
    _ type: MessageType,
    _ text: String,
    mediaData: Data? = nil,
    time: String = "9:41 AM",
    receipt: ReadReceiptStatus = .none,
    delivered: Bool = true,
    seen: Bool = false
  ) -> ChatMessage {
    ChatMessage(
      id: id.uuid,
      characterID: id.isOutgoing ? ThemePreviewSample.outgoingCharacterID : ThemePreviewSample.incomingCharacterID,
      type: type,
      text: text,
      mediaData: mediaData,
      displayTime: time,
      readReceipt: receipt,
      reaction: type == .reaction ? text : "",
      isDelivered: delivered,
      isSeen: seen
    )
  }

  private func character(for message: ChatMessage) -> ChatCharacter? {
    previewCharacters.first { $0.id == message.characterID } ?? previewCharacters.first
  }

  private func messageGroup(at index: Int, in messages: [ChatMessage]) -> (isFirst: Bool, isLast: Bool) {
    let message = messages[index]
    let previousMatches = index > 0 && messages[index - 1].isGroupedWith(message)
    let nextMatches = index < messages.count - 1 && messages[index + 1].isGroupedWith(message)
    return (!previousMatches, !nextMatches)
  }

  private func bubbleMaxWidth(for width: CGFloat) -> CGFloat {
    min(DeviceSize.chatBubbleMaxWidth(for: width), width * 0.74)
  }

  private var themeBackground: some View {
    ThemeWallpaperView(theme: theme, intensity: wallpaperIntensity)
  }

  private var wallpaperIntensity: CGFloat {
    switch theme.id {
    case "midnight-doodle": return 0.96
    case "paper-plane": return 0.9
    case "snap-style", "social-blue", "gradient-bubble": return compact ? 0.22 : 0.42
    default: return compact ? 0.42 : 0.66
    }
  }

  private var incomingName: String {
    switch theme.id {
    case "midnight-doodle": return "Archana"
    case "social-blue": return "Sanket"
    case "gradient-bubble": return "anirudh"
    case "paper-plane": return "Anirudh Bhalala"
    case "snap-style": return "bhalala.anirudh"
    case "creator-dark": return "Director"
    default: return "Avery"
    }
  }

  private var outgoingName: String {
    theme.isSnapStyleTheme ? "Me" : "You"
  }

  private var incomingStatus: String {
    switch theme.id {
    case "gradient-bubble": return "Active now"
    case "paper-plane": return "last seen recently"
    case "snap-style": return ""
    case "creator-dark": return "reviewing"
    default: return "online"
    }
  }

  private var incomingAvatar: String {
    switch theme.id {
    case "midnight-doodle": return "moon.stars.circle.fill"
    case "paper-plane": return "a.circle.fill"
    case "snap-style": return "face.smiling.fill"
    case "creator-dark": return "video.circle.fill"
    default: return "person.crop.circle.fill"
    }
  }

  private var outgoingAvatar: String {
    theme.isSnapStyleTheme ? "person.crop.circle.fill" : "sparkles"
  }

  private var fullVerticalPadding: CGFloat {
    if theme.isSnapStyleTheme { return AppSpacing.xs }
    if theme.isWhatsAppStyleTheme || theme.isPaperPlaneStyleTheme { return AppSpacing.sm }
    return AppSpacing.md
  }

  private var compactBubbleScale: CGFloat {
    theme.isSnapStyleTheme ? 0.78 : 0.72
  }

  private var previewCornerRadius: CGFloat {
    compact ? AppRadius.md : 0
  }

  private var chatFrameBackground: Color {
    Color(hex: colorScheme == .dark ? theme.style.darkBackgroundHex : theme.style.backgroundHex)
  }

  private var previewStroke: Color {
    theme.style.glowOutgoing
      ? Color(hex: theme.style.accentHex).opacity(0.42)
      : AppColors.hairline
  }
}

private enum ThemePreviewSample {
  static let incomingCharacterID = UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907001")!
  static let outgoingCharacterID = UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907002")!

  enum MessageID {
    case dateOne
    case systemOne
    case incomingOne
    case incomingTwo
    case incomingThree
    case outgoingOne
    case outgoingTwo
    case outgoingThree

    var uuid: UUID {
      switch self {
      case .dateOne: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907101")!
      case .systemOne: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907102")!
      case .incomingOne: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907103")!
      case .incomingTwo: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907104")!
      case .incomingThree: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907105")!
      case .outgoingOne: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907106")!
      case .outgoingTwo: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907107")!
      case .outgoingThree: return UUID(uuidString: "F41AEE8C-40D6-4F17-BC1E-1DC910907108")!
      }
    }

    var isOutgoing: Bool {
      switch self {
      case .outgoingOne, .outgoingTwo, .outgoingThree:
        return true
      case .dateOne, .systemOne, .incomingOne, .incomingTwo, .incomingThree:
        return false
      }
    }
  }

  static let mediaData = makeImageData(size: CGSize(width: 520, height: 390), variant: .landscape)
  static let tallMediaData = makeImageData(size: CGSize(width: 390, height: 560), variant: .portrait)
  static let wideMediaData = makeImageData(size: CGSize(width: 520, height: 300), variant: .wide)

  private enum ImageVariant {
    case landscape
    case portrait
    case wide
  }

  private static func makeImageData(size: CGSize, variant: ImageVariant) -> Data? {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
      let cgContext = context.cgContext
      let colors: [CGColor]
      switch variant {
      case .landscape:
        colors = [UIColor(red: 0.09, green: 0.46, blue: 0.88, alpha: 1).cgColor, UIColor(red: 0.20, green: 0.72, blue: 0.55, alpha: 1).cgColor]
      case .portrait:
        colors = [UIColor(red: 0.16, green: 0.13, blue: 0.30, alpha: 1).cgColor, UIColor(red: 0.75, green: 0.22, blue: 0.80, alpha: 1).cgColor]
      case .wide:
        colors = [UIColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1).cgColor, UIColor(red: 0.45, green: 0.66, blue: 0.94, alpha: 1).cgColor]
      }

      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0, 1]
      )
      if let gradient {
        cgContext.drawLinearGradient(
          gradient,
          start: CGPoint(x: 0, y: 0),
          end: CGPoint(x: size.width, y: size.height),
          options: []
        )
      }

      drawPreviewShapes(in: cgContext, size: size, variant: variant)
    }
    return image.jpegData(compressionQuality: 0.82)
  }

  private static func drawPreviewShapes(
    in context: CGContext,
    size: CGSize,
    variant: ImageVariant
  ) {
    context.saveGState()
    defer { context.restoreGState() }

    UIColor.white.withAlphaComponent(0.22).setFill()
    for index in 0..<7 {
      let radius = CGFloat(38 + index * 18)
      let x = CGFloat((index * 89) % Int(max(size.width, 1))) - radius * 0.4
      let y = CGFloat((index * 61) % Int(max(size.height, 1))) - radius * 0.3
      context.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
    }

    UIColor.black.withAlphaComponent(0.16).setFill()
    let baseY = size.height * (variant == .portrait ? 0.64 : 0.58)
    var mountain = UIBezierPath()
    mountain.move(to: CGPoint(x: 0, y: size.height))
    mountain.addLine(to: CGPoint(x: 0, y: baseY))
    mountain.addCurve(
      to: CGPoint(x: size.width, y: baseY + size.height * 0.05),
      controlPoint1: CGPoint(x: size.width * 0.25, y: baseY - size.height * 0.20),
      controlPoint2: CGPoint(x: size.width * 0.72, y: baseY + size.height * 0.24)
    )
    mountain.addLine(to: CGPoint(x: size.width, y: size.height))
    mountain.close()
    mountain.fill()

    UIColor.white.withAlphaComponent(0.24).setStroke()
    context.setLineWidth(4)
    for index in 0..<5 {
      let y = size.height * 0.18 + CGFloat(index) * size.height * 0.12
      context.move(to: CGPoint(x: size.width * 0.12, y: y))
      context.addCurve(
        to: CGPoint(x: size.width * 0.88, y: y + 18),
        control1: CGPoint(x: size.width * 0.36, y: y - 24),
        control2: CGPoint(x: size.width * 0.58, y: y + 38)
      )
      context.strokePath()
    }
  }
}

struct ThemeWallpaperView: View {
  let theme: ChatTheme
  var intensity: CGFloat = 1

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      if theme.isWhatsAppStyleTheme {
        GeometryReader { proxy in
          Image(colorScheme == .dark ? "ic_dark_bg" : "ic_light_bg")
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
      } else {
        LinearGradient(
          colors: backgroundColors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        ThemeWallpaperPattern(
          themeID: theme.id,
          accent: Color(hex: theme.style.wallpaperAccentHex),
          secondary: Color(hex: theme.style.accentHex),
          isDark: colorScheme == .dark,
          intensity: intensity
        )
      }
    }
    .clipped()
    .allowsHitTesting(false)
  }

  private var backgroundColors: [Color] {
    let base = Color(
      hex: colorScheme == .dark ? theme.style.darkBackgroundHex : theme.style.backgroundHex)
    let accent = Color(hex: theme.style.wallpaperAccentHex)
    let secondary = Color(hex: theme.style.accentHex)

    switch theme.id {
    case "social-blue":
      return [Color.white, Color.white]
    case "minimal-white":
      return colorScheme == .dark
        ? [base, Color(hex: "#191919")] : [Color.white, Color(hex: "#F8F8FA")]
    case "creator-dark":
      return [Color(hex: "#090B0F"), base, Color(hex: "#171D26")]
    case "dark-neon":
      return [Color(hex: "#050611"), base, Color(hex: "#14102A")]
    case "snap-style":
      return colorScheme == .dark
        ? [Color(hex: "#070A10"), Color(hex: "#070A10")]
        : [Color.white, Color.white]
    case "candy-pop":
      return colorScheme == .dark
        ? [base, Color(hex: "#331B31")] : [Color(hex: "#FFF4FB"), Color(hex: "#EEF9FF")]
    case "gradient-bubble":
      return colorScheme == .dark
        ? [Color(hex: "#070A10"), Color(hex: "#070A10")]
        : [Color.white, Color.white]
    case "paper-plane":
      return colorScheme == .dark
        ? [Color(hex: "#02030B"), Color(hex: "#070411"), Color(hex: "#02030B")]
        : [Color(hex: "#BFE8A8"), Color(hex: "#EAF9DF"), Color(hex: "#8FD093")]
    case "midnight-doodle":
      return [Color(hex: "#080A09"), Color(hex: "#0C0F0E"), Color(hex: "#101311")]
    default:
      return [base, accent.opacity(colorScheme == .dark ? 0.22 : 0.34)]
    }
  }
}

private struct ThemeWallpaperPattern: View {
  let themeID: String
  let accent: Color
  let secondary: Color
  let isDark: Bool
  let intensity: CGFloat

  var body: some View {
    Canvas { context, size in
      switch themeID {
      case "blue-bubble":
        drawSoftRings(in: &context, size: size)
        drawDiagonalThreads(in: &context, size: size, spacing: 46)
      case "green-bubble":
        drawMeadowMarks(in: &context, size: size)
        drawSoftDots(in: &context, size: size, spacing: 42, radius: 2.4)
      case "midnight-doodle":
        drawMidnightDoodles(in: &context, size: size)
      case "social-blue":
        break
      case "paper-plane":
        if isDark {
          drawPaperPlaneDoodles(in: &context, size: size)
        } else {
          drawFoldedPlanes(in: &context, size: size)
          drawDiagonalThreads(in: &context, size: size, spacing: 64)
        }
      case "snap-style":
        break
      case "dark-neon":
        drawNeonGrid(in: &context, size: size)
        drawOrbitBubbles(in: &context, size: size)
      case "minimal-white":
        drawMinimalLines(in: &context, size: size)
      case "creator-dark":
        drawCreatorStage(in: &context, size: size)
      case "candy-pop":
        drawCandyPattern(in: &context, size: size)
      case "gradient-bubble":
        break
      default:
        drawSoftRings(in: &context, size: size)
        drawSoftDots(in: &context, size: size, spacing: 52, radius: 2)
      }
    }
    .opacity(Double(intensity))
    .blendMode(isDark ? .screen : .multiply)
    .allowsHitTesting(false)
  }

  private func drawSoftRings(in context: inout GraphicsContext, size: CGSize) {
    let color = accent.opacity(isDark ? 0.18 : 0.24)
    for index in 0..<7 {
      let radius = CGFloat(42 + index * 24)
      let x = CGFloat((index * 73) % Int(max(size.width, 1))) - 20
      let y = CGFloat((index * 97) % Int(max(size.height, 1))) - 10
      let rect = CGRect(x: x, y: y, width: radius, height: radius)
      context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.4)
    }
  }

  private func drawDiagonalThreads(
    in context: inout GraphicsContext, size: CGSize, spacing: CGFloat
  ) {
    let lineColor = secondary.opacity(isDark ? 0.09 : 0.07)
    for offset in stride(from: -size.height, through: size.width, by: spacing) {
      var path = Path()
      path.move(to: CGPoint(x: offset, y: 0))
      path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
      context.stroke(path, with: .color(lineColor), lineWidth: 1)
    }
  }

  private func drawSoftDots(
    in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, radius: CGFloat
  ) {
    let dotColor = accent.opacity(isDark ? 0.16 : 0.18)
    for x in stride(from: CGFloat(10), through: size.width, by: spacing) {
      for y in stride(from: CGFloat(12), through: size.height, by: spacing) {
        let offset = CGFloat(Int(y / spacing).isMultiple(of: 2) ? 0 : 14)
        let rect = CGRect(x: x + offset, y: y, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(dotColor))
      }
    }
  }

  private func drawMeadowMarks(in context: inout GraphicsContext, size: CGSize) {
    let color = secondary.opacity(isDark ? 0.16 : 0.18)
    for x in stride(from: CGFloat(18), through: size.width, by: 54) {
      for y in stride(from: CGFloat(18), through: size.height, by: 50) {
        var leaf = Path()
        leaf.move(to: CGPoint(x: x, y: y + 8))
        leaf.addQuadCurve(to: CGPoint(x: x + 14, y: y), control: CGPoint(x: x + 4, y: y - 8))
        leaf.addQuadCurve(to: CGPoint(x: x, y: y + 8), control: CGPoint(x: x + 13, y: y + 10))
        context.fill(leaf, with: .color(color))
      }
    }
  }

  private func drawOrbitBubbles(in context: inout GraphicsContext, size: CGSize) {
    for index in 0..<18 {
      let width = CGFloat(18 + (index % 5) * 8)
      let x = CGFloat((index * 41) % Int(max(size.width, 1)))
      let y = CGFloat((index * 67) % Int(max(size.height, 1)))
      let rect = CGRect(x: x, y: y, width: width, height: width)
      let color = (index.isMultiple(of: 2) ? accent : secondary).opacity(isDark ? 0.15 : 0.14)
      context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.2)
    }
  }

  private func drawFoldedPlanes(in context: inout GraphicsContext, size: CGSize) {
    let color = secondary.opacity(isDark ? 0.14 : 0.16)
    for x in stride(from: CGFloat(20), through: size.width + 40, by: 86) {
      for y in stride(from: CGFloat(28), through: size.height + 30, by: 78) {
        var plane = Path()
        plane.move(to: CGPoint(x: x, y: y))
        plane.addLine(to: CGPoint(x: x + 26, y: y + 9))
        plane.addLine(to: CGPoint(x: x + 4, y: y + 19))
        plane.addLine(to: CGPoint(x: x + 9, y: y + 10))
        plane.closeSubpath()
        context.stroke(plane, with: .color(color), lineWidth: 1.1)
      }
    }
  }

  private func drawSunburstCards(in context: inout GraphicsContext, size: CGSize) {
    let color = secondary.opacity(isDark ? 0.12 : 0.16)
    for index in 0..<9 {
      let rect = CGRect(
        x: CGFloat((index * 59) % Int(max(size.width, 1))) - 18,
        y: CGFloat((index * 83) % Int(max(size.height, 1))) - 10,
        width: 72,
        height: 34
      )
      context.fill(Path(roundedRect: rect, cornerRadius: 17), with: .color(color))
    }
  }

  private func drawConfetti(in context: inout GraphicsContext, size: CGSize) {
    for index in 0..<52 {
      let x = CGFloat((index * 31) % Int(max(size.width, 1)))
      let y = CGFloat((index * 47) % Int(max(size.height, 1)))
      let rect = CGRect(x: x, y: y, width: 7, height: 3)
      let color = (index.isMultiple(of: 3) ? accent : secondary).opacity(isDark ? 0.2 : 0.26)
      context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
    }
  }

  private func drawNeonGrid(in context: inout GraphicsContext, size: CGSize) {
    let color = secondary.opacity(0.18)
    for x in stride(from: CGFloat(0), through: size.width, by: 38) {
      var path = Path()
      path.move(to: CGPoint(x: x, y: 0))
      path.addLine(to: CGPoint(x: x + 32, y: size.height))
      context.stroke(path, with: .color(color), lineWidth: 0.8)
    }
    for y in stride(from: CGFloat(16), through: size.height, by: 44) {
      var path = Path()
      path.move(to: CGPoint(x: 0, y: y))
      path.addLine(to: CGPoint(x: size.width, y: y + 18))
      context.stroke(path, with: .color(accent.opacity(0.13)), lineWidth: 0.8)
    }
  }

  private func drawMinimalLines(in context: inout GraphicsContext, size: CGSize) {
    let color = (isDark ? Color.white : Color.black).opacity(isDark ? 0.08 : 0.045)
    for y in stride(from: CGFloat(24), through: size.height, by: 38) {
      var path = Path()
      path.move(to: CGPoint(x: 18, y: y))
      path.addLine(to: CGPoint(x: size.width - 18, y: y + 5))
      context.stroke(path, with: .color(color), lineWidth: 1)
    }
  }

  private func drawCreatorStage(in context: inout GraphicsContext, size: CGSize) {
    let color = accent.opacity(0.16)
    for index in 0..<6 {
      let startX = CGFloat(index) * size.width / 5
      var beam = Path()
      beam.move(to: CGPoint(x: startX, y: 0))
      beam.addLine(to: CGPoint(x: startX + 44, y: size.height))
      beam.addLine(to: CGPoint(x: startX + 4, y: size.height))
      beam.closeSubpath()
      context.fill(beam, with: .color(color))
    }
  }

  private func drawCandyPattern(in context: inout GraphicsContext, size: CGSize) {
    drawSoftDots(in: &context, size: size, spacing: 40, radius: 4)
    for index in 0..<12 {
      let rect = CGRect(
        x: CGFloat((index * 53) % Int(max(size.width, 1))),
        y: CGFloat((index * 71) % Int(max(size.height, 1))),
        width: 34,
        height: 16
      )
      context.stroke(
        Path(roundedRect: rect, cornerRadius: 8),
        with: .color(secondary.opacity(isDark ? 0.18 : 0.2)), lineWidth: 1.2)
    }
  }

  private func drawRibbonPattern(in context: inout GraphicsContext, size: CGSize) {
    for index in 0..<5 {
      var path = Path()
      let y = CGFloat(index) * size.height / 4 - 24
      path.move(to: CGPoint(x: -30, y: y))
      path.addCurve(
        to: CGPoint(x: size.width + 30, y: y + 42),
        control1: CGPoint(x: size.width * 0.28, y: y + 86),
        control2: CGPoint(x: size.width * 0.72, y: y - 54)
      )
      context.stroke(
        path,
        with: .color((index.isMultiple(of: 2) ? accent : secondary).opacity(isDark ? 0.18 : 0.22)),
        lineWidth: 18)
    }
  }

  private func drawPaperPlaneDoodles(in context: inout GraphicsContext, size: CGSize) {
    let lineColor = secondary.opacity(0.20)
    let accentColor = accent.opacity(0.14)

    for x in stride(from: CGFloat(-14), through: size.width + 72, by: 54) {
      for y in stride(from: CGFloat(6), through: size.height + 72, by: 54) {
        let phase = Int((x + y) / 10) % 7
        let origin = CGPoint(x: x + CGFloat(phase * 4), y: y)

        switch phase {
        case 0:
          drawDoodlePlane(in: &context, at: origin, color: lineColor)
        case 1:
          drawDoodleBubble(in: &context, at: origin, color: lineColor)
        case 2:
          drawDoodleSpark(in: &context, at: origin, color: lineColor)
        case 3:
          drawDoodlePhone(in: &context, at: origin, color: lineColor)
        case 4:
          drawDoodleCamera(in: &context, at: origin, color: lineColor)
        case 5:
          drawDoodleSmile(in: &context, at: origin, color: lineColor)
        default:
          drawDoodleLock(in: &context, at: origin, color: lineColor)
        }

        let dotRect = CGRect(x: origin.x + 39, y: origin.y + 18, width: 3, height: 3)
        context.fill(Path(ellipseIn: dotRect), with: .color(accentColor))
      }
    }

    for x in stride(from: CGFloat(-20), through: size.width + 40, by: 40) {
      var path = Path()
      path.move(to: CGPoint(x: x, y: 0))
      path.addLine(to: CGPoint(x: x + 36, y: size.height))
      context.stroke(path, with: .color(Color.white.opacity(0.035)), lineWidth: 0.8)
    }
  }

  private func drawMidnightDoodles(in context: inout GraphicsContext, size: CGSize) {
    let lineColor = Color.white.opacity(isDark ? 0.12 : 0.09)
    let dotColor = accent.opacity(0.11)

    for x in stride(from: CGFloat(-18), through: size.width + 70, by: 58) {
      for y in stride(from: CGFloat(8), through: size.height + 68, by: 56) {
        let phase = Int((x + y) / 10).modulo(7)
        let origin = CGPoint(x: x + CGFloat(phase * 5), y: y)

        switch phase {
        case 0:
          drawDoodleBubble(in: &context, at: origin, color: lineColor)
        case 1:
          drawDoodleCamera(in: &context, at: origin, color: lineColor)
        case 2:
          drawDoodleLock(in: &context, at: origin, color: lineColor)
        case 3:
          drawDoodleSpark(in: &context, at: origin, color: lineColor)
        case 4:
          drawDoodlePhone(in: &context, at: origin, color: lineColor)
        case 5:
          drawDoodlePlane(in: &context, at: origin, color: lineColor)
        default:
          drawDoodleSmile(in: &context, at: origin, color: lineColor)
        }

        let dotRect = CGRect(x: origin.x + 45, y: origin.y + 21, width: 3.5, height: 3.5)
        context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
      }
    }

    let dashColor = Color.white.opacity(isDark ? 0.055 : 0.04)
    for x in stride(from: CGFloat(4), through: size.width + 44, by: 46) {
      for y in stride(from: CGFloat(34), through: size.height + 44, by: 68) {
        var dash = Path()
        dash.move(to: CGPoint(x: x, y: y))
        dash.addLine(to: CGPoint(x: x + 16, y: y + 2))
        context.stroke(dash, with: .color(dashColor), lineWidth: 1.1)
      }
    }
  }

  private func drawDoodleBubble(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    let rect = CGRect(x: origin.x, y: origin.y, width: 34, height: 22)
    context.stroke(Path(roundedRect: rect, cornerRadius: 9), with: .color(color), lineWidth: 1.15)
    var tail = Path()
    tail.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY - 1))
    tail.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY + 8))
    tail.addLine(to: CGPoint(x: rect.minX + 16, y: rect.maxY))
    context.stroke(tail, with: .color(color), lineWidth: 1.15)
  }

  private func drawDoodleCamera(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    let body = CGRect(x: origin.x + 2, y: origin.y + 4, width: 36, height: 24)
    context.stroke(Path(roundedRect: body, cornerRadius: 6), with: .color(color), lineWidth: 1.15)
    context.stroke(
      Path(ellipseIn: CGRect(x: origin.x + 15, y: origin.y + 10, width: 10, height: 10)),
      with: .color(color), lineWidth: 1.15)
    context.fill(
      Path(
        roundedRect: CGRect(x: origin.x + 8, y: origin.y, width: 12, height: 5), cornerRadius: 2.5),
      with: .color(color.opacity(0.28)))
  }

  private func drawDoodleLock(in context: inout GraphicsContext, at origin: CGPoint, color: Color) {
    let body = CGRect(x: origin.x + 9, y: origin.y + 13, width: 22, height: 18)
    context.stroke(Path(roundedRect: body, cornerRadius: 4), with: .color(color), lineWidth: 1.15)
    var shackle = Path()
    shackle.move(to: CGPoint(x: origin.x + 14, y: origin.y + 14))
    shackle.addQuadCurve(
      to: CGPoint(x: origin.x + 26, y: origin.y + 14),
      control: CGPoint(x: origin.x + 20, y: origin.y + 3))
    context.stroke(shackle, with: .color(color), lineWidth: 1.15)
    context.fill(
      Path(ellipseIn: CGRect(x: origin.x + 19, y: origin.y + 20, width: 3, height: 3)),
      with: .color(color))
  }

  private func drawDoodleSpark(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    var star = Path()
    star.move(to: CGPoint(x: origin.x + 18, y: origin.y))
    star.addLine(to: CGPoint(x: origin.x + 22, y: origin.y + 14))
    star.addLine(to: CGPoint(x: origin.x + 36, y: origin.y + 18))
    star.addLine(to: CGPoint(x: origin.x + 22, y: origin.y + 22))
    star.addLine(to: CGPoint(x: origin.x + 18, y: origin.y + 36))
    star.addLine(to: CGPoint(x: origin.x + 14, y: origin.y + 22))
    star.addLine(to: CGPoint(x: origin.x, y: origin.y + 18))
    star.addLine(to: CGPoint(x: origin.x + 14, y: origin.y + 14))
    star.closeSubpath()
    context.stroke(star, with: .color(color), lineWidth: 1.05)
  }

  private func drawDoodlePhone(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    var phone = Path()
    phone.move(to: CGPoint(x: origin.x + 10, y: origin.y + 5))
    phone.addQuadCurve(
      to: CGPoint(x: origin.x + 30, y: origin.y + 25),
      control: CGPoint(x: origin.x + 8, y: origin.y + 27))
    phone.addQuadCurve(
      to: CGPoint(x: origin.x + 35, y: origin.y + 18),
      control: CGPoint(x: origin.x + 37, y: origin.y + 22))
    phone.move(to: CGPoint(x: origin.x + 11, y: origin.y + 5))
    phone.addQuadCurve(
      to: CGPoint(x: origin.x + 18, y: origin.y + 10),
      control: CGPoint(x: origin.x + 14, y: origin.y + 2))
    context.stroke(phone, with: .color(color), lineWidth: 1.4)
  }

  private func drawDoodlePlane(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    var plane = Path()
    plane.move(to: CGPoint(x: origin.x + 2, y: origin.y + 18))
    plane.addLine(to: CGPoint(x: origin.x + 39, y: origin.y + 5))
    plane.addLine(to: CGPoint(x: origin.x + 26, y: origin.y + 34))
    plane.addLine(to: CGPoint(x: origin.x + 18, y: origin.y + 22))
    plane.addLine(to: CGPoint(x: origin.x + 2, y: origin.y + 18))
    context.stroke(plane, with: .color(color), lineWidth: 1.15)
  }

  private func drawDoodleSmile(in context: inout GraphicsContext, at origin: CGPoint, color: Color)
  {
    let face = CGRect(x: origin.x + 3, y: origin.y + 1, width: 32, height: 32)
    context.stroke(Path(ellipseIn: face), with: .color(color), lineWidth: 1.1)
    context.fill(
      Path(ellipseIn: CGRect(x: origin.x + 12, y: origin.y + 12, width: 3, height: 3)),
      with: .color(color))
    context.fill(
      Path(ellipseIn: CGRect(x: origin.x + 25, y: origin.y + 12, width: 3, height: 3)),
      with: .color(color))
    var smile = Path()
    smile.move(to: CGPoint(x: origin.x + 13, y: origin.y + 22))
    smile.addQuadCurve(
      to: CGPoint(x: origin.x + 28, y: origin.y + 22),
      control: CGPoint(x: origin.x + 20, y: origin.y + 29))
    context.stroke(smile, with: .color(color), lineWidth: 1.1)
  }
}

extension Int {
  fileprivate func modulo(_ value: Int) -> Int {
    let remainder = self % value
    return remainder >= 0 ? remainder : remainder + value
  }
}
