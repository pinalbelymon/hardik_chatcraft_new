import AVFoundation
import PhotosUI
import SwiftUI
import UIKit
struct MessageComposerRoute: Identifiable {
  let id = UUID()
  let message: ChatMessage?
}

struct ChatEditorView: View {
  @Binding var story: ChatStory

  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @Environment(\.colorScheme) private var colorScheme

  @State private var composerRoute: MessageComposerRoute?
  @State private var showPaywall = false
  @State private var showMessageManager = false
  @State private var showThemeSelection = false
  @State private var showCharacterCustomization = false
  @State private var activeCharacterID: UUID?
  @State private var quickText = ""
  @State private var quickPhotoItem: PhotosPickerItem?
  @State private var quickVideoItem: PhotosPickerItem?
  @State private var isProcessingVideo = false
  @FocusState private var isInputFocused: Bool

  private var theme: ChatTheme { story.theme }
  private var isCompactDevice: Bool { DeviceSize.isCurrentCompactHeight }

  private var activeCharacter: ChatCharacter {
    if let id = activeCharacterID, let char = story.characters.first(where: { $0.id == id }) {
      return char
    }
    return story.characters.first ?? ChatCharacter(name: "You", avatarSymbol: "person.crop.circle", bubbleColorHex: "#198CFF", side: .right)
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        editorQuickBar
          .padding(.horizontal, AppSpacing.sm)
          .padding(.vertical, isCompactDevice ? 4 : AppSpacing.xs)

        chatPreview(width: geometry.size.width - AppSpacing.md)
          .padding(.horizontal, AppSpacing.xs)
          .frame(maxHeight: .infinity)

        inlineComposerDock
          .padding(.horizontal, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
          .padding(.vertical, isCompactDevice ? 4 : AppSpacing.xs)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(PremiumBackdrop())
    }
    .sheet(item: $composerRoute) { route in
      NavigationStack {
        MessageComposerSheet(story: story, existingMessage: route.message) { message in
          save(message)
        }
      }
    }
    .fullScreenCover(isPresented: $showPaywall) {
      NavigationStack { PaywallView() }
    }
    .sheet(isPresented: $showMessageManager) {
      NavigationStack {
        MessageManagerView(story: $story, isCompactDevice: isCompactDevice)
      }
    }
    .sheet(isPresented: $showThemeSelection) {
      NavigationStack {
        ThemeSelectionView(story: $story)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") { showThemeSelection = false }
            }
          }
      }
    }
    .sheet(isPresented: $showCharacterCustomization) {
      NavigationStack {
        CharacterCustomizationView(story: $story)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") { showCharacterCustomization = false }
            }
          }
      }
    }
    .trackScreen(.editor)
    .onAppear {
      if activeCharacterID == nil {
        activeCharacterID = story.characters.first?.id
      }
    }
    .onChange(of: story.characters) { newChars in
      if let currentID = activeCharacterID, !newChars.contains(where: { $0.id == currentID }) {
        activeCharacterID = newChars.first?.id
      }
    }
    .onChange(of: quickPhotoItem) { item in
      guard let item else { return }
      Task {
        if let data = try? await item.loadTransferable(type: Data.self) {
          await MainActor.run {
            addMediaMessage(type: .image, data: data)
            quickPhotoItem = nil
          }
        }
      }
    }
    .onChange(of: quickVideoItem) { item in
      guard let item else { return }
      Task {
        await MainActor.run { isProcessingVideo = true }
        if let videoData = try? await item.loadTransferable(type: Data.self),
           let thumbData = await VideoThumbnailGenerator.thumbnailJPEGData(from: videoData) {
          await MainActor.run {
            addMediaMessage(type: .video, data: thumbData)
            isProcessingVideo = false
            quickVideoItem = nil
          }
        } else {
          await MainActor.run {
            isProcessingVideo = false
            quickVideoItem = nil
          }
        }
      }
    }
  }

  // MARK: - Editor Quick Bar (Themes & Cast Switcher)
  private var editorQuickBar: some View {
    HStack(spacing: AppSpacing.xs) {
      // Theme Button
      Button {
        showThemeSelection = true
      } label: {
        HStack(spacing: 5) {
          Image(systemName: "paintpalette.fill")
            .font(.caption.weight(.heavy))
            .foregroundStyle(AppColors.appTint)
          Text(story.theme.name)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .foregroundStyle(.primary)
          Image(systemName: "chevron.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 1))
      }
      .buttonStyle(InteractiveScaleButtonStyle())

      // Characters Button
      Button {
        showCharacterCustomization = true
      } label: {
        HStack(spacing: 5) {
          Image(systemName: "person.2.fill")
            .font(.caption.weight(.heavy))
            .foregroundStyle(AppColors.mint)
          Text("\(story.characters.count) Cast")
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .foregroundStyle(.primary)
          Image(systemName: "chevron.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 1))
      }
      .buttonStyle(InteractiveScaleButtonStyle())

      Spacer(minLength: 4)

      // Manage / Reorder Button
      Button {
        showMessageManager = true
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "slider.horizontal.3")
            .font(.caption.weight(.heavy))
          Text("\(story.messages.count)")
            .font(.caption.weight(.heavy))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .foregroundStyle(AppColors.appTint)
        .background(AppColors.appTint.opacity(0.12), in: Capsule())
      }
      .buttonStyle(InteractiveScaleButtonStyle())
    }
  }

  // MARK: - Chat Preview Canvas
  private func chatPreview(width: CGFloat) -> some View {
    VStack(spacing: 0) {
      ChatHeaderView(
        story: story,
        theme: theme,
        cornerRadius: previewFrameCornerRadius,
        roundedCorners: [.topLeft, .topRight]
      )
      .zIndex(2)
      .contentShape(Rectangle())
      .onTapGesture {
        showCharacterCustomization = true
      }

      ScrollViewReader { proxy in
        GeometryReader { scrollGeometry in
          ScrollView {
            LazyVStack(spacing: theme.compactMessageSpacing) {
              if story.messages.isEmpty {
                EmptyStateView(
                  title: "No messages yet",
                  message: "Type below or use the + button to build your conversation.",
                  systemImage: "text.bubble"
                )
              } else {
                ForEach(Array(story.messages.enumerated()), id: \.element.id) { index, message in
                  if let character = character(for: message) {
                    let group = messageGroup(at: index, in: story.messages)
                    ChatBubbleView(
                      message: message,
                      character: character,
                      theme: theme,
                      maxWidth: DeviceSize.chatBubbleMaxWidth(for: width),
                      isFirstInGroup: group.isFirst,
                      isLastInGroup: group.isLast
                    )
                    .id(message.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                      composerRoute = MessageComposerRoute(message: message)
                    }
                    .contextMenu {
                      Button {
                        composerRoute = MessageComposerRoute(message: message)
                      } label: {
                        Label("Edit Message", systemImage: "pencil")
                      }

                      Button {
                        cycleSender(for: message)
                      } label: {
                        Label("Switch Sender", systemImage: "arrow.left.arrow.right")
                      }

                      Button {
                        duplicate(message)
                      } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                      }

                      Button(role: .destructive) {
                        delete(message)
                      } label: {
                        Label("Delete Message", systemImage: "trash")
                      }
                    }
                  }
                }
              }
            }
            .frame(
              minHeight: scrollGeometry.size.height,
              alignment: story.messages.isEmpty ? .center : .top
            )
            .padding(.vertical, story.messages.isEmpty ? 0 : AppSpacing.md)
          }
          .background(chatBackground)
          .clipped()
          .onChange(of: story.messages.count) { _ in
            if let last = story.messages.last {
              withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                proxy.scrollTo(last.id, anchor: .bottom)
              }
            }
          }
        }
      }
      .zIndex(1)

      ChatInputBarPreview(
        theme: theme,
        placeholder: theme.inputPlaceholder,
        roundedCorners: [.bottomLeft, .bottomRight],
        cornerRadius: previewFrameCornerRadius,
        isDockedInChatFrame: true
      )
      .zIndex(2)
      .contentShape(Rectangle())
      .onTapGesture {
        isInputFocused = true
      }
    }
    .background(
      AppColors.panelBackground,
      in: RoundedRectangle(cornerRadius: previewFrameCornerRadius, style: .continuous)
    )
    .clipShape(RoundedRectangle(cornerRadius: previewFrameCornerRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: previewFrameCornerRadius, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [.white.opacity(0.18), AppColors.appTint.opacity(0.24), .white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(0.18), radius: 28, y: 16)
  }

  private var previewFrameCornerRadius: CGFloat {
    0
  }

  // MARK: - Inline Composer Dock
  private var inlineComposerDock: some View {
    HStack(spacing: AppSpacing.xs) {
      // 1-Tap Character Switcher
      characterToggleButton

      // Text Input
      HStack(spacing: 6) {
        TextField("Message as \(activeCharacter.name)...", text: $quickText)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
          .focused($isInputFocused)
          .submitLabel(.send)
          .onSubmit {
            sendQuickText()
          }

        if !quickText.isEmpty {
          Button {
            quickText = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.caption)
              .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.secondary)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .background(
        colorScheme == .dark ? Color(hex: "#242833") : Color(hex: "#F3F4F6"),
        in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
          .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
      )

      // Send Button (Visible when typing)
      if !quickText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Button {
          sendQuickText()
        } label: {
          ZStack {
            Circle()
              .fill(resolvedCharacterColor(activeCharacter))
              .frame(width: 36, height: 36)

            Image(systemName: "arrow.up")
              .font(.system(size: 16, weight: .bold))
              .foregroundStyle(.white)
          }
          .shadow(color: resolvedCharacterColor(activeCharacter).opacity(0.4), radius: 4, y: 2)
        }
        .buttonStyle(InteractiveScaleButtonStyle())
      }

      // Plus Menu for Media / Special Bubbles / Advanced Options
      attachmentMenu
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, 8)
    .background(
      colorScheme == .dark ? Color(hex: "#16181F") : Color.white,
      in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, y: 4)
  }

  // MARK: - Character Toggle Button
  private var characterToggleButton: some View {
    Menu {
      Section("Switch Speaker") {
        ForEach(story.characters) { char in
          Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
              activeCharacterID = char.id
            }
          } label: {
            HStack {
              Text(char.name)
              if char.id == activeCharacter.id {
                Image(systemName: "checkmark")
              }
            }
          }
        }
      }

      Button {
        showCharacterCustomization = true
      } label: {
        Label("Manage Cast...", systemImage: "person.crop.circle.badge.plus")
      }
    } label: {
      HStack(spacing: 5) {
        let accent = resolvedCharacterColor(activeCharacter)
        ZStack {
          Circle()
            .fill(accent)
            .frame(width: 32, height: 32)

          Image(systemName: activeCharacter.avatarSymbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
        }
        .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 1.2))
        .shadow(color: accent.opacity(0.35), radius: 4, y: 2)

        Image(systemName: "arrow.left.arrow.right")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.75) : Color.black.opacity(0.55))
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
      .background(
        colorScheme == .dark ? Color(hex: "#242833") : Color(hex: "#E5E7EB"),
        in: Capsule()
      )
      .overlay(
        Capsule()
          .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
      )
    }
    .simultaneousGesture(TapGesture().onEnded {
      cycleToNextCharacter()
    })
  }

  // MARK: - Attachment Menu
  private var attachmentMenu: some View {
    Menu {
      Section("Add Media & Special Bubbles") {
        // Image message
        PhotosPicker(selection: $quickPhotoItem, matching: .images) {
          Label("Photo Message", systemImage: "photo")
        }

        // Video message
        PhotosPicker(selection: $quickVideoItem, matching: .videos) {
          Label("Video Message", systemImage: "video")
        }

        // Voice Note
        Button {
          addSpecialMessage(type: .voice, text: "Voice note")
        } label: {
          Label("Voice Note", systemImage: "mic.fill")
        }

        // Typing indicator
        Button {
          addSpecialMessage(type: .typingIndicator, text: "typing...")
        } label: {
          Label("Typing Indicator", systemImage: "ellipsis.bubble")
        }

        // Timestamp / Date divider
        Button {
          addSpecialMessage(type: .timestamp, text: "Today")
        } label: {
          Label("Date / Time Separator", systemImage: "calendar")
        }

        // Reaction / Sticker
        Button {
          addSpecialMessage(type: .reaction, text: "❤️")
        } label: {
          Label("Heart Reaction", systemImage: "heart.fill")
        }

        // System notice
        Button {
          addSpecialMessage(type: .system, text: "Messages are end-to-end fictional.")
        } label: {
          Label("System Notice", systemImage: "info.circle")
        }
      }

      Section {
        Button {
          composerRoute = MessageComposerRoute(message: nil)
        } label: {
          Label("Advanced Composer...", systemImage: "slider.horizontal.3")
        }
      }
    } label: {
      ZStack {
        Circle()
          .fill(AppColors.appTint)
          .frame(width: 36, height: 36)

        Image(systemName: "plus")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.white)
      }
      .shadow(color: AppColors.appTint.opacity(0.35), radius: 4, y: 2)
    }
  }

  // MARK: - Helpers
  private func sendQuickText() {
    let clean = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return }

    let message = ChatMessage(
      characterID: activeCharacter.id,
      type: .text,
      text: clean,
      createdAt: Date(),
      displayTime: ChatMessage.defaultTimeString(from: Date()),
      readReceipt: .read,
      isDelivered: true,
      isSeen: true
    )
    save(message)
    quickText = ""
  }

  private func addSpecialMessage(type: MessageType, text: String) {
    guard subscriptionManager.canUseMessageType(type) else {
      AppAnalytics.shared.track(.featureLocked, ["source": "ChatEditorView"])
      showPaywall = true
      return
    }

    let message = ChatMessage(
      characterID: activeCharacter.id,
      type: type,
      text: text,
      createdAt: Date(),
      displayTime: ChatMessage.defaultTimeString(from: Date()),
      readReceipt: .read,
      reaction: type == .reaction ? "❤️" : "",
      isDelivered: true,
      isSeen: true
    )
    save(message)
  }

  private func addMediaMessage(type: MessageType, data: Data) {
    guard subscriptionManager.canUseMessageType(type) else {
      AppAnalytics.shared.track(.featureLocked, ["source": "ChatEditorView"])
      showPaywall = true
      return
    }

    let message = ChatMessage(
      characterID: activeCharacter.id,
      type: type,
      text: "",
      mediaData: data,
      createdAt: Date(),
      displayTime: ChatMessage.defaultTimeString(from: Date()),
      readReceipt: .read,
      isDelivered: true,
      isSeen: true
    )
    save(message)
  }

  private func cycleToNextCharacter() {
    AppAnalytics.shared.track(.characterSwitch)
    guard story.characters.count > 1 else { return }
    if let currentIndex = story.characters.firstIndex(where: { $0.id == activeCharacter.id }) {
      let nextIndex = (currentIndex + 1) % story.characters.count
      withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
        activeCharacterID = story.characters[nextIndex].id
      }
    }
  }

  private func cycleSender(for message: ChatMessage) {
    guard story.characters.count > 1 else { return }
    if let currentIndex = story.characters.firstIndex(where: { $0.id == message.characterID }) {
      let nextIndex = (currentIndex + 1) % story.characters.count
      if let msgIndex = story.messages.firstIndex(where: { $0.id == message.id }) {
        story.messages[msgIndex].characterID = story.characters[nextIndex].id
        story.updatedAt = Date()
      }
    }
  }

  private func duplicate(_ message: ChatMessage) {
    AppAnalytics.shared.track(.messageDuplicate, ["media_type": message.type.rawValue])
    let copy = ChatMessage(
      characterID: message.characterID,
      type: message.type,
      text: message.text,
      mediaData: message.mediaData,
      createdAt: Date(),
      displayTime: ChatMessage.defaultTimeString(from: Date()),
      readReceipt: message.readReceipt,
      typingDelay: message.typingDelay,
      reaction: message.reaction,
      isDelivered: message.isDelivered,
      isSeen: message.isSeen
    )
    save(copy)
  }

  private var chatBackground: some View {
    ThemeWallpaperView(
      theme: theme,
      intensity: theme.id == "midnight-doodle" ? 0.92 : (theme.isPaperPlaneStyleTheme ? 0.88 : 0.48)
    )
  }

  private func resolvedCharacterColor(_ character: ChatCharacter) -> Color {
    if let custom = character.customBubbleColorHex, !custom.isEmpty {
      return Color(hex: custom)
    }
    if !character.bubbleColorHex.isEmpty && character.bubbleColorHex != "#E9ECF2" && character.bubbleColorHex != "#FFFFFF" && character.bubbleColorHex != "#000000" {
      return Color(hex: character.bubbleColorHex)
    }
    if character.side == .right {
      return AppColors.appTint
    }
    let incomingIndex = story.characters.firstIndex(where: { $0.id == character.id }) ?? 1
    let palette = [
      Color(hex: "#10B981"),
      Color(hex: "#8B5CF6"),
      Color(hex: "#F97316"),
      Color(hex: "#EC4899"),
      Color(hex: "#06B6D4"),
      Color(hex: "#EAB308"),
    ]
    return palette[incomingIndex % palette.count]
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

  private func save(_ message: ChatMessage) {
    let editing = story.messages.contains { $0.id == message.id }
    AppAnalytics.shared.track(editing ? .messageEdit : .messageAdd, ["media_type": message.type.rawValue])
    if let index = story.messages.firstIndex(where: { $0.id == message.id }) {
      story.messages[index] = message
    } else {
      story.messages.append(message)
    }
    story.updatedAt = Date()
  }

  private func delete(_ message: ChatMessage) {
    AppAnalytics.shared.track(.messageDelete, ["media_type": message.type.rawValue])
    story.messages.removeAll { $0.id == message.id }
    story.updatedAt = Date()
  }
}

private struct MessageManagerView: View {
  @Binding var story: ChatStory
  let isCompactDevice: Bool

  @Environment(\.dismiss) private var dismiss
  @State private var composerRoute: MessageComposerRoute?

  var body: some View {
    List {
      Section {
        if story.messages.isEmpty {
          VStack(spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
            Image(systemName: "text.bubble")
              .font((isCompactDevice ? Font.title : Font.largeTitle).weight(.semibold))
              .foregroundStyle(AppColors.appTint)
            Text("No messages yet")
              .font(.headline.weight(.heavy))
            Text("Add the first message, then use this screen to reorder or edit the conversation.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
            Button {
              composerRoute = MessageComposerRoute(message: nil)
            } label: {
              Label("Add Message", systemImage: "plus.message.fill")
                .font(.subheadline.weight(.heavy))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.appTint)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, isCompactDevice ? AppSpacing.md : AppSpacing.xl)
        } else {
          ForEach(story.messages) { message in
            Button {
              composerRoute = MessageComposerRoute(message: message)
            } label: {
              MessageManagerRow(message: message)
            }
            .buttonStyle(.plain)
          }
          .onMove { offsets, destination in
            AppAnalytics.shared.track(.messageEdit, ["source": "reorder", "message_count": offsets.count])
            story.messages.move(fromOffsets: offsets, toOffset: destination)
            story.updatedAt = Date()
          }
          .onDelete { indexSet in
            AppAnalytics.shared.track(.messageDelete, ["source": "message_manager", "message_count": indexSet.count])
            story.messages.remove(atOffsets: indexSet)
            story.updatedAt = Date()
          }
        }
      } header: {
        Text(story.messages.isEmpty ? "Messages" : "Drag to reorder")
      } footer: {
        if !story.messages.isEmpty {
          Text(
            "Tap any row to edit. Use the drag handle to change order, or swipe/delete with the red control."
          )
        }
      }
    }
    .environment(\.editMode, .constant(.active))
    .trackScreen(.messageManager)
    .navigationTitle("Manage Messages")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Done") { dismiss() }
      }
      ToolbarItem(placement: .primaryAction) {
        Button {
          composerRoute = MessageComposerRoute(message: nil)
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(item: $composerRoute) { route in
      NavigationStack {
        MessageComposerSheet(story: story, existingMessage: route.message) { message in
          save(message)
        }
      }
    }
  }

  private func save(_ message: ChatMessage) {
    let editing = story.messages.contains { $0.id == message.id }
    AppAnalytics.shared.track(editing ? .messageEdit : .messageAdd, ["media_type": message.type.rawValue])
    if let index = story.messages.firstIndex(where: { $0.id == message.id }) {
      story.messages[index] = message
    } else {
      story.messages.append(message)
    }
    story.updatedAt = Date()
  }
}

private struct MessageManagerRow: View {
  let message: ChatMessage

  var body: some View {
    HStack(spacing: AppSpacing.sm) {
      Image(systemName: message.type.iconName)
        .font(.headline.weight(.semibold))
        .frame(width: 34, height: 34)
        .foregroundStyle(AppColors.appTint)
        .background(
          AppColors.appTint.opacity(0.1),
          in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        Text(message.text.isEmpty ? message.type.title : message.text)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Text("\(message.type.title) · \(message.displayTime)")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Image(systemName: "line.3.horizontal")
        .font(.headline.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, AppSpacing.xs)
  }
}

private struct MessageComposerSheet: View {
  let story: ChatStory
  let existingMessage: ChatMessage?
  let onSave: (ChatMessage) -> Void

  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @Environment(\.dismiss) private var dismiss

  @State private var selectedCharacterID: UUID
  @State private var messageType: MessageType
  @State private var text: String
  @State private var createdAt: Date
  @State private var readReceipt: ReadReceiptStatus
  @State private var typingDelay: Double
  @State private var reaction: String
  @State private var isDelivered: Bool
  @State private var isSeen: Bool
  @State private var mediaData: Data?
  @State private var photoItem: PhotosPickerItem?
  @State private var videoItem: PhotosPickerItem?
  @State private var isGeneratingVideoThumbnail = false
  @State private var showPaywall = false

  init(story: ChatStory, existingMessage: ChatMessage?, onSave: @escaping (ChatMessage) -> Void) {
    self.story = story
    self.existingMessage = existingMessage
    self.onSave = onSave

    let fallbackCharacterID = story.characters.first?.id ?? UUID()
    _selectedCharacterID = State(initialValue: existingMessage?.characterID ?? fallbackCharacterID)
    _messageType = State(initialValue: existingMessage?.type ?? .text)
    _text = State(initialValue: existingMessage?.text ?? "")
    _createdAt = State(initialValue: existingMessage?.createdAt ?? Date())
    _readReceipt = State(initialValue: existingMessage?.readReceipt ?? .none)
    _typingDelay = State(initialValue: existingMessage?.typingDelay ?? 0.8)
    _reaction = State(initialValue: existingMessage?.reaction ?? "")
    _isDelivered = State(initialValue: existingMessage?.isDelivered ?? true)
    _isSeen = State(initialValue: existingMessage?.isSeen ?? false)
    _mediaData = State(initialValue: existingMessage?.mediaData)
  }

  var body: some View {
    ResponsiveContainer(maxWidth: 680) { _ in
      VStack(alignment: .leading, spacing: AppSpacing.lg) {
        senderSection
        typeSection
        contentSection
        timingSection
        receiptSection
      }
    }
    .trackScreen(.messageEditor)
    .navigationTitle(existingMessage == nil ? "Add Message" : "Edit Message")
    .navigationBarTitleDisplayMode(.inline)
    .background(PremiumBackdrop())
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { save() }
          .disabled(story.characters.isEmpty)
      }
    }
    .fullScreenCover(isPresented: $showPaywall) {
      NavigationStack { PaywallView() }
    }
    .onChange(of: photoItem) { newItem in
      Task {
        mediaData = try? await newItem?.loadTransferable(type: Data.self)
      }
    }
    .onChange(of: videoItem) { newItem in
      Task {
        await loadVideoThumbnail(from: newItem)
      }
    }
  }

  private var senderSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      Text("Sender")
        .font(.headline)
      Picker("Sender", selection: $selectedCharacterID) {
        ForEach(story.characters) { character in
          Text(character.name).tag(character.id)
        }
      }
      .pickerStyle(.menu)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(AppSpacing.md)
      .background(
        AppColors.panelBackground,
        in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
  }

  private var typeSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      Text("Message Type")
        .font(.headline)

      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 136), spacing: AppSpacing.sm)], spacing: AppSpacing.sm
      ) {
        ForEach(MessageType.allCases) { type in
          let unlocked = subscriptionManager.canUseMessageType(type)
          Button {
            if unlocked {
              messageType = type
            } else {
              AppAnalytics.shared.track(.featureLocked, ["source": "ChatEditorView"])
              showPaywall = true
            }
          } label: {
            HStack {
              Image(systemName: type.iconName)
              Text(type.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
              Spacer(minLength: 0)
              if !unlocked {
                Image(systemName: "lock.fill")
                  .font(.caption)
              }
            }
            .font(.caption.weight(.bold))
            .padding(AppSpacing.sm)
            .foregroundStyle(unlocked ? .primary : .secondary)
            .background(
              messageType == type ? AppColors.appTint.opacity(0.16) : AppColors.panelBackground,
              in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
            )
            .overlay(
              RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(messageType == type ? AppColors.appTint : AppColors.hairline, lineWidth: 1)
            )
          }
          .buttonStyle(.plain)
        }
      }
    }
    .onChange(of: messageType) { newType in
      if newType == .image || newType == .video {
        clearLegacyMediaDefaultText()
      }
    }
  }

  @ViewBuilder
  private var contentSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      Text(contentLabel)
        .font(.headline)

      if messageType == .image {
        PhotosPicker(selection: $photoItem, matching: .images) {
          Label(mediaData == nil ? "Choose Image Message" : "Image Selected", systemImage: "photo")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(
              AppColors.appTint.opacity(0.12),
              in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
      }

      if messageType == .video {
        PhotosPicker(selection: $videoItem, matching: .videos) {
          Label(
            mediaData == nil
              ? "Choose Video for Thumbnail"
              : (isGeneratingVideoThumbnail ? "Creating Thumbnail..." : "Video Thumbnail Ready"),
            systemImage: "video.badge.plus"
          )
          .font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(AppSpacing.md)
          .background(
            AppColors.appTint.opacity(0.12),
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .disabled(isGeneratingVideoThumbnail)

        if isGeneratingVideoThumbnail {
          ProgressView("Generating video thumbnail")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }

      if let mediaData, let image = UIImage(data: mediaData),
        messageType == .image || messageType == .video
      {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(height: 150)
          .frame(maxWidth: .infinity)
          .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
          .overlay(alignment: .center) {
            if messageType == .video {
              Image(systemName: "play.fill")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.black.opacity(0.48), in: Circle())
            }
          }
      }

      ZStack(alignment: .topLeading) {
        TextEditor(text: $text)
          .scrollContentBackground(.hidden)
          .frame(minHeight: messageType == .sticker || messageType == .reaction ? 74 : 130)
          .padding(AppSpacing.xs)

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(textEditorPlaceholder)
            .font(.body)
            .foregroundStyle(.secondary.opacity(0.72))
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .allowsHitTesting(false)
        }
      }
      .background(
        AppColors.panelBackground,
        in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

      if messageType == .reaction {
        TextField("Reaction label, e.g. ❤️", text: $reaction)
          .padding(AppSpacing.md)
          .background(
            AppColors.panelBackground,
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
      }
    }
  }

  private var timingSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      Text("Timing")
        .font(.headline)
      DatePicker("Message Time", selection: $createdAt, displayedComponents: [.hourAndMinute])
      Stepper(
        "Typing delay: \(typingDelay, specifier: "%.1f")s", value: $typingDelay, in: 0...8,
        step: 0.2)
    }
    .padding(AppSpacing.md)
    .background(
      AppColors.panelBackground,
      in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
  }

  private var receiptSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      Text("Delivery")
        .font(.headline)
      Picker("Read Receipt", selection: $readReceipt) {
        ForEach(ReadReceiptStatus.allCases) { status in
          Text(status.title).tag(status)
        }
      }
      .pickerStyle(.segmented)
      Toggle("Delivered", isOn: $isDelivered)
      Toggle("Seen", isOn: $isSeen)
    }
    .padding(AppSpacing.md)
    .background(
      AppColors.panelBackground,
      in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
  }

  private var contentLabel: String {
    switch messageType {
    case .image: return "Image and Caption"
    case .video: return "Video Thumbnail and Caption"
    case .timestamp: return "Separator Text"
    case .system: return "System Message"
    case .sticker: return "Sticker or Emoji"
    case .reaction: return "Reaction"
    default: return "Message Content"
    }
  }

  private func save() {
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let message = ChatMessage(
      id: existingMessage?.id ?? UUID(),
      characterID: selectedCharacterID,
      type: messageType,
      text: textForSavedMessage(cleanText),
      mediaData: mediaData,
      createdAt: createdAt,
      displayTime: ChatMessage.defaultTimeString(from: createdAt),
      readReceipt: readReceipt,
      typingDelay: typingDelay,
      reaction: reaction,
      isDelivered: isDelivered,
      isSeen: isSeen
    )
    onSave(message)
    dismiss()
  }

  private func defaultText(for type: MessageType) -> String {
    switch type {
    case .text: return "New message"
    case .image: return "Image message"
    case .video: return mediaData == nil ? "Video placeholder" : "Video message"
    case .voice: return "Voice note"
    case .typingIndicator: return "typing..."
    case .timestamp: return "Today"
    case .reaction: return reaction.isEmpty ? "❤️" : reaction
    case .missedCall: return "Missed call"
    case .system: return "Messages are end-to-end fictional."
    case .sticker: return "✨"
    }
  }

  private var textEditorPlaceholder: String {
    switch messageType {
    case .image:
      return "Add a caption for this photo..."
    case .video:
      return "Add a caption for this video..."
    case .reaction:
      return "Write the reaction label..."
    case .sticker:
      return "Emoji or sticker text..."
    case .timestamp:
      return "Today, Yesterday, or date..."
    case .system:
      return "System notice..."
    default:
      return "Write the message..."
    }
  }

  private func textForSavedMessage(_ cleanText: String) -> String {
    if messageType == .image || messageType == .video {
      return cleanText
    }
    return cleanText.isEmpty ? defaultText(for: messageType) : cleanText
  }

  private func clearLegacyMediaDefaultText() {
    let legacyDefaults = ["Image message", "Video message", "Video placeholder"]
    if legacyDefaults.contains(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
      text = ""
    }
  }

  @MainActor
  private func loadVideoThumbnail(from item: PhotosPickerItem?) async {
    guard let item else { return }
    isGeneratingVideoThumbnail = true
    defer { isGeneratingVideoThumbnail = false }

    guard let videoData = try? await item.loadTransferable(type: Data.self) else {
      return
    }
    mediaData = await VideoThumbnailGenerator.thumbnailJPEGData(from: videoData)
  }
}

private enum VideoThumbnailGenerator {
  static func thumbnailJPEGData(from data: Data) async -> Data? {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")

    do {
      try data.write(to: url, options: [.atomic])
      defer { try? FileManager.default.removeItem(at: url) }

      let asset = AVAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.maximumSize = CGSize(width: 900, height: 900)

      let preferredTime = CMTime(seconds: 0.6, preferredTimescale: 600)
      let image = try generator.copyCGImage(at: preferredTime, actualTime: nil)
      return UIImage(cgImage: image).jpegData(compressionQuality: 0.84)
    } catch {
      return nil
    }
  }
}
