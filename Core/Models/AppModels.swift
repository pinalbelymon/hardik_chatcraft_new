import CoreGraphics
import Foundation

enum SenderSide: String, Codable, CaseIterable, Identifiable {
  case left
  case right

  var id: String { rawValue }
  var title: String { self == .left ? "Left" : "Right" }
}

enum StoryFormat: String, Codable, CaseIterable, Identifiable {
  case normalChat
  case storyPlayback
  case exportReady

  var id: String { rawValue }

  var title: String {
    switch self {
    case .normalChat: return "Normal Chat"
    case .storyPlayback: return "Story Playback"
    case .exportReady: return "Export Ready"
    }
  }

  var iconName: String {
    switch self {
    case .normalChat: return "bubble.left.and.bubble.right.fill"
    case .storyPlayback: return "play.rectangle.fill"
    case .exportReady: return "rectangle.portrait.and.arrow.right.fill"
    }
  }

  var description: String {
    switch self {
    case .normalChat: return "Best for normal fake chat screenshots."
    case .storyPlayback: return "Reveal messages one by one for stories."
    case .exportReady: return "Optimized for reels, shorts, and posts."
    }
  }
}

enum MessageType: String, Codable, CaseIterable, Identifiable {
  case text
  case image
  case video
  case voice
  case typingIndicator
  case timestamp
  case reaction
  case missedCall
  case system
  case sticker

  var id: String { rawValue }

  var title: String {
    switch self {
    case .text: return "Text"
    case .image: return "Image"
    case .video: return "Video"
    case .voice: return "Voice"
    case .typingIndicator: return "Typing"
    case .timestamp: return "Date Separator"
    case .reaction: return "Reaction"
    case .missedCall: return "Missed Call"
    case .system: return "System"
    case .sticker: return "Sticker"
    }
  }

  var iconName: String {
    switch self {
    case .text: return "text.bubble"
    case .image: return "photo"
    case .video: return "video"
    case .voice: return "waveform"
    case .typingIndicator: return "ellipsis.message"
    case .timestamp: return "calendar"
    case .reaction: return "face.smiling"
    case .missedCall: return "phone.down"
    case .system: return "info.circle"
    case .sticker: return "star"
    }
  }

  var feature: FeatureAccess {
    switch self {
    case .text: return .textMessages
    case .image: return .imageMessages
    case .video: return .videoMessages
    case .voice: return .voiceMessages
    case .typingIndicator: return .typingIndicators
    case .timestamp: return .dateSeparators
    case .reaction: return .messageReactions
    case .missedCall: return .missedCallMessages
    case .system: return .systemMessages
    case .sticker: return .stickerMessages
    }
  }
}

enum ReadReceiptStatus: String, Codable, CaseIterable, Identifiable {
  case none
  case delivered
  case seen
  case read

  var id: String { rawValue }

  var title: String {
    switch self {
    case .none: return "None"
    case .delivered: return "Delivered"
    case .seen: return "Seen"
    case .read: return "Read"
    }
  }

  var shortLabel: String {
    switch self {
    case .none: return ""
    case .delivered: return "Delivered"
    case .seen: return "Seen"
    case .read: return "Read"
    }
  }
}

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
  case vertical916
  case square11
  case portrait45

  var id: String { rawValue }

  var title: String {
    switch self {
    case .vertical916: return "9:16 Vertical"
    case .square11: return "1:1 Square"
    case .portrait45: return "4:5 Portrait"
    }
  }

  var sizeLabel: String {
    switch self {
    case .vertical916: return "1080 x 1920"
    case .square11: return "1080 x 1080"
    case .portrait45: return "1080 x 1350"
    }
  }

  var aspectRatio: CGFloat {
    switch self {
    case .vertical916: return 9.0 / 16.0
    case .square11: return 1.0
    case .portrait45: return 4.0 / 5.0
    }
  }
}

enum UserPlan: String, Codable, CaseIterable, Identifiable, Comparable {
  case free
  case lite
  case pro

  var id: String { rawValue }

  var title: String {
    switch self {
    case .free: return "Free"
    case .lite: return "Lite"
    case .pro: return "Pro"
    }
  }

  var badgeTitle: String { title }

  var rank: Int {
    switch self {
    case .free: return 0
    case .lite: return 1
    case .pro: return 2
    }
  }

  static func < (lhs: UserPlan, rhs: UserPlan) -> Bool {
    lhs.rank < rhs.rank
  }
}

struct SubscriptionOption: Identifiable, Hashable {
  let id = UUID()
  let plan: UserPlan
  let cadence: String
  let price: String
  let badge: String?
}

enum FeatureAccess: String, CaseIterable, Identifiable {
  case unlimitedStories
  case unlimitedCharacters
  case textMessages
  case imageMessages
  case videoMessages
  case voiceMessages
  case typingIndicators
  case dateSeparators
  case messageReactions
  case missedCallMessages
  case systemMessages
  case stickerMessages
  case autoplay
  case adjustablePlaybackSpeed
  case premiumAnimations
  case screenshotExport
  case videoExport
  case watermarkRemoval
  case customThemes
  case premiumThemes
  case allExportFormats

  var id: String { rawValue }

  var title: String {
    switch self {
    case .unlimitedStories: return "Unlimited stories"
    case .unlimitedCharacters: return "Unlimited characters"
    case .textMessages: return "Text messages"
    case .imageMessages: return "Image messages"
    case .videoMessages: return "Video messages"
    case .voiceMessages: return "Voice message bubbles"
    case .typingIndicators: return "Typing indicators"
    case .dateSeparators: return "Date separators"
    case .messageReactions: return "Message reactions"
    case .missedCallMessages: return "Missed call messages"
    case .systemMessages: return "System messages"
    case .stickerMessages: return "Sticker messages"
    case .autoplay: return "Auto-play preview"
    case .adjustablePlaybackSpeed: return "Adjustable playback speed"
    case .premiumAnimations: return "Premium animations"
    case .screenshotExport: return "Screenshot export"
    case .videoExport: return "Vertical video export"
    case .watermarkRemoval: return "Remove watermark"
    case .customThemes: return "Custom Theme Builder"
    case .premiumThemes: return "Premium themes"
    case .allExportFormats: return "All export formats"
    }
  }
}

enum ChatThemeCategory: String, Codable, CaseIterable, Identifiable {
  case basic
  case social
  case premium
  case dark
  case custom

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

struct ChatThemeStyle: Codable, Hashable {
  var backgroundHex: String
  var darkBackgroundHex: String
  var wallpaperAccentHex: String
  var incomingBubbleHex: String
  var outgoingBubbleHex: String
  var incomingDarkBubbleHex: String
  var outgoingDarkBubbleHex: String
  var incomingTextHex: String
  var outgoingTextHex: String
  var accentHex: String
  var headerHex: String
  var darkHeaderHex: String
  var inputBarHex: String
  var darkInputBarHex: String
  var dateSeparatorHex: String
  var bubbleCornerRadius: Double
  var fontSizeAdjustment: Double
  var showAvatars: Bool
  var hasMessageTail: Bool
  var usesGradientOutgoing: Bool
  var glowOutgoing: Bool
  var playfulBlocks: Bool
  var compactLayout: Bool
}

struct ChatTheme: Identifiable, Codable, Hashable {
  var id: String
  var name: String
  var category: ChatThemeCategory
  var requiredPlan: UserPlan
  var style: ChatThemeStyle
  var isCustom: Bool

  var subtitle: String {
    switch id {
    case "blue-bubble":
      return "Apple Messages-style blue bubbles"
    case "green-bubble":
      return "WhatsApp-style chat"
    case "midnight-doodle":
      return "WhatsApp-style chat"
    case "social-blue":
      return "Facebook Messenger-style chat"
    case "paper-plane":
      return "Telegram-style compact chat"
    case "snap-style":
      return "Snapchat-style story chat"
    case "dark-neon":
      return "Discord-style dark chat"
    case "minimal-white":
      return "SMS-style minimal chat"
    case "creator-dark":
      return "Creator-focused dark chat"
    case "candy-pop":
      return "Pastel emoji chat style"
    case "gradient-bubble":
      return "Instagram-style DM chat"
    case "custom-theme":
      return "Build your own chat look"
    default:
      switch category {
      case .basic: return "Clean everyday chat layout"
      case .social: return "Bright, social, reaction-ready"
      case .premium: return "Creator-ready premium styling"
      case .dark: return "High-contrast dark storytelling"
      case .custom: return "Build your own chat look"
      }
    }
  }

  static let defaultThemeID = "blue-bubble"

  static var fallback: ChatTheme {
    all.first { $0.id == defaultThemeID } ?? all[0]
  }

  static func normalizedID(for id: String) -> String {
    switch id {
    case "midnight-doodle":
      return "green-bubble"
    default:
      return id
    }
  }

  static func theme(for id: String) -> ChatTheme {
    all.first { $0.id == normalizedID(for: id) } ?? fallback
  }

  static let all: [ChatTheme] = [
    ChatTheme(
      id: "blue-bubble",
      name: "Apple Messages Chat",
      category: .basic,
      requiredPlan: .free,
      style: ChatThemeStyle(
        backgroundHex: "#F7F9FC",
        darkBackgroundHex: "#101318",
        wallpaperAccentHex: "#D8E7FF",
        incomingBubbleHex: "#E9ECF2",
        outgoingBubbleHex: "#198CFF",
        incomingDarkBubbleHex: "#252A33",
        outgoingDarkBubbleHex: "#147BFF",
        incomingTextHex: "#141820",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#198CFF",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#171B22",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#1C212A",
        dateSeparatorHex: "#8E97A6",
        bubbleCornerRadius: 22,
        fontSizeAdjustment: 0,
        showAvatars: false,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "green-bubble",
      name: "WhatsApp Chat",
      category: .basic,
      requiredPlan: .free,
      style: ChatThemeStyle(
        backgroundHex: "#F3EEE5",
        darkBackgroundHex: "#101B17",
        wallpaperAccentHex: "#D9D0C2",
        incomingBubbleHex: "#FFFFFF",
        outgoingBubbleHex: "#D9FDD3",
        incomingDarkBubbleHex: "#1F2925",
        outgoingDarkBubbleHex: "#165D3B",
        incomingTextHex: "#111B21",
        outgoingTextHex: "#111B21",
        accentHex: "#00A884",
        headerHex: "#F7F1E8",
        darkHeaderHex: "#13211B",
        inputBarHex: "#F7F1E8",
        darkInputBarHex: "#1A2721",
        dateSeparatorHex: "#7A8D84",
        bubbleCornerRadius: 18,
        fontSizeAdjustment: -0.5,
        showAvatars: false,
        hasMessageTail: true,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: true
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "social-blue",
      name: "Facebook Messenger Chat",
      category: .social,
      requiredPlan: .lite,
      style: ChatThemeStyle(
        backgroundHex: "#FFFFFF",
        darkBackgroundHex: "#FFFFFF",
        wallpaperAccentHex: "#FFFFFF",
        incomingBubbleHex: "#F0F2F5",
        outgoingBubbleHex: "#0084FF",
        incomingDarkBubbleHex: "#F0F2F5",
        outgoingDarkBubbleHex: "#0068f9",
        incomingTextHex: "#050505",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#0068f9",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#FFFFFF",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#FFFFFF",
        dateSeparatorHex: "#65676B",
        bubbleCornerRadius: 18,
        fontSizeAdjustment: 0,
        showAvatars: true,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: true
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "paper-plane",
      name: "Telegram Chat",
      category: .social,
      requiredPlan: .lite,
      style: ChatThemeStyle(
        backgroundHex: "#BFE8A8",
        darkBackgroundHex: "#02030B",
        wallpaperAccentHex: "#5F9461",
        incomingBubbleHex: "#F3F7EF",
        outgoingBubbleHex: "#E2FFD1",
        incomingDarkBubbleHex: "#262733",
        outgoingDarkBubbleHex: "#4E63FF",
        incomingTextHex: "#111B21",
        outgoingTextHex: "#111B21",
        accentHex: "#4E8F4C",
        headerHex: "#E7F7DC",
        darkHeaderHex: "#080910",
        inputBarHex: "#EAF9DF",
        darkInputBarHex: "#111217",
        dateSeparatorHex: "#577A59",
        bubbleCornerRadius: 16,
        fontSizeAdjustment: 0,
        showAvatars: false,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: true
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "snap-style",
      name: "Snapchat Chat",
      category: .premium,
      requiredPlan: .pro,
      style: ChatThemeStyle(
        backgroundHex: "#FFFFFF",
        darkBackgroundHex: "#070A10",
        wallpaperAccentHex: "#F4F5F6",
        incomingBubbleHex: "#FFFFFF",
        outgoingBubbleHex: "#FFFFFF",
        incomingDarkBubbleHex: "#070A10",
        outgoingDarkBubbleHex: "#070A10",
        incomingTextHex: "#151515",
        outgoingTextHex: "#111111",
        accentHex: "#E83463",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#070A10",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#070A10",
        dateSeparatorHex: "#A8ADB4",
        bubbleCornerRadius: 0,
        fontSizeAdjustment: 0,
        showAvatars: false,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: true,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "dark-neon",
      name: "Discord Dark Chat",
      category: .dark,
      requiredPlan: .pro,
      style: ChatThemeStyle(
        backgroundHex: "#090A14",
        darkBackgroundHex: "#090A14",
        wallpaperAccentHex: "#7C3DFF",
        incomingBubbleHex: "#222534",
        outgoingBubbleHex: "#9B5CFF",
        incomingDarkBubbleHex: "#222534",
        outgoingDarkBubbleHex: "#9B5CFF",
        incomingTextHex: "#F4F5FF",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#00E6FF",
        headerHex: "#10111F",
        darkHeaderHex: "#10111F",
        inputBarHex: "#17192A",
        darkInputBarHex: "#17192A",
        dateSeparatorHex: "#9298FF",
        bubbleCornerRadius: 24,
        fontSizeAdjustment: 0.5,
        showAvatars: true,
        hasMessageTail: false,
        usesGradientOutgoing: true,
        glowOutgoing: true,
        playfulBlocks: false,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "minimal-white",
      name: "SMS Messages",
      category: .basic,
      requiredPlan: .lite,
      style: ChatThemeStyle(
        backgroundHex: "#FFFFFF",
        darkBackgroundHex: "#111111",
        wallpaperAccentHex: "#E9E9E9",
        incomingBubbleHex: "#F5F5F5",
        outgoingBubbleHex: "#111111",
        incomingDarkBubbleHex: "#202020",
        outgoingDarkBubbleHex: "#F4F4F4",
        incomingTextHex: "#111111",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#111111",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#151515",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#1B1B1B",
        dateSeparatorHex: "#9B9B9B",
        bubbleCornerRadius: 14,
        fontSizeAdjustment: 0,
        showAvatars: false,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: true
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "creator-dark",
      name: "Creator Dark Chat",
      category: .dark,
      requiredPlan: .pro,
      style: ChatThemeStyle(
        backgroundHex: "#0D0F12",
        darkBackgroundHex: "#0D0F12",
        wallpaperAccentHex: "#2D3644",
        incomingBubbleHex: "#23272F",
        outgoingBubbleHex: "#EAF0FF",
        incomingDarkBubbleHex: "#23272F",
        outgoingDarkBubbleHex: "#EAF0FF",
        incomingTextHex: "#F2F4F7",
        outgoingTextHex: "#0E1116",
        accentHex: "#7DD3FC",
        headerHex: "#14181F",
        darkHeaderHex: "#14181F",
        inputBarHex: "#181D25",
        darkInputBarHex: "#181D25",
        dateSeparatorHex: "#9AA6B2",
        bubbleCornerRadius: 18,
        fontSizeAdjustment: 1.5,
        showAvatars: true,
        hasMessageTail: false,
        usesGradientOutgoing: false,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "candy-pop",
      name: "Candy Pop Chat",
      category: .premium,
      requiredPlan: .pro,
      style: ChatThemeStyle(
        backgroundHex: "#FFF0F8",
        darkBackgroundHex: "#231521",
        wallpaperAccentHex: "#FFC7E8",
        incomingBubbleHex: "#FFFFFF",
        outgoingBubbleHex: "#FF7AC8",
        incomingDarkBubbleHex: "#352536",
        outgoingDarkBubbleHex: "#FF75C2",
        incomingTextHex: "#3A2034",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#7C5CFF",
        headerHex: "#FFF8FC",
        darkHeaderHex: "#2B1C2B",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#342338",
        dateSeparatorHex: "#B67DA1",
        bubbleCornerRadius: 25,
        fontSizeAdjustment: 0.5,
        showAvatars: true,
        hasMessageTail: false,
        usesGradientOutgoing: true,
        glowOutgoing: false,
        playfulBlocks: true,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "gradient-bubble",
      name: "Instagram Chat",
      category: .social,
      requiredPlan: .lite,
      style: ChatThemeStyle(
        backgroundHex: "#FFFFFF",
        darkBackgroundHex: "#070A10",
        wallpaperAccentHex: "#FFFFFF",
        incomingBubbleHex: "#F0F1F5",
        outgoingBubbleHex: "#7B39FF",
        incomingDarkBubbleHex: "#23272E",
        outgoingDarkBubbleHex: "#7B39FF",
        incomingTextHex: "#111318",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#B938FF",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#070A10",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#171B22",
        dateSeparatorHex: "#9CA3AF",
        bubbleCornerRadius: 23,
        fontSizeAdjustment: 0,
        showAvatars: true,
        hasMessageTail: false,
        usesGradientOutgoing: true,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: false
      ),
      isCustom: false
    ),
    ChatTheme(
      id: "custom-theme",
      name: "Custom Theme Builder",
      category: .custom,
      requiredPlan: .pro,
      style: ChatThemeStyle(
        backgroundHex: "#F7F7FB",
        darkBackgroundHex: "#121217",
        wallpaperAccentHex: "#C9D6FF",
        incomingBubbleHex: "#EFEFF4",
        outgoingBubbleHex: "#4F7CFF",
        incomingDarkBubbleHex: "#24242B",
        outgoingDarkBubbleHex: "#4F7CFF",
        incomingTextHex: "#151515",
        outgoingTextHex: "#FFFFFF",
        accentHex: "#4F7CFF",
        headerHex: "#FFFFFF",
        darkHeaderHex: "#181820",
        inputBarHex: "#FFFFFF",
        darkInputBarHex: "#20202A",
        dateSeparatorHex: "#8E8E99",
        bubbleCornerRadius: 22,
        fontSizeAdjustment: 0,
        showAvatars: true,
        hasMessageTail: true,
        usesGradientOutgoing: true,
        glowOutgoing: false,
        playfulBlocks: false,
        compactLayout: false
      ),
      isCustom: true
    ),
  ]
}

enum ChatReceiptPresentation {
  case textLabel
  case doubleCheck
  case seenBubble
  case compact
  case neon
}

extension ChatTheme {
  var headerActionIcons: [String] {
    switch id {
    case "blue-bubble":
      return ["video", "phone", "ellipsis"]
    case "green-bubble", "midnight-doodle":
      return ["video", "phone"]
    case "social-blue":
      return ["phone.fill", "video.fill"]
    case "paper-plane":
      return ["paperclip", "mic.fill", "face.smiling"]
    case "snap-style":
      return ["phone.fill", "video.fill"]
    case "dark-neon":
      return ["bolt.fill", "waveform", "ellipsis"]
    case "minimal-white":
      return ["magnifyingglass", "ellipsis"]
    case "creator-dark":
      return ["record.circle", "square.and.arrow.up", "ellipsis"]
    case "candy-pop":
      return ["heart.fill", "face.smiling.fill", "ellipsis"]
    default:
      return ["phone", "video", "ellipsis"]
    }
  }

  var inputLeadingIcon: String? {
    switch id {
    case "blue-bubble":
      return "plus.circle"
    case "green-bubble", "midnight-doodle":
      return "plus"
    case "social-blue":
      return nil
    case "paper-plane":
      return "paperclip"
    case "snap-style":
      return "camera.fill"
    case "dark-neon":
      return "plus.circle.fill"
    case "minimal-white":
      return nil
    case "creator-dark":
      return "slider.horizontal.3"
    case "candy-pop":
      return "plus.circle.fill"
    default:
      return "plus.circle.fill"
    }
  }

  var inputTrailingIcons: [String] {
    switch id {
    case "blue-bubble":
      return ["camera", "mic.fill"]
    case "green-bubble", "midnight-doodle":
      return ["indianrupeesign.circle", "camera.fill", "mic.fill"]
    case "social-blue":
      return ["face.smiling.fill", "camera.fill", "mic.fill"]
    case "paper-plane":
      return ["face.smiling", "mic.fill"]
    case "snap-style":
      return ["mic.fill", "face.smiling", "photo.on.rectangle", "gamecontroller"]
    case "dark-neon":
      return ["waveform", "paperplane.fill"]
    case "minimal-white":
      return ["paperplane"]
    case "creator-dark":
      return ["waveform", "arrow.up.circle.fill"]
    case "candy-pop":
      return ["heart.fill", "camera.fill"]
    default:
      return ["camera", "mic.fill"]
    }
  }

  var inputPlaceholder: String {
    switch id {
    case "midnight-doodle":
      return "Message"
    case "snap-style":
      return "Send chat"
    case "dark-neon":
      return "Transmit message"
    case "creator-dark":
      return "Write scene dialogue"
    case "minimal-white":
      return "Write a message"
    default:
      return "Message"
    }
  }

  var usesInlineMessageMeta: Bool {
    id == "green-bubble" || id == "midnight-doodle" || id == "paper-plane"
  }

  var usesCompactMessengerLayout: Bool {
    isWhatsAppStyleTheme || isPaperPlaneStyleTheme
  }

  var usesThemeBubbleColors: Bool {
    isWhatsAppStyleTheme || isSocialMetaStyleTheme || isGradientDMStyleTheme
      || isPaperPlaneStyleTheme
  }

  var isWhatsAppStyleTheme: Bool {
    id == "green-bubble" || id == "midnight-doodle"
  }

  var isSocialMetaStyleTheme: Bool {
    id == "social-blue"
  }

  var isGradientDMStyleTheme: Bool {
    id == "gradient-bubble"
  }

  var isPaperPlaneStyleTheme: Bool {
    id == "paper-plane"
  }

  var isSnapStyleTheme: Bool {
    id == "snap-style"
  }

    var compactMessageSpacing: CGFloat {
        if isWhatsAppStyleTheme {
            return 6
        }
        if isSocialMetaStyleTheme {
            return 2
        }
        if isGradientDMStyleTheme {
            return 4
        }
        if isPaperPlaneStyleTheme {
            return 2
        }
        if isSnapStyleTheme {
            return 0
        }
        return AppSpacing.sm
    }

  var usesFloatingInputBar: Bool {
    id == "social-blue" || id == "gradient-bubble" || id == "paper-plane" || id == "dark-neon" || id == "candy-pop"
  }

  var receiptPresentation: ChatReceiptPresentation {
    switch id {
    case "green-bubble", "midnight-doodle", "paper-plane":
      return .doubleCheck
    case "social-blue", "candy-pop":
      return .seenBubble
    case "dark-neon":
      return .neon
    case "minimal-white":
      return .compact
    default:
      return .textLabel
    }
  }

  var bubbleBorderOpacity: Double {
    switch id {
    case "midnight-doodle":
      return 0.08
    case "minimal-white":
      return 0.18
    case "creator-dark", "dark-neon":
      return 0.12
    default:
      return 0
    }
  }

  var chatCornerRadius: CGFloat {
    switch id {
    case "green-bubble", "midnight-doodle":
      return 0
    case "creator-dark":
      return 18
    case "minimal-white":
      return 20
    case "snap-style", "candy-pop":
      return 34
    default:
      return 28
    }
  }
}

struct ChatCharacter: Identifiable, Codable, Hashable {
  var id: UUID
  var name: String
  var avatarSymbol: String
  var avatarImageData: Data?
  var bubbleColorHex: String
  var textColorHex: String
  var customBubbleColorHex: String?
  var customTextColorHex: String?
  var side: SenderSide
  var isOnline: Bool
  var statusText: String

  init(
    id: UUID = UUID(),
    name: String,
    avatarSymbol: String,
    avatarImageData: Data? = nil,
    bubbleColorHex: String,
    textColorHex: String = "#FFFFFF",
    customBubbleColorHex: String? = nil,
    customTextColorHex: String? = nil,
    side: SenderSide,
    isOnline: Bool = true,
    statusText: String = "online"
  ) {
    self.id = id
    self.name = name
    self.avatarSymbol = avatarSymbol
    self.avatarImageData = avatarImageData
    self.bubbleColorHex = bubbleColorHex
    self.textColorHex = textColorHex
    self.customBubbleColorHex = customBubbleColorHex
    self.customTextColorHex = customTextColorHex
    self.side = side
    self.isOnline = isOnline
    self.statusText = statusText
  }

  static let avatarSymbols = [
    "person.crop.circle", "sparkles", "heart.circle", "bolt.circle", "moon.circle", "star.circle",
    "crown", "face.smiling",
  ]
}

struct ChatMessage: Identifiable, Codable, Hashable {
  var id: UUID
  var characterID: UUID
  var type: MessageType
  var text: String
  var mediaData: Data?
  var createdAt: Date
  var displayTime: String
  var readReceipt: ReadReceiptStatus
  var typingDelay: Double
  var reaction: String
  var isDelivered: Bool
  var isSeen: Bool

  init(
    id: UUID = UUID(),
    characterID: UUID,
    type: MessageType = .text,
    text: String,
    mediaData: Data? = nil,
    createdAt: Date = Date(),
    displayTime: String = ChatMessage.defaultTimeString(),
    readReceipt: ReadReceiptStatus = .none,
    typingDelay: Double = 0.8,
    reaction: String = "",
    isDelivered: Bool = true,
    isSeen: Bool = false
  ) {
    self.id = id
    self.characterID = characterID
    self.type = type
    self.text = text
    self.mediaData = mediaData
    self.createdAt = createdAt
    self.displayTime = displayTime
    self.readReceipt = readReceipt
    self.typingDelay = typingDelay
    self.reaction = reaction
    self.isDelivered = isDelivered
    self.isSeen = isSeen
  }

  static func defaultTimeString(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  var participatesInBubbleGroup: Bool {
    switch type {
    case .text, .image, .video, .voice, .typingIndicator, .reaction, .missedCall, .sticker:
      return true
    case .timestamp, .system:
      return false
    }
  }

  func isGroupedWith(_ other: ChatMessage) -> Bool {
    characterID == other.characterID && participatesInBubbleGroup && other.participatesInBubbleGroup
  }
}

struct ChatStory: Identifiable, Codable, Hashable {
  var id: UUID
  var title: String
  var themeID: String
  var customThemeStyle: ChatThemeStyle?
  var characters: [ChatCharacter]
  var messages: [ChatMessage]
  var format: StoryFormat
  var exportFormat: ExportFormat
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    title: String,
    themeID: String = ChatTheme.defaultThemeID,
    customThemeStyle: ChatThemeStyle? = nil,
    characters: [ChatCharacter],
    messages: [ChatMessage] = [],
    format: StoryFormat = .normalChat,
    exportFormat: ExportFormat = .vertical916,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.themeID = themeID
    self.customThemeStyle = customThemeStyle
    self.characters = characters
    self.messages = messages
    self.format = format
    self.exportFormat = exportFormat
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  var theme: ChatTheme {
    var base = ChatTheme.theme(for: themeID)
    if base.isCustom, let customThemeStyle {
      base.style = customThemeStyle
    }
    return base
  }
}
