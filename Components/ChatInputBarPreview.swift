import SwiftUI
import UIKit

struct ChatInputBarPreview: View {
  let theme: ChatTheme
  var placeholder: String = "Message"
  var roundedCorners: UIRectCorner = .allCorners
  var cornerRadius: CGFloat?
  var isDockedInChatFrame = false

  @Environment(\.colorScheme) private var colorScheme

  @ViewBuilder
  var body: some View {
    if theme.isWhatsAppStyleTheme {
      midnightInputBar
    } else if theme.isSocialMetaStyleTheme {
      socialBlueInputBar
    } else if theme.isGradientDMStyleTheme {
      gradientDMInputBar
    } else if theme.isPaperPlaneStyleTheme {
      paperPlaneInputBar
    } else if theme.isSnapStyleTheme {
      snapInputBar
    } else {
      standardInputBar
    }
  }

  private var standardInputBar: some View {
    HStack(spacing: AppSpacing.sm) {
      if let inputLeadingIcon = theme.inputLeadingIcon {
        Image(systemName: inputLeadingIcon)
          .frame(width: 28, height: 28)
      }

      HStack {
        Text(placeholder == "Message" ? theme.inputPlaceholder : placeholder)
          .font(.callout)
          .foregroundStyle(.secondary)
        Spacer()
        if theme.id == "social-blue" {
          Image(systemName: "hand.thumbsup.fill")
            .foregroundStyle(Color(hex: theme.style.accentHex))
        }
      }
      .padding(.horizontal, AppSpacing.md)
      .padding(.vertical, AppSpacing.sm)
      .background(inputFieldFill, in: Capsule())
      .overlay(
        Capsule().stroke(
          Color(hex: theme.style.accentHex).opacity(theme.id == "minimal-white" ? 0.1 : 0.18),
          lineWidth: 1))

      ForEach(theme.inputTrailingIcons, id: \.self) { iconName in
        Image(systemName: iconName)
          .frame(width: 24, height: 24)
      }
    }
    .font(.headline)
    .foregroundStyle(Color(hex: theme.style.accentHex))
    .padding(usesFloatingFrame ? AppSpacing.xs : AppSpacing.sm)
    .padding(.horizontal, usesFloatingFrame ? AppSpacing.sm : 0)
    .frame(maxWidth: .infinity)
    .background(
      .ultraThinMaterial,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .background(
      barFill,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .clipShape(
      RoundedCornerShape(
        radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .padding(.horizontal, usesFloatingFrame ? AppSpacing.sm : 0)
    .padding(.vertical, usesFloatingFrame ? AppSpacing.xs : 0)
  }

  private var midnightInputBar: some View {
    HStack(spacing: AppSpacing.sm) {
      Image(systemName: "plus")
        .font(.title3.weight(.regular))
        .frame(width: 28, height: 28)

      HStack(spacing: AppSpacing.xs) {
        Text(placeholder == "Message" ? theme.inputPlaceholder : placeholder)
          .font(.callout.weight(.regular))
          .foregroundStyle(whatsAppPlaceholderColor)
          .lineLimit(1)
        Spacer(minLength: AppSpacing.xs)
        WhatsAppStickerIcon(color: whatsAppIconColor)
      }
      .padding(.horizontal, AppSpacing.md)
      .padding(.vertical, 10)
      .background(whatsAppFieldBackground, in: Capsule())
      .overlay(Capsule().stroke(whatsAppFieldStroke, lineWidth: 1))

      ForEach(whatsAppTrailingIcons, id: \.self) { iconName in
        Image(systemName: iconName)
              .font(.title3.weight(.medium))
          .frame(width: 32, height: 32)
      }
    }
    .foregroundStyle(whatsAppIconColor)
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, AppSpacing.sm)
    .frame(maxWidth: .infinity)
    .background(
      whatsAppBarBackground,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .clipShape(RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners))
  }

  private var socialBlueInputBar: some View {
    HStack(spacing: 14) {
      socialComposerIcon("meta_camera", size: 22)
      socialComposerIcon("meta_photo", size: 22)
      socialComposerIcon("meta_microphone", size: 23)

      HStack(spacing: AppSpacing.xs) {
        Text(placeholder == "Message" ? "Aa" : placeholder)
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(socialBluePlaceholderColor)
          .lineLimit(1)
        Spacer(minLength: AppSpacing.xs)
          Image("meta_smile")
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .font(.system(size: 23, weight: .semibold))
              .foregroundColor(Color(hex: "#0035c8"))
              .frame(width: 24, height: 24)
      }
      .padding(.leading, 16)
      .padding(.trailing, 10)
      .frame(height: 36)
      .background(socialBlueFieldBackground, in: Capsule())

      socialComposerIcon("meta_thumb", size: 26)
    }
    .foregroundStyle(Color(hex: theme.style.accentHex))
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(
      socialBlueBarBackground,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .clipShape(RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners))
  }

  private func socialComposerIcon(_ systemName: String, size: CGFloat) -> some View {

      Image(systemName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 26, height: 34)
              .foregroundColor(Color(hex: "#0035c8"))
  }

  private var gradientDMInputBar: some View {
    HStack(spacing: 10) {
      Image(systemName: "camera.fill")
        .font(.system(size: 19, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 36, height: 36)
        .background(
          LinearGradient(
            colors: [Color(hex: "#6E54FF"), Color(hex: "#C135FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          in: Circle()
        )

      Text(placeholder == "Message" ? "Message..." : placeholder)
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(gradientDMPlaceholderColor)
        .lineLimit(1)

      Spacer(minLength: 6)

      gradientDMComposerIcon("mic", size: 22)
     // gradientDMComposerIcon("photo", size: 22)
        
        Image("insta_gallery")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(gradientDMIconColor)
            .frame(width: 27, height: 30)
        
      InstagramStickerIcon(color: gradientDMIconColor)
        .frame(width: 27, height: 30)
      gradientDMComposerIcon("plus.circle", size: 24)
    }
    .padding(.leading, 5)
    .padding(.trailing, 10)
    .frame(maxWidth: .infinity)
    .frame(height: 44)
    .background(gradientDMFieldBackground, in: Capsule())
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(
      gradientDMBarBackground,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .clipShape(RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners))
  }

  private func gradientDMComposerIcon(_ systemName: String, size: CGFloat) -> some View {
    Image(systemName: systemName)
      .font(.system(size: size, weight: .medium))
      .foregroundStyle(gradientDMIconColor)
      .frame(width: 27, height: 30)
  }

  private var paperPlaneInputBar: some View {
    HStack(spacing: 8) {
      Image(systemName: "paperclip")
        .font(.system(size: 23, weight: .semibold))
        .foregroundStyle(paperPlaneIconColor)
        .frame(width: 40, height: 40)
        .background(paperPlaneCircleBackground, in: Circle())

      HStack(spacing: AppSpacing.sm) {
        Text(placeholder == "Message" ? "Message" : placeholder)
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(paperPlanePlaceholderColor)
          .lineLimit(1)
        Spacer(minLength: AppSpacing.xs)
        Image(systemName: "clock")
          .font(.system(size: 23, weight: .medium))
          .foregroundStyle(paperPlaneIconColor.opacity(colorScheme == .dark ? 0.72 : 0.66))
      }
      .padding(.horizontal, 14)
      .frame(height: 40)
      .background(paperPlaneFieldBackground, in: Capsule())
      .overlay(Capsule().stroke(paperPlaneFieldStroke, lineWidth: 1))

      Image(systemName: "mic")
        .font(.system(size: 25, weight: .semibold))
        .foregroundStyle(paperPlaneIconColor)
        .frame(width: 40, height: 40)
        .background(paperPlaneCircleBackground, in: Circle())
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .frame(maxWidth: .infinity)
    .background(
      paperPlaneBarBackground,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .clipShape(RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners))
  }

  private var snapInputBar: some View {
    HStack(spacing: 11) {
      Image(systemName: "camera.fill")
        .font(.system(size: 21, weight: .black))
        .foregroundStyle(snapCameraIconColor)
        .frame(width: 44, height: 44)
        .background(snapCameraBackground, in: Circle())

      HStack(spacing: 0) {
        Text(placeholder == "Message" ? "Send chat" : placeholder)
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(snapPlaceholderColor)
          .lineLimit(1)
          .padding(.leading, 14)

        Spacer(minLength: AppSpacing.xs)

        Image(systemName: "mic")
          .font(.system(size: 25, weight: .medium))
          .foregroundStyle(snapComposerIconColor)
          .frame(width: 28, height: 28)
          .padding(.trailing, 9)
      }
      .frame(height: 40)
      .background(snapFieldBackground, in: Capsule())
      .overlay(Capsule().stroke(snapFieldStroke, lineWidth: 1))

      snapComposerIcon("face.smiling", size: 25)
      SnapStickerStackIcon(color: snapComposerIconColor)
        .frame(width: 27, height: 34)
      snapComposerIcon("gamecontroller", size: 25)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity)
    .background(
      snapBarBackground,
      in: RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners)
    )
    .overlay(alignment: .top) {
      Rectangle()
        .fill(snapTopDividerColor)
        .frame(height: 1)
    }
    .clipShape(RoundedCornerShape(radius: resolvedCornerRadius, corners: roundedCorners))
  }

  private func snapComposerIcon(_ systemName: String, size: CGFloat) -> some View {
    Image(systemName: systemName)
      .font(.system(size: size, weight: .medium))
      .foregroundStyle(snapComposerIconColor)
      .frame(width: 27, height: 28)
  }

  private var inputFieldFill: Color {
    if theme.id == "minimal-white" {
      return Color(hex: colorScheme == .dark ? "#151515" : "#FFFFFF")
    }
    return Color(hex: colorScheme == .dark ? theme.style.darkInputBarHex : theme.style.inputBarHex)
      .opacity(0.88)
  }

  private var barFill: Color {
    Color(hex: colorScheme == .dark ? theme.style.darkInputBarHex : theme.style.inputBarHex)
      .opacity(usesFloatingFrame ? 0.62 : 0.82)
  }

  private var usesFloatingFrame: Bool {
    theme.usesFloatingInputBar && !isDockedInChatFrame
  }

  private var resolvedCornerRadius: CGFloat {
    if theme.isWhatsAppStyleTheme || theme.isSocialMetaStyleTheme || theme.isGradientDMStyleTheme
      || theme.isPaperPlaneStyleTheme || theme.isSnapStyleTheme
    {
      return cornerRadius ?? 0
    }
    return cornerRadius ?? (usesFloatingFrame ? AppRadius.xl : 0)
  }

  private var whatsAppTrailingIcons: [String] {
    ["indianrupeesign.circle", "camera", "mic"]
  }

  private var isLightGreenWhatsApp: Bool {
    theme.id == "green-bubble" && colorScheme == .light
  }

  private var whatsAppBarBackground: Color {
    isLightGreenWhatsApp ? Color(hex: theme.style.headerHex) : Color(hex: "#0B0B0B")
  }

  private var whatsAppFieldBackground: Color {
    isLightGreenWhatsApp ? Color.white.opacity(0.95) : Color(hex: "#202020")
  }

  private var whatsAppFieldStroke: Color {
    isLightGreenWhatsApp ? Color.black.opacity(0.12) : Color.white.opacity(0.06)
  }

  private var whatsAppIconColor: Color {
    isLightGreenWhatsApp ? Color(hex: "#111B21") : .white.opacity(0.95)
  }

  private var whatsAppPlaceholderColor: Color {
    isLightGreenWhatsApp ? Color(hex: "#667781") : .white.opacity(0.55)
  }

  private var socialBlueBarBackground: Color {
    .white
  }

  private var socialBlueFieldBackground: Color {
    Color(hex: "#F0F2F5")
  }

  private var socialBluePlaceholderColor: Color {
    Color(hex: "#65676B")
  }

  private var gradientDMBarBackground: Color {
    colorScheme == .dark ? Color(hex: "#070A10") : Color.white
  }

  private var gradientDMFieldBackground: Color {
    colorScheme == .dark ? Color(hex: "#1D2025") : Color(hex: "#F2F3F5")
  }

  private var gradientDMIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.96) : Color(hex: "#111318")
  }

  private var gradientDMPlaceholderColor: Color {
    colorScheme == .dark ? .white.opacity(0.58) : Color(hex: "#8E939C")
  }

  private var paperPlaneBarBackground: Color {
    colorScheme == .dark ? Color(hex: "#05060B").opacity(0.98) : Color.clear
  }

  private var paperPlaneIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.92) : Color(hex: "#324131")
  }

  private var paperPlaneCircleBackground: Color {
    colorScheme == .dark ? Color.white.opacity(0.10) : Color(hex: "#F5FFF1").opacity(0.82)
  }

  private var paperPlaneFieldBackground: Color {
    colorScheme == .dark ? Color.white.opacity(0.10) : Color(hex: "#F5FFF1").opacity(0.80)
  }

  private var paperPlaneFieldStroke: Color {
    colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "#DDEECD").opacity(0.70)
  }

  private var paperPlanePlaceholderColor: Color {
    colorScheme == .dark ? .white.opacity(0.58) : Color(hex: "#6A7D68")
  }

  private var snapBarBackground: Color {
    colorScheme == .dark ? Color(hex: "#070A10") : Color.white
  }

  private var snapCameraBackground: Color {
    colorScheme == .dark ? .white.opacity(0.92) : Color.black
  }

  private var snapCameraIconColor: Color {
    colorScheme == .dark ? Color(hex: "#070A10") : .white
  }

  private var snapFieldBackground: Color {
    colorScheme == .dark ? Color(hex: "#1A1F27") : Color.white
  }

  private var snapFieldStroke: Color {
    colorScheme == .dark ? .white.opacity(0.10) : Color(hex: "#D8DBE0")
  }

  private var snapPlaceholderColor: Color {
    colorScheme == .dark ? Color(hex: "#AAB1BC") : Color(hex: "#8D939C")
  }

  private var snapComposerIconColor: Color {
    colorScheme == .dark ? .white.opacity(0.88) : Color(hex: "#4A5059")
  }

  private var snapTopDividerColor: Color {
    colorScheme == .dark ? .white.opacity(0.08) : Color(hex: "#E6E8EC")
  }
}

private struct SnapStickerStackIcon: View {
  let color: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3.8, style: .continuous)
        .stroke(color, lineWidth: 2.2)
        .frame(width: 13, height: 20)
        .rotationEffect(.degrees(-8))
        .offset(x: -4)

      RoundedRectangle(cornerRadius: 3.8, style: .continuous)
        .stroke(color, lineWidth: 2.2)
        .frame(width: 13, height: 20)
        .rotationEffect(.degrees(8))
        .offset(x: 4)

      Circle()
        .fill(color)
        .frame(width: 2.6, height: 2.6)
        .offset(x: 4, y: -4)
    }
  }
}

//private struct InstagramStickerIcon: View {
//  let color: Color
//
//  var body: some View {
//    ZStack {
//      RoundedRectangle(cornerRadius: 5, style: .continuous)
//        .stroke(color, lineWidth: 2.2)
//
//      Path { path in
//        path.move(to: CGPoint(x: 15.8, y: 3))
//        path.addLine(to: CGPoint(x: 19, y: 6.2))
//        path.addLine(to: CGPoint(x: 15.8, y: 6.2))
//        path.closeSubpath()
//      }
//      .fill(color.opacity(0.96))
//
//      HStack(spacing: 5) {
//        Circle()
//          .fill(color)
//          .frame(width: 2.5, height: 2.5)
//        Circle()
//          .fill(color)
//          .frame(width: 2.5, height: 2.5)
//      }
//      .offset(y: -1.5)
//
//      Path { path in
//        path.move(to: CGPoint(x: 7, y: 12.8))
//        path.addQuadCurve(to: CGPoint(x: 15, y: 12.8), control: CGPoint(x: 11, y: 16))
//      }
//      .stroke(color, style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
//      .offset(y: 1)
//    }
//    .frame(width: 22, height: 22)
//  }
//}


import SwiftUI

private struct InstagramStickerIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            // 1. Main Outline & Soft Fold
            Path { path in
                let cr: CGFloat = 5
                
                // Top & Top-Right Corner
                path.move(to: CGPoint(x: cr, y: 0))
                path.addLine(to: CGPoint(x: 22 - cr, y: 0))
                path.addArc(center: CGPoint(x: 22 - cr, y: cr), radius: cr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
                
                // Right edge down to the start of the peel
                path.addLine(to: CGPoint(x: 22, y: 14.5))
                
                // Diagonal outer cut (the gap)
                path.addLine(to: CGPoint(x: 14.5, y: 22))
                
                // Bottom edge & Bottom-Left Corner
                path.addLine(to: CGPoint(x: cr, y: 22))
                path.addArc(center: CGPoint(x: cr, y: 22 - cr), radius: cr, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
                
                // Left edge & Top-Left Corner
                path.addLine(to: CGPoint(x: 0, y: cr))
                path.addArc(center: CGPoint(x: cr, y: cr), radius: cr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
                
                // The Inner Flap
                path.move(to: CGPoint(x: 22, y: 14.5))
                // This arc mathematically rounds off the sharp inner corner of the flap
                path.addArc(tangent1End: CGPoint(x: 14.5, y: 14.5),
                            tangent2End: CGPoint(x: 14.5, y: 22),
                            radius: 2.0)
                path.addLine(to: CGPoint(x: 14.5, y: 22))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))

            // 2. Eyes (Slightly larger and adjusted spacing)
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 2.8, height: 2.8)
                Circle()
                    .fill(color)
                    .frame(width: 2.8, height: 2.8)
            }
            .offset(x: -1.0, y: -2.5)

            // 3. Smile (Wider and deeper to match the eyes)
            Path { path in
                path.move(to: CGPoint(x: 6.5, y: 11.5))
                path.addQuadCurve(to: CGPoint(x: 13.5, y: 11.5), control: CGPoint(x: 10.0, y: 15.5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
        .frame(width: 22, height: 22)
    }
}


struct WhatsAppStickerIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            WhatsAppStickerOutline()
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            WhatsAppStickerFold()
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 20, height: 20)
    }
}

struct WhatsAppStickerOutline: Shape {
    func path(in rect: CGRect) -> Path {
        // Reduced inset slightly to optimize the stroke drawing space within 22x22
        let r = rect.insetBy(dx: 1.0, dy: 1.0)
        let radius = min(r.width, r.height) * 0.4
        let foldOffset = min(r.width, r.height) * 0.36
        var path = Path()

        // Top-Left corner start
        path.move(to: CGPoint(x: r.minX + radius, y: r.minY))
        
        // Top edge & Top-Right corner
        path.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius), control: CGPoint(x: r.maxX, y: r.minY))
        
        // Right edge down to the fold start
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - foldOffset))
        
        // The outer cutout curve of the fold (bending inwards dynamically)
        path.addQuadCurve(
            to: CGPoint(x: r.maxX - foldOffset, y: r.maxY),
            control: CGPoint(x: r.maxX - foldOffset * 0.15, y: r.maxY - foldOffset * 0.15)
        )
        
        // Bottom edge & Bottom-Left corner
        path.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius), control: CGPoint(x: r.minX, y: r.maxY))
        
        // Left edge & back to Top-Left corner
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        path.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        
        return path
    }
}

struct WhatsAppStickerFold: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: 1.0, dy: 1.0)
        let foldOffset = min(r.width, r.height) * 0.45
        var path = Path()

        // Flap line of the peeled sticker corner
        path.move(to: CGPoint(x: r.maxX - foldOffset, y: r.maxY))
        path.addQuadCurve(
            to: CGPoint(x: r.maxX, y: r.maxY - foldOffset),
            control: CGPoint(x: r.maxX - foldOffset * 0.85, y: r.maxY - foldOffset * 0.85)
        )
        
        return path
    }
}
