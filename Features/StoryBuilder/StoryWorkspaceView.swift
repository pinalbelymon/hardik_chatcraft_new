import SwiftUI

enum StoryWorkspaceTab: String, CaseIterable, Identifiable {
  case editor
  case preview
  case export

  var id: String { rawValue }

  var title: String {
    switch self {
    case .editor: return "Editor"
    case .preview: return "Preview"
    case .export: return "Export"
    }
  }

  var compactTitle: String {
    title
  }

  var iconName: String {
    switch self {
    case .editor: return "pencil.and.outline"
    case .preview: return "play.fill"
    case .export: return "square.and.arrow.up.fill"
    }
  }

  var stepNumber: Int {
    switch self {
    case .editor: return 1
    case .preview: return 2
    case .export: return 3
    }
  }

  var guidance: String {
    switch self {
    case .editor: return "Write and manage conversation messages."
    case .preview: return "Play the story before sharing."
    case .export: return "Save an image or prepare a vertical video."
    }
  }

  var next: StoryWorkspaceTab? {
    StoryWorkspaceTab.allCases.first { $0.stepNumber == stepNumber + 1 }
  }
}

struct StoryWorkspaceView: View {
  @EnvironmentObject private var store: ChatStore
  @Environment(\.dismiss) private var dismiss
  let storyID: UUID

  @State private var story: ChatStory?
  @State private var selectedTab: StoryWorkspaceTab = .editor

  var body: some View {
    Group {
      if let binding = storyBinding {
        workspace(binding)
      } else {
        EmptyStateView(
          title: "Story not found", message: "This project may have been deleted.",
          systemImage: "exclamationmark.triangle"
        )
        .padding()
      }
    }
    .detailAds(bannerEnabled: selectedTab == .export)
    .navigationTitle(story?.title ?? "Story")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") { saveAndClose() }
          .accessibilityLabel("Save and close story")
      }
    }
    .onAppear {
      story = store.story(with: storyID)
    }
  }

  private func saveAndClose() {
    AppAnalytics.shared.track(.storyClose)
    if let story { store.updateStory(story) }
    dismiss()
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 500_000_000)
      guard !Task.isCancelled else { return }
      AdsController.shared.completedNaturalBreak()
    }
  }

  private var storyBinding: Binding<ChatStory>? {
    guard story != nil else { return nil }
    return Binding(
      get: { story! },
      set: { newValue in
        story = newValue
        store.updateStory(newValue)
      }
    )
  }

  private func workspace(_ story: Binding<ChatStory>) -> some View {
    GeometryReader { geometry in
      Group {
        if DeviceSize.category(for: geometry.size.width) == .iPad {
          HStack(spacing: 0) {
            sidebar
              .frame(width: 230)
              .background(.regularMaterial)
            Divider()
            tabContent(story)
          }
        } else {
          VStack(spacing: 0) {
            WorkspaceFlowBar(selectedTab: $selectedTab)
              .zIndex(20)
            tabContent(story)
              .zIndex(0)
          }
        }
      }
      .background(PremiumBackdrop())
    }
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      Text("Workspace")
        .font(.headline.weight(.bold))
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)

      ForEach(StoryWorkspaceTab.allCases) { tab in
        Button {
          selectedTab = tab
        } label: {
          HStack {
            Image(systemName: tab.iconName)
              .font(.caption.weight(.bold))
              .frame(width: 24)
              .foregroundStyle(selectedTab == tab ? AppColors.appTint : .secondary)
            Text(tab.title)
              .font(.subheadline.weight(.semibold))
            Spacer()
          }
          .padding(.horizontal, AppSpacing.md)
          .padding(.vertical, AppSpacing.sm)
          .background(
            selectedTab == tab ? AppColors.appTint.opacity(0.14) : Color.clear,
            in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
          )
          .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
              .stroke(selectedTab == tab ? AppColors.appTint.opacity(0.22) : .clear, lineWidth: 1)
          )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.sm)
      }
      Spacer()
    }
  }

  @ViewBuilder
  private func tabContent(_ story: Binding<ChatStory>) -> some View {
    switch selectedTab {
    case .editor:
      ChatEditorView(story: story)
    case .preview:
      PreviewModeView(story: story)
    case .export:
      ExportView(story: story)
    }
  }
}

private struct WorkspaceFlowBar: View {
  @Binding var selectedTab: StoryWorkspaceTab

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      ForEach(StoryWorkspaceTab.allCases) { tab in
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            selectedTab = tab
          }
        } label: {
          HStack(spacing: AppSpacing.xs) {
            Image(systemName: tab.iconName)
              .font(.caption.weight(.heavy))
            Text(tab.compactTitle)
              .font(.caption.weight(.heavy))
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 9)
          .foregroundStyle(selectedTab == tab ? .white : .secondary)
          .background(tabFill(tab), in: Capsule())
        }
        .buttonStyle(InteractiveScaleButtonStyle())
      }
    }
    .padding(.horizontal, AppSpacing.md)
    .padding(.top, AppSpacing.xs)
    .padding(.bottom, AppSpacing.sm)
  }

  private func tabFill(_ tab: StoryWorkspaceTab) -> AnyShapeStyle {
    if selectedTab == tab {
      return AnyShapeStyle(AppColors.appTint)
    }
    return AnyShapeStyle(Color.clear)
  }
}
