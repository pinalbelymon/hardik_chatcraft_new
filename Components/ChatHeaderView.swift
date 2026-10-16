import SwiftUI
import UIKit

struct ChatHeaderView: View {
  let story: ChatStory
  let theme: ChatTheme
  var showsControls: Bool = true
  var cornerRadius: CGFloat = 0
  var roundedCorners: UIRectCorner = []
  var onBackTap: (() -> Void)? = nil

  @Environment(\.colorScheme) private var colorScheme

  @ViewBuilder
  var body: some View {
    if theme.isWhatsAppStyleTheme {
      midnightHeader
    } else if theme.isSocialMetaStyleTheme {
      socialBlueHeader
    } else if theme.isGradientDMStyleTheme {
      gradientDMHeader
    } else if theme.isPaperPlaneStyleTheme {
      paperPlaneHeader
    } else if theme.isSnapStyleTheme {
      snapHeader
    } else {
      standardHeader
    }
  }

  private var standardHeader: some View {
    HStack(spacing: theme.style.compactLayout ? AppSpacing.xs : AppSpacing.sm) {
      if onBackTap != nil {
        standardBackButton
      }

      avatar

      VStack(alignment: .leading, spacing: 2) {
        Text(primaryName)
          .font(theme.style.playfulBlocks ? .title3.weight(.heavy) : .headline.weight(.bold))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
        Text(primaryStatus)
          .font(.caption.weight(theme.style.playfulBlocks ? .bold : .regular))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: AppSpacing.sm)

      if showsControls {
        HStack(spacing: AppSpacing.sm) {
          ForEach(theme.headerActionIcons, id: \.self) { iconName in
            Image(systemName: iconName)
              .frame(width: 22, height: 22)
          }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color(hex: theme.style.accentHex))
      }
    }
    .padding(.horizontal, AppSpacing.md)
    .padding(.vertical, theme.style.compactLayout ? AppSpacing.xs : AppSpacing.sm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      .ultraThinMaterial,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
    .background(
      headerColor.opacity(0.82),
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(AppColors.hairline)
        .frame(height: 1)
    }
  }

  private var standardBackButton: some View {
    backActionWrapper {
      Image(systemName: "chevron.left")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(Color(hex: theme.style.accentHex))
        .frame(width: 38, height: 38)
        .background(Color(hex: theme.style.accentHex).opacity(0.12), in: Circle())
        .overlay(Circle().stroke(Color(hex: theme.style.accentHex).opacity(0.16), lineWidth: 1))
    }
  }

  private var midnightHeader: some View {
    HStack(spacing: AppSpacing.sm) {
      whatsAppBackButton
      avatar

      VStack(alignment: .leading, spacing: 2) {
        Text(primaryName)
          .font(.headline.weight(.bold))
          .foregroundStyle(whatsAppHeaderTitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        Text(primaryStatus)
          .font(.caption.weight(.medium))
          .foregroundStyle(whatsAppHeaderSubtitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.78)
      }

      Spacer(minLength: AppSpacing.xs)

      if showsControls {
        HStack(spacing: 20) {
          Image(systemName: "video")
                .font(.title2.weight(.semibold))
          Image(systemName: "phone")
            .font(.title2.weight(.semibold))
        }
        .foregroundStyle(whatsAppControlForeground)
        .frame(width: 100, height: 44)
        .background(whatsAppControlBackground, in: Capsule())
        .overlay(Capsule().stroke(whatsAppControlStroke, lineWidth: 1))
        .shadow(color: whatsAppControlShadow, radius: 7, y: 3)
      }
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, 7)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      whatsAppChromeColor,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
  }

  private var whatsAppBackButton: some View {
    backActionWrapper {
      Image(systemName: "chevron.left")
        .font(.title3.weight(.semibold))
        .foregroundStyle(whatsAppControlForeground)
        .frame(width: 40, height: 40)
        .background(whatsAppControlBackground, in: Circle())
        .overlay(Circle().stroke(whatsAppControlStroke, lineWidth: 1))
        .shadow(color: whatsAppControlShadow, radius: 6, y: 2)
    }
  }

  private var socialBlueHeader: some View {
    HStack(spacing: 10) {
      socialBlueBackButton
      socialAvatar

      Text(primaryName)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(socialBlueTitleColor)
        .lineLimit(1)
        .minimumScaleFactor(0.72)

      Spacer(minLength: AppSpacing.sm)

      if showsControls {
        HStack(spacing: 18) {
          Image(systemName: "phone.fill")
            .font(.system(size: 23, weight: .bold))
            .frame(width: 32, height: 36)
            Image("meta_video")
                .resizable()
                .scaledToFit()
             
              .frame(width: 28, height: 28)
        }
        .foregroundStyle(Color(hex: theme.style.accentHex))
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      socialBlueHeaderBackground,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(socialBlueDividerColor)
        .frame(height: 1)
    }
  }

  private var socialBlueBackButton: some View {
    backActionWrapper {
        Image(systemName: "chevron.left")
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(Color.blue)
            .frame(width: 24, height: 38)
    }
  }

  private var gradientDMHeader: some View {
    HStack(spacing: 8) {
      gradientDMBackButton
      gradientDMAvatar

      VStack(alignment: .leading, spacing: 2) {
        Text(primaryName)
          .font(.headline.weight(.heavy))
          .foregroundStyle(gradientDMTitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        Text(gradientDMStatusText)
          .font(.caption.weight(.medium))
          .foregroundStyle(gradientDMSubtitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.78)
      }

      Spacer(minLength: AppSpacing.xs)

      if showsControls {
        HStack(spacing: 8) {
          gradientDMHeaderCircleIcon("phone", size: 21)
          gradientDMHeaderCircleIcon("video", size: 22)
        }
      }
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      gradientDMHeaderBackground,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
  }

  private var gradientDMBackButton: some View {
    backActionWrapper {
      Image(systemName: "chevron.left")
        .font(.system(size: 23, weight: .medium))
        .foregroundStyle(gradientDMIconColor)
        .frame(width: 42, height: 42)
        .background(gradientDMCircleBackground, in: Circle())
        .overlay(Circle().stroke(gradientDMCircleStroke, lineWidth: 1))
    }
  }

  private func gradientDMHeaderCircleIcon(_ systemName: String, size: CGFloat) -> some View {
    Image(systemName: systemName)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(gradientDMIconColor)
      .frame(width: 40, height: 40)
      .background(gradientDMCircleBackground, in: Circle())
      .overlay(Circle().stroke(gradientDMCircleStroke, lineWidth: 1))
  }

  private var paperPlaneHeader: some View {
    HStack(spacing: 8) {
      paperPlaneBackControl

      Spacer(minLength: AppSpacing.xs)

        VStack(spacing: 0) {
        Text(primaryName)
              .font(.headline.weight(.bold))
          .foregroundStyle(paperPlaneTitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        Text(paperPlaneStatusText)
          .font(.caption.weight(.medium))
          .foregroundStyle(paperPlaneSubtitleColor)
          .lineLimit(1)
          .minimumScaleFactor(0.78)
      }
      .padding(.horizontal, 20)
      .frame(height: 44)
      .frame(maxWidth: 188)
      .background(paperPlaneControlBackground, in: Capsule())
      .overlay(Capsule().stroke(paperPlaneControlStroke, lineWidth: 1))

      Spacer(minLength: AppSpacing.xs)

      paperPlaneAvatar
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, 9)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      paperPlaneHeaderBackground,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
  }

  private var paperPlaneBackControl: some View {
    backActionWrapper {
      Image(systemName: "chevron.left")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(paperPlaneControlForeground)
        .frame(width: 40, height: 40)
        .background(paperPlaneControlBackground, in: Capsule())
        .overlay(Capsule().stroke(paperPlaneControlStroke, lineWidth: 1))
    }
  }

  private var snapHeader: some View {
    HStack(spacing: 10) {
      snapBackButton
      snapAvatar

      Text(primaryName)
        .font(.title3.weight(.heavy))
        .foregroundStyle(snapHeaderTitleColor)
        .lineLimit(1)
        .minimumScaleFactor(0.72)

      Spacer(minLength: AppSpacing.xs)

      if showsControls {
        HStack(spacing: 18) {
          Image(systemName: "phone.fill")
            .font(.system(size: 21, weight: .bold))
            .frame(width: 28, height: 32)
          Image(systemName: "video.fill")
            .font(.system(size: 22, weight: .bold))
            .frame(width: 28, height: 32)
        }
        .foregroundStyle(snapHeaderIconColor)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 7)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      snapHeaderBackground,
      in: RoundedCornerShape(radius: cornerRadius, corners: roundedCorners)
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(snapHeaderDividerColor)
        .frame(height: 1)
    }
  }

  private var snapBackButton: some View {
    backActionWrapper {
      Image(systemName: "chevron.left")
        .font(.system(size: 21, weight: .medium))
        .foregroundStyle(snapHeaderIconColor)
        .frame(width: 24, height: 38)
    }
  }

  @ViewBuilder
  private func backActionWrapper<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    if let onBackTap {
      Button(action: onBackTap) {
        content()
      }
      .buttonStyle(.plain)
    } else {
      content()
    }
  }

  private var avatar: some View {
    ZStack(alignment: .bottomTrailing) {
      Circle()
        .fill(Color(hex: theme.style.accentHex).opacity(0.16))
        .frame(width: avatarSize, height: avatarSize)
        .overlay {
          if let data = primaryCharacter?.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .clipShape(Circle())
          } else {
            Image(systemName: primaryCharacter?.avatarSymbol ?? "person.crop.circle")
              .font(.title3.weight(.bold))
              .foregroundStyle(Color(hex: theme.style.accentHex))
          }
        }

      if primaryCharacter?.isOnline == true && !theme.isWhatsAppStyleTheme {
        Circle()
          .fill(AppColors.success)
          .frame(width: 11, height: 11)
          .overlay(Circle().stroke(headerColor, lineWidth: 2))
      }
    }
  }

  private var socialAvatar: some View {
    Circle()
      .fill(socialBlueAvatarBackground)
      .frame(width: avatarSize, height: avatarSize)
      .overlay {
        if let data = primaryCharacter?.avatarImageData, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
        } else {
          Image(systemName: primaryCharacter?.avatarSymbol ?? "person.fill")
            .font(.headline.weight(.bold))
            .foregroundStyle(Color(hex: theme.style.accentHex))
        }
      }
  }

  private var gradientDMAvatar: some View {
    ZStack(alignment: .bottomTrailing) {
      Circle()
        .fill(socialBlueAvatarBackground)
        .frame(width: avatarSize, height: avatarSize)
        .overlay {
          if let data = primaryCharacter?.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .clipShape(Circle())
          } else {
            Image(systemName: primaryCharacter?.avatarSymbol ?? "person.fill")
              .font(.headline.weight(.bold))
              .foregroundStyle(Color(hex: theme.style.accentHex))
          }
        }

      if primaryCharacter?.isOnline == true {
        Circle()
          .fill(Color(hex: "#26D14F"))
          .frame(width: 10, height: 10)
          .overlay(Circle().stroke(gradientDMHeaderBackground, lineWidth: 2))
      }
    }
  }

  private var paperPlaneAvatar: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [Color(hex: "#FF6E6E"), Color(hex: "#FF8C4A")],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: 44, height: 44)
      .overlay {
        if let data = primaryCharacter?.avatarImageData, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
        } else {
          Text(primaryInitials)
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
        }
      }
      .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
  }

  private var snapAvatar: some View {
    ZStack(alignment: .bottomTrailing) {
      Circle()
        .fill(snapAvatarFill)
        .frame(width: 46, height: 46)
        .overlay {
          if let data = primaryCharacter?.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .clipShape(Circle())
          } else {
            Image(systemName: primaryCharacter?.avatarSymbol ?? "person.crop.circle.fill")
              .font(.headline.weight(.heavy))
              .foregroundStyle(snapAvatarIconColor)
          }
        }
        .overlay(Circle().stroke(snapAvatarStrokeColor, lineWidth: 1))

      if primaryCharacter?.isOnline == true {
        Circle()
          .fill(Color(hex: "#1FD15E"))
          .frame(width: 12, height: 12)
          .overlay(Circle().stroke(snapHeaderBackground, lineWidth: 2))
      }
    }
  }

  private var primaryCharacter: ChatCharacter? {
    story.characters.first(where: { $0.side == .left }) ?? story.characters.first
  }

  private var primaryName: String {
    primaryCharacter?.name ?? "Character"
  }

  private var primaryStatus: String {
    guard let character = primaryCharacter else { return "offline" }
    let status = character.statusText.trimmingCharacters(in: .whitespacesAndNewlines)
    return character.isOnline ? (status.isEmpty ? "online" : status) : "offline"
  }

  private var headerColor: Color {
    Color(hex: colorScheme == .dark ? theme.style.darkHeaderHex : theme.style.headerHex)
  }

  private var whatsAppChromeColor: Color {
    if isLightGreenWhatsApp {
      return Color(hex: theme.style.headerHex)
    }
    return Color(hex: "#111111")
  }

  private var isLightGreenWhatsApp: Bool {
    theme.id == "green-bubble" && colorScheme == .light
  }

  private var whatsAppHeaderTitleColor: Color {
    isLightGreenWhatsApp ? Color(hex: theme.style.incomingTextHex) : .white
  }

  private var whatsAppHeaderSubtitleColor: Color {
    isLightGreenWhatsApp ? Color(hex: "#5D7569") : .white.opacity(0.64)
  }

  private var whatsAppControlForeground: Color {
    isLightGreenWhatsApp ? Color(hex: "#111B21") : .white
  }

  private var whatsAppControlBackground: Color {
    isLightGreenWhatsApp ? Color.white.opacity(0.82) : Color(hex: "#1D1D1F").opacity(0.96)
  }

  private var whatsAppControlStroke: Color {
    isLightGreenWhatsApp ? Color.black.opacity(0.08) : Color.white.opacity(0.12)
  }

  private var whatsAppControlShadow: Color {
    isLightGreenWhatsApp ? Color.black.opacity(0.08) : Color.black.opacity(0.26)
  }

  private var whatsAppHeaderDivider: Color {
    isLightGreenWhatsApp ? Color(hex: theme.style.accentHex).opacity(0.14) : Color.white.opacity(0.05)
  }

  private var socialBlueHeaderBackground: Color {
    Color.white
  }

  private var socialBlueTitleColor: Color {
    Color(hex: "#050505")
  }

  private var socialBlueDividerColor: Color {
    Color(hex: "#E5E7EB")
  }

  private var socialBlueAvatarBackground: Color {
    colorScheme == .dark ? Color(hex: theme.style.accentHex).opacity(0.18) : Color(hex: "#EAF2FF")
  }

  private var gradientDMHeaderBackground: Color {
    colorScheme == .dark ? Color(hex: "#070A10") : Color.white
  }

  private var gradientDMTitleColor: Color {
    colorScheme == .dark ? .white.opacity(0.98) : Color(hex: "#111318")
  }

  private var gradientDMSubtitleColor: Color {
    colorScheme == .dark ? .white.opacity(0.76) : Color(hex: "#525866")
  }

  private var gradientDMIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.96) : Color(hex: "#111318")
  }

  private var gradientDMCircleBackground: Color {
    colorScheme == .dark ? Color.white.opacity(0.075) : Color.white.opacity(0.92)
  }

  private var gradientDMCircleStroke: Color {
    colorScheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.08)
  }

  private var gradientDMDividerColor: Color {
    colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.06)
  }

  private var gradientDMStatusText: String {
    guard primaryCharacter?.isOnline == true else { return "Offline" }
    let status = primaryCharacter?.statusText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return status.isEmpty || status.lowercased() == "online" ? "Active now" : status
  }

  private var snapHeaderBackground: Color {
    colorScheme == .dark ? Color(hex: "#070A10") : Color.white
  }

  private var snapHeaderTitleColor: Color {
    colorScheme == .dark ? .white.opacity(0.96) : Color(hex: "#111214")
  }

  private var snapHeaderIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.88) : Color(hex: "#3D4046")
  }

  private var snapHeaderDividerColor: Color {
    colorScheme == .dark ? .white.opacity(0.10) : Color(hex: "#D9DCE1")
  }

  private var snapAvatarFill: LinearGradient {
    LinearGradient(
      colors: colorScheme == .dark
        ? [Color(hex: "#222834"), Color(hex: "#111821")]
        : [Color(hex: "#FFF3C6"), Color(hex: "#E9F7FF")],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var snapAvatarIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "#2E333B")
  }

  private var snapAvatarStrokeColor: Color {
    colorScheme == .dark ? .white.opacity(0.10) : Color(hex: "#E5E7EB")
  }

  private var paperPlaneHeaderBackground: Color {
    colorScheme == .dark ? Color(hex: "#05060B").opacity(0.96) : Color(hex: theme.style.headerHex).opacity(0.86)
  }

  private var paperPlaneControlBackground: Color {
    colorScheme == .dark ? Color.white.opacity(0.11) : Color.white.opacity(0.64)
  }

  private var paperPlaneControlForeground: Color {
    colorScheme == .dark ? .white : Color(hex: "#111B21")
  }

  private var paperPlaneControlStroke: Color {
    colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.82)
  }

  private var paperPlaneTitleColor: Color {
    colorScheme == .dark ? .white : Color(hex: "#111B21")
  }

  private var paperPlaneSubtitleColor: Color {
    colorScheme == .dark ? .white.opacity(0.58) : Color(hex: "#465D48")
  }

  private var paperPlaneHeaderDividerColor: Color {
    colorScheme == .dark ? Color.white.opacity(0.10) : Color(hex: "#5F9461").opacity(0.12)
  }

  private var paperPlaneStatusText: String {
    let status = primaryStatus.trimmingCharacters(in: .whitespacesAndNewlines)
    if status.isEmpty || status.lowercased() == "online" {
      return "last seen recently"
    }
    return status
  }

  private var primaryInitials: String {
    let parts = primaryName.split(separator: " ").prefix(2)
    let letters = parts.compactMap { $0.first }.map(String.init).joined()
    return letters.isEmpty ? "PP" : letters.uppercased()
  }

  private var avatarSize: CGFloat {
    if theme.isWhatsAppStyleTheme {
      return 40
    }
    if theme.isSocialMetaStyleTheme {
      return 36
    }
    if theme.isGradientDMStyleTheme {
      return 38
    }
    return theme.style.playfulBlocks ? 48 : (theme.style.compactLayout ? 36 : 42)
  }
}
