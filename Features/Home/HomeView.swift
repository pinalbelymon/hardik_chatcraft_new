import SwiftUI
import UIKit

struct HomeView: View {
  var onNavigateToProjects: (() -> Void)? = nil
  @EnvironmentObject private var store: ChatStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @Environment(\.colorScheme) private var colorScheme
  @State private var showBuilder = false
  @State private var selectedTemplateThemeID: String?
  @State private var showPaywall = false
  @State private var showStyles = false
  @State private var navigationPath = NavigationPath()

  private let blue = Color(hex: "#087CFF")
  private var secondary: Color { colorScheme == .dark ? Color(hex: "#B8C2D2") : Color(hex: "#596575") }
  private var messageCount: Int { store.stories.reduce(0) { $0 + $1.messages.count } }
  private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      GeometryReader { geometry in
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            header
            createBanner
            if !store.stories.isEmpty {
              continueSection
            }
            VStack(spacing: 0) {
              statistics
              NativeAdSlot(topSpacing: 20)
            }
            stylesSection
          }
          .padding(.horizontal, 16)
          .padding(.top, 12)
          .padding(.bottom, 24)
          .frame(maxWidth: 860)
          .frame(maxWidth: .infinity)
        }
        .background(colorScheme == .dark ? Color(hex: "#101416") : Color(uiColor: .systemGroupedBackground))
      }
      .clipped()
      .background((colorScheme == .dark ? Color(hex: "#101416") : Color(uiColor: .systemGroupedBackground)).ignoresSafeArea())
      .trackScreen(.stories)
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: Binding(get: { showBuilder && !isPad }, set: { showBuilder = $0 })) {
        builder
      }
      .fullScreenCover(isPresented: Binding(get: { showBuilder && isPad }, set: { showBuilder = $0 })) {
        builder
      }
      .fullScreenCover(isPresented: $showPaywall) {
        NavigationStack { PaywallView() }
      }
      .sheet(isPresented: $showStyles) {
        NavigationStack {
          ScrollView {
            AdSupportedGrid(items: ChatTheme.all, columns: 2, spacing: 16) { theme in
                styleCard(theme) {
                  showStyles = false
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { createStory(themeID: theme.id) }
                }
            }.padding(16)
          }
          .detailAds()
          .trackScreen(.allStyles)
          .navigationTitle("All Styles")
          .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showStyles = false } } }
        }
      }
      .navigationDestination(for: UUID.self) { StoryWorkspaceView(storyID: $0) }
    }
  }

  private var header: some View {
    HStack {
      Text("Stories").font(.system(size: 38, weight: .bold))
      Spacer()
      Button { showPaywall = true } label: {
        Label(subscriptionManager.currentPlan.title, systemImage: "crown.fill")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(Color(hex: colorScheme == .dark ? "#FFB629" : "#996000"))
          .padding(.horizontal, 16).padding(.vertical, 12)
          .background(Color(hex: "#FFB629").opacity(0.10), in: Capsule())
          .overlay(Capsule().stroke(.primary.opacity(0.10)))
      }.buttonStyle(.plain)
    }.padding(.horizontal, 4).padding(.bottom, 2)
  }

  private var createBanner: some View {
    Button { createStory() } label: {
      HStack(spacing: 14) {
        Image(systemName: "plus.message.fill")
          .font(.system(size: 36, weight: .bold))
          .frame(width: 66, height: 70)
          .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
        VStack(alignment: .leading, spacing: 5) {
          Text("New Story").font(.system(size: 25, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
          Text("Start with quick setup").font(.system(size: 14)).lineLimit(1).minimumScaleFactor(0.75).opacity(0.88)
        }.layoutPriority(1)
        Spacer(minLength: 0)
        Label("Create", systemImage: "plus")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(blue)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.horizontal, 14).padding(.vertical, 13)
          .background(.white, in: Capsule())
      }
      .foregroundStyle(.white)
      .padding(18)
      .frame(maxWidth: .infinity, minHeight: 114)
      .background(LinearGradient(colors: [Color(hex: "#087CFF"), Color(hex: "#0060FF")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
    }.buttonStyle(InteractiveScaleButtonStyle())
  }

  private func sectionHeader(_ title: String, action: @escaping () -> Void) -> some View {
    HStack {
      Text(title).font(.system(size: 21, weight: .bold))
      Spacer()
      Button(action: action) {
        HStack(spacing: 6) { Text("See All"); Image(systemName: "chevron.right") }
          .font(.system(size: 14, weight: .semibold)).foregroundStyle(blue)
      }.buttonStyle(.plain)
    }.padding(.horizontal, 3)
  }

  private var continueSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Continue Editing") { onNavigateToProjects?() }
      if let story = store.stories.first {
        Button { navigationPath.append(story.id) } label: {
          HStack(alignment: .top, spacing: 14) {
            StoryIdentityMark(story: story)
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(story.title).font(.system(size: 19, weight: .bold)).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(secondary)
              }
              Text("Edited \(story.updatedAt.formatted(.relative(presentation: .numeric)))")
                .font(.system(size: 13)).foregroundStyle(secondary)
              ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                  Label("\(story.messages.count) messages", systemImage: "text.bubble.fill")
                  Text("·")
                  Label("\(story.characters.count) characters", systemImage: "person.2.fill")
                }
                HStack(spacing: 12) {
                  Label("\(story.messages.count)", systemImage: "text.bubble.fill")
                  Label("\(story.characters.count)", systemImage: "person.2.fill")
                }
              }.font(.system(size: 12)).foregroundStyle(secondary).padding(.top, 7)
              Label(story.theme.name, systemImage: "message.fill")
                .font(.system(size: 12)).foregroundStyle(secondary)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
          }.padding(16).frame(maxWidth: .infinity, alignment: .leading).homeCard()
        }.buttonStyle(InteractiveScaleButtonStyle()).foregroundStyle(.primary)
      }
    }
  }

  private var statistics: some View {
    HStack(spacing: 0) {
      Button { onNavigateToProjects?() } label: {
        stat(value: store.stories.count, title: "Projects", icon: "folder.fill", tint: blue)
      }.buttonStyle(.plain)
      Rectangle().fill(.primary.opacity(0.10)).frame(width: 1, height: 40)
      stat(value: messageCount, title: "Messages", icon: "text.bubble.fill", tint: Color(hex: "#00C99B"))
    }.padding(.vertical, 16).homeCard()
  }

  private func stat(value: Int, title: String, icon: String, tint: Color) -> some View {
    HStack(spacing: 18) {
      Image(systemName: icon).font(.system(size: 28)).foregroundStyle(tint)
      VStack(alignment: .leading, spacing: 2) {
        Text("\(value)").font(.system(size: 23, weight: .bold)).foregroundStyle(.primary)
        Text(title).font(.system(size: 14)).foregroundStyle(secondary)
      }
    }.frame(maxWidth: .infinity)
  }

  private var stylesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Popular Styles") { showStyles = true }
      HStack(alignment: .top, spacing: 10) {
        ForEach(Array(ChatTheme.all.prefix(2))) { theme in
          styleCard(theme) { createStory(themeID: theme.id) }
        }
      }
    }
  }

  private func styleCard(_ theme: ChatTheme, action: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      StoryArtwork(theme: theme, preview: true)
        .frame(height: 78).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.08)))
      Text(theme.id == "blue-bubble" ? "Apple Messages" : theme.name)
        .font(.system(size: 16, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
      Text(theme.id == "blue-bubble" ? "Classic iMessage style with blue and gray bubbles." : theme.id == "green-bubble" ? "Realistic WhatsApp style with green and white bubbles." : theme.subtitle)
        .font(.system(size: 12)).foregroundStyle(secondary).lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 48, alignment: .topLeading)
      Button(action: action) {
        Text("Use Style").font(.system(size: 14, weight: .semibold))
          .frame(maxWidth: .infinity).padding(.vertical, 11)
          .foregroundStyle(Color(hex: colorScheme == .dark ? "#64BBFF" : "#0065D1"))
          .background(blue.opacity(colorScheme == .dark ? 0.18 : 0.08), in: Capsule())
          .overlay(Capsule().stroke(blue.opacity(0.9), lineWidth: 0.7))
      }.buttonStyle(InteractiveScaleButtonStyle())
    }.padding(14).frame(maxWidth: .infinity, alignment: .leading).homeCard()
  }

  private var builder: some View {
    NavigationStack {
      StoryBuilderView(initialThemeID: selectedTemplateThemeID) { story in
        showBuilder = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { navigationPath.append(story.id) }
      }
    }
  }

  private func createStory(themeID: String? = nil) {
    selectedTemplateThemeID = themeID
    if subscriptionManager.canCreateStory(currentStoryCount: store.stories.count) { showBuilder = true }
    else { showPaywall = true }
  }
}

private struct StoryArtwork: View {
  let theme: ChatTheme
  var preview = false
  @Environment(\.colorScheme) private var colorScheme

  private var backgroundColors: [Color] {
    if colorScheme == .light {
      return theme.id == "green-bubble"
        ? [Color(hex: "#EDF4E8"), Color(hex: "#E1EBDD")]
        : [Color(hex: "#F3F6FA"), Color(hex: "#E8EDF4")]
    }
    return theme.id == "green-bubble"
      ? [Color(hex: "#102526"), Color(hex: "#172B2D")]
      : [Color(hex: "#262E37"), Color(hex: "#1E252D")]
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        if preview && theme.id == "green-bubble" {
          Canvas { context, size in
            for x in stride(from: 8.0, through: size.width, by: 22) {
              for y in stride(from: 6.0, through: size.height, by: 22) {
                let rect = CGRect(x: x, y: y, width: 12, height: 14)
                context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(colorScheme == .dark ? .white.opacity(0.06) : .black.opacity(0.05)), lineWidth: 1)
              }
            }
          }
        }
        VStack(spacing: 6) {
          bubble(color: Color(hex: theme.style.outgoingBubbleHex), width: geometry.size.width * 0.73, outgoing: true)
          bubble(color: Color(hex: theme.style.incomingBubbleHex), width: geometry.size.width * 0.57, outgoing: false)
          if !preview {
            bubble(color: Color(hex: theme.style.outgoingBubbleHex).opacity(0.7), width: geometry.size.width * 0.50, outgoing: true)
          }
        }.padding(12)
      }
    }.accessibilityHidden(true)
  }
  private func bubble(color: Color, width: CGFloat, outgoing: Bool) -> some View {
    HStack {
      if outgoing && preview { Spacer(minLength: 0) }
      RoundedRectangle(cornerRadius: preview ? 12 : 7)
        .fill(color).frame(width: width, height: preview ? 25 : 17)
        .overlay(alignment: .leading) {
          if !outgoing {
            Capsule().fill(Color.black.opacity(0.10)).frame(width: width * 0.65, height: 3).padding(.leading, 8)
          }
        }
      if !outgoing || !preview { Spacer(minLength: 0) }
    }
  }
}

private struct HomeCardModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  func body(content: Content) -> some View {
    content.background(colorScheme == .dark ? Color(hex: "#1D2227") : .white, in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(.primary.opacity(0.08), lineWidth: 0.7))
  }
}
private extension View {
  func homeCard() -> some View { modifier(HomeCardModifier()) }
}

// MARK: - Dedicated Projects Tab View
struct ProjectsView: View {
  @EnvironmentObject private var store: ChatStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager

  @State private var searchText = ""
  @State private var showBuilder = false
  @State private var showPaywall = false
  @State private var navigationPath = NavigationPath()

  private var isPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
  }

  private var isCompactDevice: Bool {
    DeviceSize.isCurrentCompactHeight
  }

  private var filteredStories: [ChatStory] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return store.stories }
    return store.stories.filter { story in
      story.title.localizedCaseInsensitiveContains(query)
        || story.theme.name.localizedCaseInsensitiveContains(query)
    }
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      GeometryReader { geometry in
        ScrollView {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
            searchField
            projectsSection(width: geometry.size.width)
          }
          .padding(.horizontal, DeviceSize.horizontalPadding(for: geometry.size.width))
          .padding(.vertical, isCompactDevice ? AppSpacing.xs : AppSpacing.sm)
          .frame(maxWidth: DeviceSize.contentMaxWidth(for: geometry.size.width))
          .frame(maxWidth: .infinity)
        }
        .background(PremiumBackdrop())
      }
      .trackScreen(.projects)
      .navigationTitle("Projects")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: AppSpacing.xs) {
            Button {
              createStory()
            } label: {
              Image(systemName: "plus")
                .font(.headline.weight(.heavy))
            }

            Button {
              showPaywall = true
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                Text(subscriptionManager.currentPlan.title)
              }
              .font(.caption.weight(.heavy))
            }
            .buttonStyle(.bordered)
            .tint(AppColors.amber)
          }
        }
      }
      .sheet(isPresented: builderSheetBinding) {
        storyBuilderNavigation
      }
      .fullScreenCover(isPresented: builderFullScreenBinding) {
        storyBuilderNavigation
      }
      .fullScreenCover(isPresented: $showPaywall) {
        NavigationStack { PaywallView() }
      }
      .navigationDestination(for: UUID.self) { storyID in
        StoryWorkspaceView(storyID: storyID)
      }
    }
  }

  private var builderSheetBinding: Binding<Bool> {
    Binding(
      get: { showBuilder && !isPad },
      set: { isPresented in
        if !isPresented { showBuilder = false }
      }
    )
  }

  private var builderFullScreenBinding: Binding<Bool> {
    Binding(
      get: { showBuilder && isPad },
      set: { isPresented in
        if !isPresented { showBuilder = false }
      }
    )
  }

  private var storyBuilderNavigation: some View {
    NavigationStack {
      StoryBuilderView { story in
        showBuilder = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          navigationPath.append(story.id)
        }
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: AppSpacing.sm) {
      Image(systemName: "magnifyingglass")
        .font(.subheadline.weight(.heavy))
        .foregroundStyle(AppColors.appTint)

      TextField("Search title or theme", text: $searchText)
        .textInputAutocapitalization(.words)
        .font(.subheadline.weight(.semibold))

      if !searchText.isEmpty {
        Button {
          searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, AppSpacing.md)
    .padding(.vertical, AppSpacing.sm)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
  }

  private func projectsSection(width: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      HStack {
        Text(searchText.isEmpty ? "All Projects" : "Results")
          .font(.headline.weight(.heavy))
        Text("\(filteredStories.count)")
          .font(.caption.weight(.heavy))
          .foregroundStyle(AppColors.appTint)
          .padding(.horizontal, AppSpacing.xs)
          .padding(.vertical, 4)
          .background(AppColors.appTint.opacity(0.1), in: Capsule())
        Spacer()
      }

      if filteredStories.isEmpty {
        EmptyStateView(
          title: searchText.isEmpty ? "No projects yet" : "No matching projects",
          message: searchText.isEmpty
            ? "Create your first chat story and it will appear here."
            : "Try another title or theme name.",
          systemImage: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
          actionTitle: searchText.isEmpty ? "Create Story" : "Clear Search"
        ) {
          if searchText.isEmpty {
            createStory()
          } else {
            searchText = ""
          }
        }
        .premiumSurface(cornerRadius: AppRadius.xl)
      } else {
        AdSupportedGrid(items: filteredStories, columns: projectColumns(width: width).count, spacing: AppSpacing.sm) { story in
            StoryProjectRow(
              story: story,
              duplicateAction: { store.duplicateStory(story) },
              deleteAction: { store.deleteStory(story) }
            )
        }
      }
    }
  }

  private func projectColumns(width: CGFloat) -> [GridItem] {
    let count = DeviceSize.category(for: width) == .iPad ? 2 : 1
    return Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: count)
  }

  private func createStory() {
    if subscriptionManager.canCreateStory(currentStoryCount: store.stories.count) {
      showBuilder = true
    } else {
      showPaywall = true
    }
  }
}

private struct StoryStatTile: View {
  let value: String
  let label: String
  let iconName: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      Image(systemName: iconName)
        .font(.caption.weight(.heavy))
        .frame(width: 28, height: 28)
        .foregroundStyle(tint)
        .background(
          tint.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
      Text(value)
        .font(.headline.weight(.heavy))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      Text(label)
        .font(.caption2.weight(.bold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.sm)
    .background(
      AppColors.panelBackground.opacity(0.62),
      in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
  }
}

private struct StoryProjectRow: View {
  let story: ChatStory
  let duplicateAction: () -> Void
  let deleteAction: () -> Void

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      NavigationLink(value: story.id) {
        HStack(spacing: AppSpacing.sm) {
          StoryIdentityMark(story: story)

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(story.title)
              .font(.headline.weight(.heavy))
              .foregroundStyle(.primary)
              .lineLimit(2)
              .minimumScaleFactor(0.88)
              .multilineTextAlignment(.leading)

            HStack(spacing: AppSpacing.xs) {
              StoryMetaChip(iconName: "text.bubble.fill", text: "\(story.messages.count)")
              StoryMetaChip(iconName: "person.2.fill", text: "\(story.characters.count)")
              StoryMetaChip(iconName: story.format.iconName, text: story.format.compactLabel)
            }

            HStack(spacing: AppSpacing.xs) {
              ThemeSwatches(theme: story.theme)
              Text(story.theme.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }

          Spacer(minLength: AppSpacing.xs)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Menu {
        Button {
          duplicateAction()
        } label: {
          Label("Duplicate Story", systemImage: "doc.on.doc")
        }

        Button(role: .destructive) {
          deleteAction()
        } label: {
          Label("Delete Story", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.headline.weight(.heavy))
          .frame(width: 40, height: 40)
          .foregroundStyle(.secondary)
          .background(AppColors.panelBackground.opacity(0.72), in: Circle())
      }
      .buttonStyle(.plain)
    }
    .padding(AppSpacing.sm)
    .background(
      .regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        .stroke(AppColors.hairline, lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.04), radius: 10, y: 6)
  }
}

extension StoryFormat {
  fileprivate var compactLabel: String {
    switch self {
    case .normalChat: return "Chat"
    case .storyPlayback: return "Playback"
    case .exportReady: return "Export"
    }
  }
}

private struct StoryIdentityMark: View {
  let story: ChatStory

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(hex: story.theme.style.accentHex).opacity(0.92),
              Color(hex: story.theme.style.wallpaperAccentHex).opacity(0.74),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 58, height: 58)

      VStack(spacing: -4) {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(.white.opacity(0.86))
          .frame(width: 30, height: 16)
          .offset(x: -4)
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(.white.opacity(0.72))
          .frame(width: 34, height: 16)
          .offset(x: 5)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Text("\(max(story.messages.count, 0))")
        .font(.caption2.weight(.heavy))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.32), in: Capsule())
        .offset(x: 5, y: 5)
    }
  }
}

private struct StoryMetaChip: View {
  let iconName: String
  let text: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: iconName)
        .font(.caption2.weight(.heavy))
      Text(text)
        .font(.caption2.weight(.heavy))
        .lineLimit(1)
    }
    .foregroundStyle(.secondary)
    .padding(.horizontal, 7)
    .padding(.vertical, 4)
    .background(AppColors.panelBackground.opacity(0.72), in: Capsule())
  }
}

private struct StoryThemeRow: View {
  let theme: ChatTheme

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      ThemeSwatches(theme: theme)
      Text(theme.name)
        .font(.caption.weight(.heavy))
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .minimumScaleFactor(0.86)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: AppSpacing.xs)
    }
    .padding(.horizontal, AppSpacing.sm)
    .padding(.vertical, AppSpacing.xs)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      AppColors.appTint.opacity(0.07),
      in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
        .stroke(AppColors.appTint.opacity(0.12), lineWidth: 1)
    )
  }
}

private struct ThemeSwatches: View {
  let theme: ChatTheme

  var body: some View {
    HStack(spacing: -3) {
      Circle()
        .fill(Color(hex: theme.style.outgoingBubbleHex))
      Circle()
        .fill(Color(hex: theme.style.incomingBubbleHex))
      Circle()
        .fill(Color(hex: theme.style.accentHex))
    }
    .frame(width: 34, height: 12)
    .overlay(Capsule().stroke(AppColors.hairline, lineWidth: 0.6))
  }
}
