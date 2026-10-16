import SwiftUI
import UIKit

enum ExportScope: String, CaseIterable, Identifiable {
    case conversationArea
    case fullConversation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversationArea: return "Selected Area"
        case .fullConversation: return "Full Conversation"
        }
    }
}

private enum ExportedAssetKind {
    case image
    case video
}

struct ExportView: View {
    @Binding var story: ChatStory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showExportShare = false
    @State private var isExportVisible = false
    @State private var exportAdTask: Task<Void, Never>?
    @State private var selectedFormat: ExportFormat = .vertical916
    @State private var exportScope: ExportScope = .conversationArea
    @State private var includeWatermark = true
    @State private var exportedURL: URL?
    @State private var statusMessage: String?
    @State private var showPaywall = false
    @State private var isExporting = false
    @State private var selectedAreaScrollProgress: CGFloat = 0
    @State private var selectedAreaMeasuredTimelineHeight: CGFloat = 0
    @State private var exportedAssetKind: ExportedAssetKind?

    var body: some View {
        ResponsiveContainer(maxWidth: 980) { width in
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header(width: width)
                controls
                preview(width: width)
                exportActions
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationStack { PaywallView() }
        }
        .sheet(isPresented: $showExportShare) {
            if let exportedURL {
                AdExportShareSheet(url: exportedURL) { completed in
                    AppAnalytics.shared.track(.exportShareResult, ["completed": completed ? 1 : 0])
                    showExportShare = false
                }
            }
        }
        .onDisappear {
            isExportVisible = false
            exportAdTask?.cancel()
        }
        .background(PremiumBackdrop())
        .trackScreen(.export)
        .onAppear {
            isExportVisible = true
            includeWatermark = !subscriptionManager.canExportWithoutWatermark()
            selectedFormat = story.exportFormat
        }
        .onChange(of: selectedFormat) { value in
            AppAnalytics.shared.track(.exportOption, ["option": "format", "value": value.rawValue])
            selectedAreaScrollProgress = 0
            selectedAreaMeasuredTimelineHeight = 0
        }
        .onChange(of: exportScope) { value in
            AppAnalytics.shared.track(.exportOption, ["option": "scope", "value": value.rawValue])
            selectedAreaScrollProgress = 0
            selectedAreaMeasuredTimelineHeight = 0
        }
        .onChange(of: story.messages.count) { _ in
            selectedAreaScrollProgress = min(max(selectedAreaScrollProgress, 0), 1)
            selectedAreaMeasuredTimelineHeight = 0
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Export")
                .font(AppFont.title(width: width))
            Text("Render the fictional chat as a shareable image or prepare a vertical video flow.")
                .font(AppFont.body(width: width))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Export Options")
                .font(.headline.weight(.bold))

            Picker("Capture", selection: $exportScope) {
                ForEach(ExportScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Format")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: AppSpacing.sm) {
                    ForEach(ExportFormat.allCases) { format in
                        let locked = format != .vertical916 && !subscriptionManager.canUse(feature: .allExportFormats)
                        Button {
                            if locked {
                                AppAnalytics.shared.track(.featureLocked, ["source": "ExportView"])
                                showPaywall = true
                            } else {
                                selectedFormat = format
                                story.exportFormat = format
                            }
                        } label: {
                            VStack(spacing: AppSpacing.xxs) {
                                HStack(spacing: AppSpacing.xxs) {
                                    Text(format.title)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)
                                    if locked {
                                        Image(systemName: "lock.fill")
                                    }
                                }
                                Text(format.sizeLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.sm)
                            .background(selectedFormat == format ? AppColors.appTint.opacity(0.14) : AppColors.panelBackground, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .stroke(selectedFormat == format ? AppColors.appTint : AppColors.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle(isOn: watermarkBinding) {
                HStack {
                    Text("Watermark")
                    if !subscriptionManager.canExportWithoutWatermark() {
                        LockBadgeView(label: subscriptionManager.currentPlan.title)
                    }
                }
            }
        }
        .premiumSurface()
    }

    private func preview(width: CGFloat) -> some View {
        let isPad = DeviceSize.category(for: width) == .iPad
        let previewWidth =
            isPad
            ? max(420, min(width - (AppSpacing.xl * 2), 560))
            : min(width - AppSpacing.xl, 360)

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Export Preview")
                .font(.headline.weight(.bold))

            if exportScope == .conversationArea {
                ExportScrollableSnapshotPreview(
                    story: story,
                    width: previewWidth,
                    format: selectedFormat,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText,
                    scrollProgress: $selectedAreaScrollProgress,
                    measuredTimelineHeight: $selectedAreaMeasuredTimelineHeight
                )
                .environment(\.colorScheme, colorScheme)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: exportPreviewCornerRadius, style: .continuous)
                )
                .frame(maxWidth: .infinity, alignment: isPad ? .center : .leading)
            } else if isPad {
                ExportConversationSnapshotView(
                    story: story,
                    width: previewWidth,
                    format: selectedFormat,
                    scope: exportScope,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText
                )
                .environment(\.colorScheme, colorScheme)
                .frame(width: previewWidth)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: exportPreviewCornerRadius, style: .continuous)
                )
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    ExportConversationSnapshotView(
                        story: story,
                        width: previewWidth,
                        format: selectedFormat,
                        scope: exportScope,
                        includeWatermark: includeWatermark,
                        watermarkText: watermarkText
                    )
                    .environment(\.colorScheme, colorScheme)
                    .frame(width: previewWidth)
                }
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: exportPreviewCornerRadius, style: .continuous)
                )
            }
        }
    }

    private var exportPreviewCornerRadius: CGFloat {
        0
    }

    private var exportActions: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: isExporting ? "Rendering..." : "Export as Image", iconName: "photo.on.rectangle.angled", isEnabled: !isExporting) {
                Task { await exportImage() }
            }

            Button {
                Task { await exportVideo() }
            } label: {
                Label(isExporting ? "Rendering Video..." : "Export Story Video", systemImage: "video.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .foregroundStyle(subscriptionManager.canUse(feature: .videoExport) && !isExporting ? AppColors.appTint : .secondary)
                    .background(AppColors.appTint.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isExporting)

            if exportedURL != nil {
                Button {
                    AppAnalytics.shared.track(.exportShareOpen, ["media_type": exportedAssetKind == .video ? "video" : "image"])
                    showExportShare = true
                } label: {
                    Label(shareButtonTitle, systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.success.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var watermarkBinding: Binding<Bool> {
        Binding(
            get: { includeWatermark || !subscriptionManager.canExportWithoutWatermark() },
            set: { newValue in
                if subscriptionManager.canExportWithoutWatermark() {
                    includeWatermark = newValue
                } else {
                    includeWatermark = true
                    AppAnalytics.shared.track(.featureLocked, ["source": "ExportView"])
                    showPaywall = true
                }
            }
        )
    }

    private var watermarkText: String? {
        includeWatermark ? (subscriptionManager.watermarkLabel() ?? "ChatCraft") : nil
    }

    private var shareButtonTitle: String {
        exportedAssetKind == .video ? "Share Exported Video" : "Share Exported Image"
    }

    @MainActor
    private func exportImage() async {
        let analyticsStart = Date()
        AppAnalytics.shared.track(.exportStart, ["media_type": "image", "format": selectedFormat.rawValue, "scope": exportScope.rawValue, "message_count": story.messages.count])
        isExporting = true
        defer { isExporting = false }

        let layoutWidth = exportLayoutWidth
        let renderScale = exportPixelSize.width / layoutWidth
        let selectedAreaScrollOffset =
            exportScope == .conversationArea
            ? selectedAreaScrollProgress
                * ExportSnapshotMetrics.maxScrollOffset(
                    story: story,
                    width: layoutWidth,
                    format: selectedFormat,
                    measuredTimelineHeight: selectedAreaMeasuredTimelineHeight
                )
            : 0
        let view = ExportConversationSnapshotView(
            story: story,
            width: layoutWidth,
            format: selectedFormat,
            scope: exportScope,
            includeWatermark: includeWatermark,
            watermarkText: watermarkText,
            scrollOffset: selectedAreaScrollOffset
        )
        .environment(\.colorScheme, colorScheme)
        .frame(width: layoutWidth)

        do {
            exportedURL = try ScreenshotExportService.export(
                view: view,
                format: selectedFormat,
                fileName: story.title,
                scale: renderScale
            )
            exportedAssetKind = .image
            AppAnalytics.shared.track(.exportSuccess, ["media_type": "image", "format": selectedFormat.rawValue, "scope": exportScope.rawValue, "duration_ms": Int(Date().timeIntervalSince(analyticsStart) * 1000)])
            statusMessage = "Image export is ready."
            scheduleExportAd()
        } catch {
            AppAnalytics.shared.track(.exportFailure, ["media_type": "image", "reason": "render_failed"])
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func scheduleExportAd() {
        exportAdTask?.cancel()
        exportAdTask = Task { @MainActor in
            // Let the completed export update its UI; never wait for ad inventory.
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled, isExportVisible, !isExporting, !showExportShare else { return }
            AdsController.shared.completedNaturalBreak()
        }
    }

    private var exportLayoutWidth: CGFloat {
        393
    }

    private var exportPixelSize: CGSize {
        switch selectedFormat {
        case .vertical916:
            return CGSize(width: 1080, height: 1920)
        case .square11:
            return CGSize(width: 1080, height: 1080)
        case .portrait45:
            return CGSize(width: 1080, height: 1350)
        }
    }

    @MainActor
    private func exportVideo() async {
        guard subscriptionManager.canUse(feature: .videoExport) else {
            AppAnalytics.shared.track(.featureLocked, ["source": "ExportView"])
            showPaywall = true
            return
        }

        let analyticsStart = Date()
        AppAnalytics.shared.track(.exportStart, ["media_type": "video", "format": selectedFormat.rawValue, "message_count": story.messages.count])
        isExporting = true
        defer { isExporting = false }

        do {
            let frames = try renderVideoFrames()
            exportedURL = try await VideoExportService().exportVideo(
                frames: frames,
                format: selectedFormat,
                fileName: story.title
            )
            exportedAssetKind = .video
            AppAnalytics.shared.track(.exportSuccess, ["media_type": "video", "format": selectedFormat.rawValue, "duration_ms": Int(Date().timeIntervalSince(analyticsStart) * 1000)])
            statusMessage = "Video export is ready."
            scheduleExportAd()
        } catch {
            AppAnalytics.shared.track(.exportFailure, ["media_type": "video", "reason": "render_failed"])
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func renderVideoFrames() throws -> [UIImage] {
        let layoutWidth = exportLayoutWidth
        let renderScale = exportPixelSize.width / layoutWidth
        let messages = story.messages
        let revealSteps = max(messages.count, 1)

        var frames: [UIImage] = []
        frames.reserveCapacity(revealSteps + 1)

        for revealIndex in 0...revealSteps {
            var frameStory = story
            if messages.isEmpty {
                frameStory.messages = []
            } else {
                frameStory.messages = Array(messages.prefix(min(revealIndex, messages.count)))
            }

            let scrollOffset = ExportSnapshotMetrics.maxScrollOffset(
                story: frameStory,
                width: layoutWidth,
                format: selectedFormat
            )

            let view = ExportConversationSnapshotView(
                story: frameStory,
                width: layoutWidth,
                format: selectedFormat,
                scope: .conversationArea,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText,
                scrollOffset: scrollOffset
            )
            .environment(\.colorScheme, colorScheme)
            .frame(width: layoutWidth)

            let renderer = ImageRenderer(content: view)
            renderer.scale = renderScale

            guard let image = renderer.uiImage else {
                throw ExportError.renderFailed
            }

            frames.append(image)
        }

        return frames
    }
}

private struct ExportScrollableSnapshotPreview: View {
    let story: ChatStory
    let width: CGFloat
    let format: ExportFormat
    let includeWatermark: Bool
    let watermarkText: String?
    @Binding var scrollProgress: CGFloat
    @Binding var measuredTimelineHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var viewportHeight: CGFloat {
        ExportSnapshotMetrics.selectedAreaHeight(width: width, format: format)
    }

    private var maxScrollOffset: CGFloat {
        ExportSnapshotMetrics.maxScrollOffset(
            story: story,
            width: width,
            format: format,
            measuredTimelineHeight: measuredTimelineHeight
        )
    }

    private var scrollOffset: CGFloat {
        maxScrollOffset * min(max(scrollProgress, 0), 1)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ExportConversationSnapshotView(
                story: story,
                width: width,
                format: format,
                scope: .conversationArea,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText,
                scrollOffset: scrollOffset,
                maxScrollOffsetOverride: maxScrollOffset,
                onTimelineHeightChange: { height in
                    measuredTimelineHeight = height
                }
            )
            .environment(\.colorScheme, colorScheme)
            .allowsHitTesting(false)

            if maxScrollOffset > 1 {
                scrollControls
                    .padding(.trailing, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .frame(width: width, height: viewportHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous))
    }

    private var previewCornerRadius: CGFloat {
        0
    }

    private var scrollControls: some View {
        VStack(spacing: 8) {
            scrollButton(systemName: "chevron.up", direction: -1)
                .disabled(scrollProgress <= 0.001)
                .opacity(scrollProgress <= 0.001 ? 0.42 : 1)

            scrollButton(systemName: "chevron.down", direction: 1)
                .disabled(scrollProgress >= 0.999)
                .opacity(scrollProgress >= 0.999 ? 0.42 : 1)
        }
        .padding(6)
        .background(Color.black.opacity(0.48), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }

    private func scrollButton(systemName: String, direction: CGFloat) -> some View {
        Button {
            movePreview(direction: direction)
        } label: {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction < 0 ? "Move preview up" : "Move preview down")
    }

    private func movePreview(direction: CGFloat) {
        guard maxScrollOffset > 1 else { return }
        let pointStep: CGFloat = 140
        let progressStep = min(0.28, max(0.08, pointStep / maxScrollOffset))
        let nextProgress = min(max(scrollProgress + (direction * progressStep), 0), 1)
        withAnimation(.easeInOut(duration: 0.2)) {
            scrollProgress = nextProgress
        }
    }
}

private struct ExportTimelineHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private enum ExportSnapshotMetrics {
    static func selectedAreaHeight(width: CGFloat, format: ExportFormat) -> CGFloat {
        width / format.aspectRatio
    }

    static func height(story: ChatStory, width: CGFloat, format: ExportFormat, scope: ExportScope) -> CGFloat {
        switch scope {
        case .conversationArea:
            return selectedAreaHeight(width: width, format: format)
        case .fullConversation:
            return headerReserve(theme: story.theme)
                + estimatedTimelineHeight(story: story, width: width)
                + composerReserve(theme: story.theme)
        }
    }

    static func messageAreaHeight(story: ChatStory, width: CGFloat, format: ExportFormat, scope: ExportScope) -> CGFloat {
        max(
            0,
            height(story: story, width: width, format: format, scope: scope)
                - headerReserve(theme: story.theme)
                - composerReserve(theme: story.theme)
        )
    }

    static func maxScrollOffset(story: ChatStory, width: CGFloat, format: ExportFormat) -> CGFloat {
        return maxScrollOffset(story: story, width: width, format: format, measuredTimelineHeight: 0)
    }

    static func maxScrollOffset(
        story: ChatStory,
        width: CGFloat,
        format: ExportFormat,
        measuredTimelineHeight: CGFloat
    ) -> CGFloat {
        let timelineHeight =
            measuredTimelineHeight > 1
            ? measuredTimelineHeight
            : estimatedTimelineHeight(story: story, width: width)
        let naturalOffset =
            timelineHeight
            - messageAreaHeight(story: story, width: width, format: format, scope: .conversationArea)

        return max(0, naturalOffset - selectedAreaEndSlackTrim(story: story, width: width))
    }

    static func selectedAreaEndSlackTrim(story: ChatStory, width: CGFloat) -> CGFloat {
        guard story.theme.isPaperPlaneStyleTheme, story.messages.isEmpty == false else {
            return 0
        }

        return min(max(width * 0.32, 84), 132)
    }

    static func composerReserve(theme: ChatTheme) -> CGFloat {
        if theme.isWhatsAppStyleTheme {
            return 66
        }
        if theme.isPaperPlaneStyleTheme {
            return 62
        }
        if theme.isGradientDMStyleTheme || theme.isSocialMetaStyleTheme {
            return 60
        }
        if theme.isSnapStyleTheme {
            return 54
        }
        return 60
    }

    static func headerReserve(theme: ChatTheme) -> CGFloat {
        if theme.isWhatsAppStyleTheme {
            return 58
        }
        if theme.isPaperPlaneStyleTheme {
            return 64
        }
        if theme.isGradientDMStyleTheme {
            return 70
        }
        if theme.isSocialMetaStyleTheme {
            return 56
        }
        if theme.isSnapStyleTheme {
            return 60
        }
        return 60
    }

    static func estimatedTimelineHeight(story: ChatStory, width: CGFloat) -> CGFloat {
        let messageHeights = story.messages.reduce(CGFloat.zero) { total, message in
            total + estimatedHeight(for: message, width: width, theme: story.theme)
        }
        let spacing = CGFloat(max(story.messages.count - 1, 0)) * story.theme.compactMessageSpacing
        return AppSpacing.md + messageHeights + spacing + AppSpacing.md
    }

    static func estimatedHeight(for message: ChatMessage, width: CGFloat, theme: ChatTheme) -> CGFloat {
        switch message.type {
        case .image:
            return estimatedMediaHeight(for: message, width: width, theme: theme, isVideo: false)
        case .video:
            return estimatedMediaHeight(for: message, width: width, theme: theme, isVideo: true)
        case .voice:
            return 72
        case .typingIndicator:
            return 54
        case .timestamp, .system:
            return 46
        case .reaction, .sticker:
            return 64
        case .missedCall:
            return 58
        case .text:
            if theme.isWhatsAppStyleTheme {
                let charactersPerLine = max(Int(DeviceSize.chatBubbleMaxWidth(for: width) / 9.8), 16)
                let lines = max(1, Int(ceil(Double(message.text.count) / Double(charactersPerLine))))
                return CGFloat(lines) * 21 + 28
            }
            let charactersPerLine = max(Int(DeviceSize.chatBubbleMaxWidth(for: width) / 9.5), 18)
            let lines = max(1, Int(ceil(Double(message.text.count) / Double(charactersPerLine))))
            return CGFloat(lines) * 25 + 36
        }
    }

    static func estimatedMediaHeight(
        for message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        isVideo: Bool
    ) -> CGFloat {
        let bubbleMaxWidth = DeviceSize.chatBubbleMaxWidth(for: width)
        let mediaWidth: CGFloat
        if theme.isSnapStyleTheme {
            mediaWidth = snapMediaWidth(for: bubbleMaxWidth)
        } else {
            mediaWidth = min(bubbleMaxWidth, theme.isGradientDMStyleTheme ? 254 : 312)
        }
        let defaultRatio: CGFloat = isVideo ? 1.12 : 0.78
        let ratio: CGFloat
        if let data = message.mediaData, let image = UIImage(data: data) {
            ratio = min(
                max(image.size.height / max(image.size.width, 1), isVideo ? 0.76 : 0.58),
                isVideo ? 1.36 : 1.42
            )
        } else {
            ratio = defaultRatio
        }
        let captionReserve: CGFloat =
            theme.isSnapStyleTheme
            ? (message.text.isEmpty ? 34 : 72)
            : (message.text.isEmpty ? 18 : 56)
        return mediaWidth * ratio + captionReserve
    }

    static func snapMediaWidth(for bubbleMaxWidth: CGFloat) -> CGFloat {
        guard bubbleMaxWidth >= 180 else {
            return bubbleMaxWidth * 0.94
        }

        let widthCap: CGFloat = bubbleMaxWidth > 420 ? 320 : 258
        return max(184, min(bubbleMaxWidth * 0.78, widthCap))
    }
}

struct ExportConversationSnapshotView: View {
    let story: ChatStory
    let width: CGFloat
    let format: ExportFormat
    let scope: ExportScope
    let includeWatermark: Bool
    let watermarkText: String?
    var scrollOffset: CGFloat = 0
    var maxScrollOffsetOverride: CGFloat? = nil
    var onTimelineHeightChange: ((CGFloat) -> Void)? = nil

    private var theme: ChatTheme { story.theme }
    @Environment(\.colorScheme) private var colorScheme

    private var height: CGFloat {
        ExportSnapshotMetrics.height(story: story, width: width, format: format, scope: scope)
    }

    var body: some View {
        snapshotContent
        .frame(width: width, height: fixedSnapshotHeight, alignment: .top)
        .background(background)
        .overlay(alignment: .bottom) {
            composerOverlay
        }
        .clipShape(RoundedRectangle(cornerRadius: snapshotCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: snapshotCornerRadius, style: .continuous)
                .stroke(AppColors.hairline, lineWidth: 1)
        )
        .onPreferenceChange(ExportTimelineHeightPreferenceKey.self) { height in
            onTimelineHeightChange?(height)
        }
    }

    private var fixedSnapshotHeight: CGFloat? {
        scope == .conversationArea ? height : nil
    }

    private var snapshotCornerRadius: CGFloat {
        0
    }

    private var snapshotContent: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                story: story,
                theme: theme,
                showsControls: true,
                cornerRadius: snapshotCornerRadius,
                roundedCorners: [.topLeft, .topRight]
            )
            .frame(height: headerReserve)
            .clipped()

            messageArea

            composerBackgroundColor
                .frame(height: composerReserve)
        }
    }

    @ViewBuilder
    private var messageArea: some View {
        if scope == .fullConversation {
            messageTimeline
                .frame(maxWidth: .infinity, alignment: .top)
                .background(background)
                .clipped()
        } else {
            ZStack(alignment: .top) {
                messageTimeline
                    .offset(y: -effectiveScrollOffset)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: messageAreaHeight,
                maxHeight: messageAreaHeight,
                alignment: .top
            )
            .background(background)
            .clipped()
        }
    }

    private var messageTimeline: some View {
        VStack(spacing: theme.compactMessageSpacing) {
            ForEach(Array(story.messages.enumerated()), id: \.element.id) { index, message in
                if let character = character(for: message) {
                    let group = messageGroup(at: index, in: story.messages)
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
        }
        .padding(.top, AppSpacing.md)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: ExportTimelineHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
            }
        }
    }

    private var composerOverlay: some View {
        ZStack {
            composerBackgroundColor

            ChatInputBarPreview(
                theme: theme,
                placeholder: theme.inputPlaceholder,
                roundedCorners: [.bottomLeft, .bottomRight],
                cornerRadius: snapshotCornerRadius,
                isDockedInChatFrame: true
            )
        }
        .overlay(alignment: .bottomTrailing) {
            if includeWatermark, let watermarkText {
                Text(watermarkText)
                    .font(.system(size: width * 0.026, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, width * 0.024)
                    .padding(.vertical, width * 0.011)
                    .background(Color.black.opacity(0.48), in: Capsule())
                    .padding(.trailing, width * 0.026)
                    .padding(.bottom, width * 0.018)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: composerReserve, alignment: .center)
        .background(
            composerBackgroundColor,
            in: RoundedCornerShape(radius: snapshotCornerRadius, corners: [.bottomLeft, .bottomRight])
        )
    }

    private var composerReserve: CGFloat {
        ExportSnapshotMetrics.composerReserve(theme: theme)
    }

    private var headerReserve: CGFloat {
        ExportSnapshotMetrics.headerReserve(theme: theme)
    }

    private var messageAreaHeight: CGFloat {
        ExportSnapshotMetrics.messageAreaHeight(story: story, width: width, format: format, scope: scope)
    }

    private var effectiveScrollOffset: CGFloat {
        guard scope == .conversationArea else { return 0 }
        let limit =
            maxScrollOffsetOverride
            ?? ExportSnapshotMetrics.maxScrollOffset(story: story, width: width, format: format)
        return min(
            max(scrollOffset, 0),
            limit
        )
    }

    private var estimatedTimelineHeight: CGFloat {
        ExportSnapshotMetrics.estimatedTimelineHeight(story: story, width: width)
    }

    private func estimatedHeight(for message: ChatMessage) -> CGFloat {
        switch message.type {
        case .image:
            return estimatedMediaHeight(for: message, isVideo: false)
        case .video:
            return estimatedMediaHeight(for: message, isVideo: true)
        case .voice:
            return 72
        case .typingIndicator:
            return 54
        case .timestamp, .system:
            return 46
        case .reaction, .sticker:
            return 64
        case .missedCall:
            return 58
        case .text:
            if theme.isWhatsAppStyleTheme {
                let charactersPerLine = max(Int(DeviceSize.chatBubbleMaxWidth(for: width) / 9.8), 16)
                let lines = max(1, Int(ceil(Double(message.text.count) / Double(charactersPerLine))))
                return CGFloat(lines) * 21 + 28
            }
            let charactersPerLine = max(Int(DeviceSize.chatBubbleMaxWidth(for: width) / 9.5), 18)
            let lines = max(1, Int(ceil(Double(message.text.count) / Double(charactersPerLine))))
            return CGFloat(lines) * 25 + 36
        }
    }

    private func estimatedMediaHeight(for message: ChatMessage, isVideo: Bool) -> CGFloat {
        let bubbleMaxWidth = DeviceSize.chatBubbleMaxWidth(for: width)
        let mediaWidth: CGFloat
        if theme.isSnapStyleTheme {
            mediaWidth = ExportSnapshotMetrics.snapMediaWidth(for: bubbleMaxWidth)
        } else {
            mediaWidth = min(bubbleMaxWidth, theme.isGradientDMStyleTheme ? 254 : 312)
        }
        let defaultRatio: CGFloat = isVideo ? 1.12 : 0.78
        let ratio: CGFloat
        if let data = message.mediaData, let image = UIImage(data: data) {
            ratio = min(max(image.size.height / max(image.size.width, 1), isVideo ? 0.76 : 0.58), isVideo ? 1.36 : 1.42)
        } else {
            ratio = defaultRatio
        }
        let captionReserve: CGFloat =
            theme.isSnapStyleTheme
            ? (message.text.isEmpty ? 34 : 72)
            : (message.text.isEmpty ? 18 : 56)
        return mediaWidth * ratio + captionReserve
    }

    private var composerBackgroundColor: Color {
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
            return colorScheme == .dark
                ? Color(hex: "#05060B").opacity(0.98)
                : Color.clear
        }
        if theme.isSnapStyleTheme {
            return colorScheme == .dark ? Color(hex: "#070A10") : .white
        }
        return Color(hex: colorScheme == .dark ? theme.style.darkInputBarHex : theme.style.inputBarHex)
    }

    private var background: some View {
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
