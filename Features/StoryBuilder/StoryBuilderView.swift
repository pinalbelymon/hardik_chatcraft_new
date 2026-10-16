import SwiftUI
import UIKit

struct StoryBuilderView: View {
    @EnvironmentObject private var store: ChatStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("chatcraft_default_theme") private var defaultThemeID = ChatTheme.defaultThemeID
    @AppStorage("chatcraft_default_export_format") private var defaultExportFormatRawValue = ExportFormat.vertical916.rawValue

    var initialThemeID: String? = nil
    var onCreated: ((ChatStory) -> Void)? = nil

    @State private var title = ""
    @State private var selectedThemeID: String
    @State private var storyFormat: StoryFormat = .normalChat
    @State private var didLoadDefaultTheme = false
    @State private var characters: [ChatCharacter] = [
        ChatCharacter(name: "You", avatarSymbol: "person.crop.circle", bubbleColorHex: "#198CFF", side: .right),
        ChatCharacter(name: "Avery", avatarSymbol: "sparkles", bubbleColorHex: "#E9ECF2", textColorHex: "#151820", side: .left)
    ]
    @State private var showPaywall = false

    init(initialThemeID: String? = nil, onCreated: ((ChatStory) -> Void)? = nil) {
        self.initialThemeID = initialThemeID
        self.onCreated = onCreated
        let fallback = initialThemeID ?? ChatTheme.defaultThemeID
        _selectedThemeID = State(initialValue: ChatTheme.normalizedID(for: fallback))
    }

    private var selectedTheme: ChatTheme { ChatTheme.theme(for: selectedThemeID) }
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var isCompactDevice: Bool { DeviceSize.isCurrentCompactHeight }
    private var builderMaxWidth: CGFloat { isPad ? 1180 : 920 }

    private var featuredThemes: [ChatTheme] {
        let selectedID = ChatTheme.normalizedID(for: selectedThemeID)
        let defaults = ["blue-bubble", "green-bubble", "gradient-bubble", "snap-style", "social-blue", "paper-plane"]
        let featuredIDs = [selectedID] + defaults.filter { $0 != selectedID }
        return featuredIDs.compactMap { id in
            ChatTheme.all.first { $0.id == id }
        }
    }

    var body: some View {
        ResponsiveContainer(maxWidth: builderMaxWidth) { width in
            VStack(alignment: .leading, spacing: isCompactDevice ? AppSpacing.sm : AppSpacing.md) {
                header(width: width)
                titleSection
                themeTemplateSection
                castSection
                formatSection
                createButton
            }
        }
        .detailAds()
        .trackScreen(.storyBuilder)
        .navigationTitle("New Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationStack { PaywallView() }
        }
        .background(PremiumBackdrop())
        .onAppear {
            guard !didLoadDefaultTheme else { return }
            didLoadDefaultTheme = true
            if let initialThemeID {
                selectedThemeID = ChatTheme.normalizedID(for: initialThemeID)
            } else {
                selectedThemeID = ChatTheme.normalizedID(for: defaultThemeID)
            }
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Create Story")
                .font(AppFont.font(isCompactDevice ? 26 : 32, weight: .heavy, width: width))

            Text("Choose a style and start writing your conversation instantly.")
                .font(AppFont.caption(width: width))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Story Title")
                .font(.headline.weight(.bold))

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "pencil")
                    .foregroundStyle(AppColors.appTint)
                TextField("e.g., Secret Project, Catching Up...", text: $title)
                    .textInputAutocapitalization(.words)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(isCompactDevice ? AppSpacing.sm : AppSpacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColors.hairline, lineWidth: 1)
            )
        }
    }

    private var themeTemplateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Chat Style Template")
                    .font(.headline.weight(.bold))
                Spacer()
                NavigationLink {
                    ThemeSelectionView(selectedThemeID: $selectedThemeID)
                } label: {
                    HStack(spacing: 4) {
                        Text("All Themes")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.appTint)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(featuredThemes) { theme in
                        let isSelected = selectedThemeID == theme.id
                        let isLocked = !subscriptionManager.canUseTheme(theme)

                        Button {
                            if isLocked {
                                AppAnalytics.shared.track(.featureLocked, ["source": "StoryBuilderView"])
                                showPaywall = true
                            } else {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    AppAnalytics.shared.track(.themeSelect, ["theme_id": theme.id, "source": "story_builder"])
                                    selectedThemeID = theme.id
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: theme.style.accentHex))
                                        .frame(width: 12, height: 12)

                                    HStack(spacing: 3) {
                                        Capsule()
                                            .fill(Color(hex: theme.style.incomingBubbleHex))
                                            .frame(width: 20, height: 8)
                                        Capsule()
                                            .fill(Color(hex: theme.style.outgoingBubbleHex))
                                            .frame(width: 26, height: 8)
                                    }

                                    Spacer(minLength: 0)

                                    if isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                                    } else if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }

                                Text(theme.name)
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(AppSpacing.sm)
                            .frame(width: 168, height: 78, alignment: .leading)
                            .background(
                                isSelected ? AnyShapeStyle(AppColors.brandGradient) : AnyShapeStyle(.regularMaterial),
                                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                    .stroke(isSelected ? Color.white.opacity(0.3) : AppColors.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(InteractiveScaleButtonStyle())
                    }
                }
            }
            .id(selectedThemeID)
        }
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Cast / Characters")
                    .font(.headline.weight(.bold))
                Spacer()
                Button {
                    addCharacter()
                } label: {
                    Label("Add Character", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.mint)
                }
                .disabled(!subscriptionManager.canAddCharacter(currentCharacterCount: characters.count))
            }

            ForEach($characters) { $character in
                let accent = resolvedCharacterColor(character)

                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(accent)
                            .frame(width: 34, height: 34)

                        Image(systemName: character.avatarSymbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: accent.opacity(0.35), radius: 4, y: 2)

                    TextField("Name", text: $character.name)
                        .textInputAutocapitalization(.words)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)

                    Picker("Side", selection: $character.side) {
                        ForEach(SenderSide.allCases) { side in
                            Text(side.title).tag(side)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(AppColors.appTint)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .stroke(AppColors.hairline, lineWidth: 1)
                )
            }
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Format")
                    .font(.headline.weight(.bold))
                Spacer()
                Text(storyFormat.title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(AppColors.appTint)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 3),
                spacing: AppSpacing.xs
            ) {
                ForEach(StoryFormat.allCases) { format in
                    let isSelected = storyFormat == format
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            storyFormat = format
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: format.iconName)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(isSelected ? .white : AppColors.appTint)
                                .frame(height: 22)

                            Text(format.title)
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            Text(formatShortGuidance(for: format))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.vertical, 9)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(
                            isSelected ? AnyShapeStyle(AppColors.brandGradient) : AnyShapeStyle(.regularMaterial),
                            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.25) : AppColors.hairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(InteractiveScaleButtonStyle())
                }
            }
        }
    }

    private func formatShortGuidance(for format: StoryFormat) -> String {
        switch format {
        case .normalChat: return "Standard Chat"
        case .storyPlayback: return "Auto-revealing"
        case .exportReady: return "Video & Reels"
        }
    }

    private var createButton: some View {
        PrimaryButton(
            title: "Create & Start Writing",
            iconName: "arrow.right",
            iconPlacement: .trailing,
            isEnabled: canCreate
        ) {
            saveStory()
        }
        .padding(.top, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
    }

    private var canCreate: Bool {
        subscriptionManager.canUseTheme(selectedTheme) &&
        !characters.isEmpty &&
        characters.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func addCharacter() {
        guard subscriptionManager.canAddCharacter(currentCharacterCount: characters.count) else {
            AppAnalytics.shared.track(.featureLocked, ["source": "StoryBuilderView"])
            showPaywall = true
            return
        }
        AppAnalytics.shared.track(.characterAdd, ["character_count": characters.count + 1, "source": "story_builder"])
        characters.append(
            ChatCharacter(
                name: "Character \(characters.count + 1)",
                avatarSymbol: ChatCharacter.avatarSymbols[characters.count % ChatCharacter.avatarSymbols.count],
                bubbleColorHex: "#4F7CFF",
                side: characters.count.isMultiple(of: 2) ? .left : .right
            )
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
        let incomingIndex = characters.firstIndex(where: { $0.id == character.id }) ?? 1
        let palette = [
            Color(hex: "#10B981"),
            Color(hex: "#8B5CF6"),
            Color(hex: "#F97316"),
            Color(hex: "#EC4899"),
            Color(hex: "#06B6D4"),
            Color(hex: "#EAB308")
        ]
        return palette[incomingIndex % palette.count]
    }

    private func characterBubbleColorHex(_ character: ChatCharacter) -> String {
        if let custom = character.customBubbleColorHex {
            return custom
        }
        if colorScheme == .dark {
            return character.side == .right ? selectedTheme.style.outgoingDarkBubbleHex : selectedTheme.style.incomingDarkBubbleHex
        }
        return character.side == .right ? selectedTheme.style.outgoingBubbleHex : selectedTheme.style.incomingBubbleHex
    }

    private func saveStory() {
        guard subscriptionManager.canCreateStory(currentStoryCount: store.stories.count) else {
            AppAnalytics.shared.track(.featureLocked, ["source": "StoryBuilderView"])
            showPaywall = true
            return
        }

        guard subscriptionManager.canUseTheme(selectedTheme) else {
            AppAnalytics.shared.track(.featureLocked, ["source": "StoryBuilderView"])
            showPaywall = true
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = cleanTitle.isEmpty ? "New Story" : cleanTitle
        let story = ChatStory(
            title: finalTitle,
            themeID: ChatTheme.normalizedID(for: selectedThemeID),
            characters: characters,
            format: storyFormat,
            exportFormat: ExportFormat(rawValue: defaultExportFormatRawValue) ?? .vertical916
        )
        store.addStory(story)
        if let onCreated {
            onCreated(story)
        } else {
            dismiss()
        }
    }
}
