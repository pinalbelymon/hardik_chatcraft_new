import SwiftUI
import PhotosUI
import UIKit

struct CharacterCustomizationView: View {
    @Binding var story: ChatStory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showPaywall = false

    private var isCompactDevice: Bool {
        DeviceSize.isCurrentCompactHeight
    }

    var body: some View {
        ResponsiveContainer { width in
            VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
                header(width: width)

                if !subscriptionManager.canAddCharacter(currentCharacterCount: story.characters.count) {
                    upgradeBanner
                }

                ForEach($story.characters) { $character in
                    CharacterEditorCard(character: $character, theme: story.theme, canDelete: story.characters.count > 1) {
                        delete(character)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationStack { PaywallView() }
        }
        .trackScreen(.characters)
        .detailAds()
        .background(PremiumBackdrop())
    }

    private func header(width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Characters")
                    .font(AppFont.font(isCompactDevice ? 24 : 30, weight: .heavy, width: width))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("Name, avatar, message side, online status, and bubble colors.")
                    .font((isCompactDevice ? Font.caption : Font.subheadline).weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(isCompactDevice ? 2 : nil)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.sm)

            Button {
                addCharacter()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font((isCompactDevice ? Font.caption : Font.subheadline).weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, isCompactDevice ? AppSpacing.sm : AppSpacing.md)
                .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
                .background(AppColors.brandGradient, in: Capsule())
                .shadow(color: AppColors.appTint.opacity(0.22), radius: 14, y: 8)
            }
            .buttonStyle(InteractiveScaleButtonStyle())
        }
    }

    private var upgradeBanner: some View {
        Button {
            AppAnalytics.shared.track(.featureLocked, ["source": "CharacterCustomizationView"])
            showPaywall = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.caption.weight(.heavy))
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white)
                    .background(AppColors.appTint, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("More characters are locked")
                        .font(.subheadline.weight(.heavy))
                    Text("Upgrade to add a larger cast for bigger stories.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(AppSpacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColors.appTint.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle())
    }

    private func addCharacter() {
        guard subscriptionManager.canAddCharacter(currentCharacterCount: story.characters.count) else {
            AppAnalytics.shared.track(.featureLocked, ["source": "CharacterCustomizationView"])
            showPaywall = true
            return
        }
        AppAnalytics.shared.track(.characterAdd, ["character_count": story.characters.count + 1])
        story.characters.append(
            ChatCharacter(
                name: "Character \(story.characters.count + 1)",
                avatarSymbol: ChatCharacter.avatarSymbols[story.characters.count % ChatCharacter.avatarSymbols.count],
                bubbleColorHex: "#4F7CFF",
                side: story.characters.count.isMultiple(of: 2) ? .left : .right,
                statusText: "online"
            )
        )
    }

    private func delete(_ character: ChatCharacter) {
        guard story.characters.count > 1 else { return }
        AppAnalytics.shared.track(.characterDelete, ["character_count": story.characters.count - 1])
        story.characters.removeAll { $0.id == character.id }

        if let fallback = story.characters.first {
            for index in story.messages.indices where story.messages[index].characterID == character.id {
                story.messages[index].characterID = fallback.id
            }
        }
    }
}

private struct CharacterEditorCard: View {
    @Binding var character: ChatCharacter
    let theme: ChatTheme
    let canDelete: Bool
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            topRow
            avatarTools
            sideSelector
            statusRow
            colorRow
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(Color(hex: effectiveBubbleColorHex).opacity(0.2), lineWidth: 1.2)
        }
        .shadow(color: Color(hex: effectiveBubbleColorHex).opacity(0.12), radius: 18, y: 10)
        .onChange(of: photoItem) { newItem in
            Task {
                character.avatarImageData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            avatarPreview

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                TextField("Character name", text: $character.name)
                    .font(.title3.weight(.heavy))
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                TextField("Status text", text: $character.statusText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            }

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Character", systemImage: "trash")
                }
                .disabled(!canDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.heavy))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(AppColors.appTint)
                    .background(AppColors.appTint.opacity(0.12), in: Circle())
            }
        }
    }

    private var avatarTools: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("Avatar")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.secondary)

            Spacer()

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(character.avatarImageData == nil ? "Photo" : "Change", systemImage: "photo.fill")
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.appTint.opacity(0.12), in: Capsule())
            }

            Menu {
                ForEach(ChatCharacter.avatarSymbols, id: \.self) { symbol in
                    Button {
                        character.avatarSymbol = symbol
                    } label: {
                        Label(avatarName(for: symbol), systemImage: symbol)
                    }
                }
            } label: {
                Label(avatarName(for: character.avatarSymbol), systemImage: character.avatarSymbol)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(.thinMaterial, in: Capsule())
            }

            if character.avatarImageData != nil {
                Button {
                    character.avatarImageData = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.heavy))
                        .frame(width: 26, height: 26)
                        .foregroundStyle(.secondary)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sideSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Message Side")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.xs) {
                sideButton(.left)
                sideButton(.right)
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Online Status")
                    .font(.subheadline.weight(.heavy))
                Text(character.isOnline ? "Shown as available in header" : "Shown as offline")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Online", isOn: $character.isOnline)
                .labelsHidden()
        }
        .padding(AppSpacing.sm)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private var colorRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ColorPicker(selection: bubbleColorBinding, supportsOpacity: false) {
                ColorSettingChip(title: character.customBubbleColorHex == nil ? "Bubble" : "Custom Bubble", color: Color(hex: effectiveBubbleColorHex))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ColorPicker(selection: textColorBinding, supportsOpacity: false) {
                ColorSettingChip(title: character.customTextColorHex == nil ? "Text" : "Custom Text", color: Color(hex: effectiveTextColorHex))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var avatarPreview: some View {
        Circle()
            .fill(Color(hex: effectiveBubbleColorHex).opacity(0.18))
            .frame(width: 64, height: 64)
            .overlay {
                if let data = character.avatarImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: character.avatarSymbol)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(hex: effectiveBubbleColorHex))
                }
            }
            .overlay(Circle().stroke(Color(hex: effectiveBubbleColorHex).opacity(0.18), lineWidth: 1))
    }

    private func sideButton(_ side: SenderSide) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                character.side = side
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if side == .left {
                    Image(systemName: "arrow.left")
                    Text(side.title)
                } else {
                    Text(side.title)
                    Image(systemName: "arrow.right")
                }
            }
            .font(.subheadline.weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .foregroundStyle(character.side == side ? .white : .primary)
            .background(sideFill(side), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(character.side == side ? Color.white.opacity(0.18) : AppColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveScaleButtonStyle())
    }

    private func sideFill(_ side: SenderSide) -> AnyShapeStyle {
        if character.side == side {
            return AnyShapeStyle(AppColors.brandGradient)
        }
        return AnyShapeStyle(.thinMaterial)
    }

    private func avatarName(for symbol: String) -> String {
        switch symbol {
        case "person.crop.circle": return "Person"
        case "sparkles": return "Sparkle"
        case "heart.circle": return "Heart"
        case "bolt.circle": return "Bolt"
        case "moon.circle": return "Moon"
        case "star.circle": return "Star"
        case "crown": return "Crown"
        case "face.smiling": return "Smile"
        default: return "Icon"
        }
    }

    private var effectiveBubbleColorHex: String {
        character.customBubbleColorHex ?? defaultBubbleColorHex
    }

    private var effectiveTextColorHex: String {
        character.customTextColorHex ?? defaultTextColorHex
    }

    private var defaultBubbleColorHex: String {
        if colorScheme == .dark {
            return character.side == .right ? theme.style.outgoingDarkBubbleHex : theme.style.incomingDarkBubbleHex
        }
        return character.side == .right ? theme.style.outgoingBubbleHex : theme.style.incomingBubbleHex
    }

    private var defaultTextColorHex: String {
        if character.side == .right {
            return theme.style.outgoingTextHex
        }
        if colorScheme == .dark {
            return "#FFFFFF"
        }
        return theme.style.incomingTextHex
    }

    private var bubbleColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: effectiveBubbleColorHex) },
            set: { newColor in
                let hex = newColor.toHex()
                character.customBubbleColorHex = hex
                character.bubbleColorHex = hex
            }
        )
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: effectiveTextColorHex) },
            set: { newColor in
                let hex = newColor.toHex()
                character.customTextColorHex = hex
                character.textColorHex = hex
            }
        )
    }
}

private struct ColorSettingChip: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
            Text(title)
                .font(.subheadline.weight(.heavy))
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}
