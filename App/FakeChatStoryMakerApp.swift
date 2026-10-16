import SwiftUI

@main
struct FakeChatStoryMakerApp: App {
    @StateObject private var ads = AdsController.shared
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = ChatStore()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("chatcraft_has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("chatcraft_appearance") private var appearanceRawValue = AppAppearance.system.rawValue

    init() { AppAnalytics.shared.start() }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainAppView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environmentObject(ads)
            .environmentObject(store)
            .environmentObject(subscriptionManager)
            .overlay {
                if ads.showingAppOpen {
                    ZStack {
                        Color(uiColor: .systemBackground).ignoresSafeArea()
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble.fill").font(.largeTitle).foregroundStyle(AppColors.appTint)
                            Text("ChatCraft").font(.title.bold())
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { ads.sceneChanged($0) }
            .preferredColorScheme(AppAppearance(rawValue: appearanceRawValue)?.colorScheme)
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct MainAppView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onNavigateToProjects: {
                selectedTab = 1
            })
            .tabItem {
                Label("Stories", systemImage: "sparkles")
            }
            .tag(0)

            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(AppColors.appTint)
        .task {
            AdsController.shared.bind(to: subscriptionManager)
            AdsController.shared.startSession()
        }
    }
}
