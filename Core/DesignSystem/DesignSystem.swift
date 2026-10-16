import SwiftUI
import UIKit

enum AppSpacing {
  static let xxs: CGFloat = 4
  static let xs: CGFloat = 8
  static let sm: CGFloat = 12
  static let md: CGFloat = 16
  static let lg: CGFloat = 24
  static let xl: CGFloat = 32
  static let xxl: CGFloat = 44
}

enum AppRadius {
  static let sm: CGFloat = 8
  static let md: CGFloat = 14
  static let lg: CGFloat = 20
  static let xl: CGFloat = 28
  static let xxl: CGFloat = 36
}

enum DeviceSizeCategory {
  case compact
  case regular
  case large
  case iPad
}

struct DeviceSize {
  static func category(for width: CGFloat) -> DeviceSizeCategory {
    if UIDevice.current.userInterfaceIdiom == .pad { return .iPad }
    if width <= 360 { return .compact }
    if width >= 430 { return .large }
    return .regular
  }

  static func contentMaxWidth(for width: CGFloat) -> CGFloat {
    switch category(for: width) {
    case .compact, .regular, .large:
      return width
    case .iPad:
      return min(width, 920)
    }
  }

  static func chatBubbleMaxWidth(for width: CGFloat) -> CGFloat {
    switch category(for: width) {
    case .compact:
      return width * 0.76
    case .regular:
      return width * 0.72
    case .large:
      return width * 0.68
    case .iPad:
      return min(width * 0.56, 520)
    }
  }

  static func horizontalPadding(for width: CGFloat) -> CGFloat {
    switch category(for: width) {
    case .compact:
      return AppSpacing.sm
    case .regular:
      return AppSpacing.md
    case .large:
      return AppSpacing.lg
    case .iPad:
      return AppSpacing.xl
    }
  }

  static func isCompactScreen(width: CGFloat, height: CGFloat) -> Bool {
    UIDevice.current.userInterfaceIdiom != .pad && (width <= 375 || height <= 700)
  }

  static func isVeryCompactScreen(width: CGFloat, height: CGFloat) -> Bool {
    UIDevice.current.userInterfaceIdiom != .pad && (width <= 340 || height <= 620)
  }

  static func verticalPadding(for width: CGFloat, height: CGFloat) -> CGFloat {
    if UIDevice.current.userInterfaceIdiom == .pad { return AppSpacing.xl }
    if isVeryCompactScreen(width: width, height: height) { return AppSpacing.xs }
    if isCompactScreen(width: width, height: height) { return AppSpacing.sm }
    return AppSpacing.md
  }

  static func compactScale(width: CGFloat, height: CGFloat) -> CGFloat {
    if UIDevice.current.userInterfaceIdiom == .pad { return 1 }
    if isVeryCompactScreen(width: width, height: height) { return 0.84 }
    if isCompactScreen(width: width, height: height) { return 0.91 }
    return 1
  }

  static var currentScreenSize: CGSize {
    UIScreen.main.bounds.size
  }

  static var isCurrentCompactHeight: Bool {
    let width = min(currentScreenSize.width, currentScreenSize.height)
    let height = max(currentScreenSize.width, currentScreenSize.height)
    return isCompactScreen(width: width, height: height)
  }
}

enum AppFont {
  static func scale(for width: CGFloat) -> CGFloat {
    switch DeviceSize.category(for: width) {
    case .compact:
      return 0.9
    case .regular:
      return 1
    case .large:
      return 1.08
    case .iPad:
      return 1.16
    }
  }

  static func font(
    _ size: CGFloat,
    weight: Font.Weight = .regular,
    width: CGFloat = UIScreen.main.bounds.width,
    height: CGFloat? = nil
  ) -> Font {
    let heightScale = height.map { DeviceSize.compactScale(width: width, height: $0) } ?? 1
    return .system(size: size * scale(for: width) * heightScale, weight: weight, design: .rounded)
  }

  static func title(width: CGFloat) -> Font { font(28, weight: .bold, width: width) }
  static func sectionTitle(width: CGFloat) -> Font { font(18, weight: .semibold, width: width) }
  static func body(width: CGFloat) -> Font { font(16, weight: .regular, width: width) }
  static func caption(width: CGFloat) -> Font { font(12, weight: .medium, width: width) }
}

enum AppColors {
  static let appTint = Color(hex: "#2563EB")
  static let ink = Color(hex: "#111827")
  static let electricBlue = Color(hex: "#2563EB")
  static let mint = Color(hex: "#0F766E")
  static let coral = Color(hex: "#B45309")
  static let amber = Color(hex: "#B7791F")
  static let violet = Color(hex: "#475569")
  static let success = Color(hex: "#168A55")
  static let danger = Color(hex: "#DC2626")
  static let warning = Color(hex: "#B7791F")
  static let neutralBackground = Color(uiColor: .systemGroupedBackground)
  static let panelBackground = Color(uiColor: .secondarySystemGroupedBackground)
  static let hairline = Color(uiColor: .separator).opacity(0.35)

  static var brandGradient: LinearGradient {
    LinearGradient(
      colors: [Color(hex: "#2563EB"), Color(hex: "#0F766E")],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static var warmGradient: LinearGradient {
    LinearGradient(
      colors: [Color(hex: "#B7791F"), Color(hex: "#92400E")],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}

extension Color {
  init(hex: String) {
    let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: sanitized).scanHexInt64(&int)

    let red: UInt64
    let green: UInt64
    let blue: UInt64
    let alpha: UInt64

    switch sanitized.count {
    case 3:
      red = (int >> 8) * 17
      green = ((int >> 4) & 0xF) * 17
      blue = (int & 0xF) * 17
      alpha = 255
    case 6:
      red = int >> 16
      green = (int >> 8) & 0xFF
      blue = int & 0xFF
      alpha = 255
    case 8:
      red = int >> 24
      green = (int >> 16) & 0xFF
      blue = (int >> 8) & 0xFF
      alpha = int & 0xFF
    default:
      red = 79
      green = 124
      blue = 255
      alpha = 255
    }

    self.init(
      .sRGB,
      red: Double(red) / 255,
      green: Double(green) / 255,
      blue: Double(blue) / 255,
      opacity: Double(alpha) / 255
    )
  }

  func toHex() -> String {
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return String(
      format: "#%02lX%02lX%02lX",
      lroundf(Float(red * 255)),
      lroundf(Float(green * 255)),
      lroundf(Float(blue * 255))
    )
  }
}

extension View {
  func cardSurface(cornerRadius: CGFloat = AppRadius.lg) -> some View {
    padding(AppSpacing.md)
      .background(
        .regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(AppColors.hairline, lineWidth: 1)
      )
  }

  func responsiveFrame(maxWidth: CGFloat = 920) -> some View {
    frame(maxWidth: maxWidth)
      .frame(maxWidth: .infinity)
  }

  func premiumSurface(cornerRadius: CGFloat = AppRadius.xl, padding: CGFloat = AppSpacing.md)
    -> some View
  {
    self
      .padding(padding)
      .background(
        .regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(AppColors.hairline, lineWidth: 1)
      }
      .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
  }

  func interactiveLift() -> some View {
    buttonStyle(InteractiveScaleButtonStyle())
  }
}

struct InteractiveScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.965 : 1)
      .brightness(configuration.isPressed ? -0.035 : 0)
      .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
  }
}

struct RoundedCornerShape: Shape {
  var radius: CGFloat
  var corners: UIRectCorner

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

struct PremiumBackdrop: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      LinearGradient(
        colors: colorScheme == .dark
          ? [Color(hex: "#111315"), Color(hex: "#171A1D"), Color(hex: "#1B1A18")]
          : [Color(hex: "#F8FAFC"), Color(hex: "#F3F6F8"), Color(hex: "#F8F7F4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Canvas { context, size in
        let lineColor =
          colorScheme == .dark ? Color.white.opacity(0.025) : Color.black.opacity(0.025)
        for offset in stride(from: -size.height, through: size.width, by: 44) {
          var path = Path()
          path.move(to: CGPoint(x: offset, y: 0))
          path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
          context.stroke(path, with: .color(lineColor), lineWidth: 1)
        }
      }
      .blendMode(.overlay)
    }
    .ignoresSafeArea()
  }
}

struct SectionTitleRow: View {
  let title: String
  var count: Int?
  var actionTitle: String?
  var action: (() -> Void)?

  var body: some View {
    HStack(spacing: AppSpacing.sm) {
      Text(title)
        .font(.headline.weight(.heavy))
      if let count {
        Text("\(count)")
          .font(.caption.weight(.bold))
          .foregroundStyle(AppColors.appTint)
          .padding(.horizontal, AppSpacing.xs)
          .padding(.vertical, 4)
          .background(AppColors.appTint.opacity(0.12), in: Capsule())
      }
      Spacer()
      if let actionTitle, let action {
        Button(actionTitle, action: action)
          .font(.caption.weight(.bold))
          .foregroundStyle(AppColors.appTint)
          .buttonStyle(.plain)
      }
    }
  }
}

struct PremiumStatChip: View {
  let iconName: String
  let value: String
  let title: String
  var tint: Color = AppColors.appTint

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      Image(systemName: iconName)
        .font(.caption.weight(.bold))
        .frame(width: 26, height: 26)
        .foregroundStyle(.white)
        .background(tint, in: Circle())

      VStack(alignment: .leading, spacing: 1) {
        Text(value)
          .font(.subheadline.weight(.heavy))
          .lineLimit(1)
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, AppSpacing.xs)
    .background(.thinMaterial, in: Capsule())
    .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
  }
}

struct ResponsiveViewModifier: ViewModifier {
  let maxWidth: CGFloat

  func body(content: Content) -> some View {
    GeometryReader { geometry in
      ScrollView {
        content
          .padding(.horizontal, DeviceSize.horizontalPadding(for: geometry.size.width))
          .padding(.vertical, AppSpacing.md)
          .frame(maxWidth: min(maxWidth, geometry.size.width), alignment: .top)
          .frame(maxWidth: .infinity)
      }
    }
  }
}

extension View {
  func responsiveScreen(maxWidth: CGFloat = 920) -> some View {
    modifier(ResponsiveViewModifier(maxWidth: maxWidth))
  }
}


enum AppLegalLinks {
  static let termsOfUse = URL(string: "https://belymoninfotech.com/app/chatcraft/termsofuse.html")!
  static let privacyPolicy = URL(string: "https://belymoninfotech.com/app/chatcraft/privacypolicy.html")!
  static let eula = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}


enum AppStoreLinks {
  static let writeReview = URL(string: "https://apps.apple.com/app/id6786126568?action=write-review")!
}
