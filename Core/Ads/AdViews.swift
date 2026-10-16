import SwiftUI
import Combine
import GoogleMobileAds

private enum AdLoadState { case idle, loading, loaded, failed }

/// Shimmer exists only during a bounded network request; no perpetual animation when offscreen.
private struct AdShimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.10))
            .overlay {
                if !reduceMotion {
                    GeometryReader { geometry in
                        LinearGradient(colors: [.clear, .white.opacity(0.30), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geometry.size.width * 0.5)
                            .offset(x: phase ? geometry.size.width : -geometry.size.width * 0.5)
                    }.clipped()
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = true }
            }
            .accessibilityLabel("Loading advertisement")
    }
}

@MainActor
private final class BannerModel: NSObject, ObservableObject, BannerViewDelegate {
    @Published var state: AdLoadState = .idle
    private(set) var view: BannerView?
    private var timeout: Task<Void, Never>?
    private var attempted = false

    func load() {
        guard !attempted, AdsController.shared.canRequestAds else { return }
        attempted = true
        state = .loading
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdUnits.banner
        banner.rootViewController = AdsController.presenter
        banner.delegate = self
        view = banner
        banner.load(Request())
        timeout = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled, let self, self.state == .loading else { return }
            self.fail()
        }
    }
    func clear() {
        timeout?.cancel()
        view?.delegate = nil
        view = nil
        state = .idle
        attempted = false
    }
    private func fail() {
        timeout?.cancel()
        view?.delegate = nil
        view = nil
        state = .failed
    }
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        guard AdsController.shared.canRequestAds, bannerView === view else { clear(); return }
        timeout?.cancel()
        state = .loaded
        AppAnalytics.shared.track(.adLoadResult, ["format": "banner", "result": "loaded"])
    }
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        #if DEBUG
        print("[Ads] Banner unavailable: \(error.localizedDescription)")
        #endif
        fail()
    }
}

private struct BannerContent: UIViewRepresentable {
    let banner: BannerView
    func makeUIView(context: Context) -> BannerView { banner }
    func updateUIView(_ uiView: BannerView, context: Context) {}
    // BannerModel owns the delegate across navigation/keyboard visibility changes.
}

struct BannerAdSlot: View {
    @EnvironmentObject private var ads: AdsController
    @StateObject private var model = BannerModel()
    var body: some View {
        VStack(spacing: 0) {
            if ads.canRequestAds {
                if (model.state == .loading || model.state == .loaded), let banner = model.view {
                    ZStack {
                        // Keep the SDK view attached while loading so visibility/refresh work correctly.
                        BannerContent(banner: banner).frame(width: 320, height: 50)
                            .opacity(model.state == .loaded ? 1 : 0)
                            .allowsHitTesting(model.state == .loaded)
                        if model.state == .loading { AdShimmer().frame(width: 320, height: 50) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(Color(uiColor: .systemBackground))
                }
            }
        }
        .task(id: ads.canRequestAds) {
            if ads.canRequestAds { model.load() } else { model.clear() }
        }
    }
}

@MainActor
private final class NativeModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var state: AdLoadState = .idle
    private(set) var ad: NativeAd?
    private var loader: AdLoader?
    private var timeout: Task<Void, Never>?
    private var attempted = false

    func load() {
        guard !attempted, AdsController.shared.canRequestAds else { return }
        attempted = true
        state = .loading
        let options = NativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .landscape
        let loader = AdLoader(adUnitID: AdUnits.native, rootViewController: AdsController.presenter, adTypes: [.native], options: [options])
        self.loader = loader
        loader.delegate = self
        loader.load(Request())
        timeout = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled, let self, self.state == .loading else { return }
            self.fail()
        }
    }
    func clear() {
        timeout?.cancel()
        loader?.delegate = nil
        loader = nil
        ad = nil
        state = .idle
        attempted = false
    }
    private func fail() {
        timeout?.cancel()
        loader?.delegate = nil
        loader = nil
        ad = nil
        state = .failed
    }
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard AdsController.shared.canRequestAds, adLoader === loader else { clear(); return }
        timeout?.cancel()
        ad = nativeAd
        state = .loaded
        AppAnalytics.shared.track(.adLoadResult, ["format": "native", "result": "loaded"])
    }
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) { fail() }
}

/// SDK owns click tracking and AdChoices. No custom gestures or overlays cover the ad assets.
private struct NativeContent: UIViewRepresentable {
    let ad: NativeAd
    func makeUIView(context: Context) -> NativeAdView {
        let view = NativeAdView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 14
        let attribution = UILabel()
        attribution.text = "Ad"
        attribution.font = .systemFont(ofSize: 11, weight: .bold)
        attribution.textColor = .secondaryLabel
        let media = MediaView()
        media.contentMode = .scaleAspectFit
        let headline = UILabel()
        headline.font = .systemFont(ofSize: 15, weight: .semibold)
        headline.numberOfLines = 2
        let body = UILabel()
        body.font = .systemFont(ofSize: 12)
        body.textColor = .secondaryLabel
        body.numberOfLines = 2
        let advertiser = UILabel()
        advertiser.font = .systemFont(ofSize: 11)
        advertiser.textColor = .secondaryLabel
        let cta = UIButton(type: .system)
        cta.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        cta.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
        cta.layer.cornerRadius = 8
        cta.isUserInteractionEnabled = false
        cta.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let text = UIStackView(arrangedSubviews: [headline, body, advertiser, cta])
        text.axis = .vertical
        text.spacing = 5
        let row = UIStackView(arrangedSubviews: [media, text])
        row.spacing = 12
        row.alignment = .center
        let stack = UIStackView(arrangedSubviews: [attribution, row])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
            media.widthAnchor.constraint(equalToConstant: 120),
            media.heightAnchor.constraint(equalToConstant: 120)
        ])
        // Leave the SDK's top-right AdChoices overlay unobstructed by text.
        attribution.heightAnchor.constraint(equalToConstant: 16).isActive = true
        view.mediaView = media
        view.headlineView = headline
        view.bodyView = body
        view.advertiserView = advertiser
        view.callToActionView = cta
        headline.text = ad.headline
        body.text = ad.body
        body.isHidden = ad.body == nil
        advertiser.text = ad.advertiser
        advertiser.isHidden = ad.advertiser == nil
        cta.setTitle(ad.callToAction, for: .normal)
        cta.isHidden = ad.callToAction == nil
        media.mediaContent = ad.mediaContent
        view.nativeAd = ad
        return view
    }
    func updateUIView(_ uiView: NativeAdView, context: Context) {}
    static func dismantleUIView(_ uiView: NativeAdView, coordinator: ()) {
        uiView.mediaView?.mediaContent?.videoController.pause()
        uiView.nativeAd = nil
    }
}

struct NativeAdSlot: View {
    @EnvironmentObject private var ads: AdsController
    @StateObject private var model = NativeModel()
    var topSpacing: CGFloat = 12
    var body: some View {
        VStack(spacing: 0) {
            if ads.canRequestAds {
                if model.state == .loading {
                    AdShimmer().frame(height: 180).padding(.top, topSpacing)
                } else if model.state == .loaded, let ad = model.ad {
                    NativeContent(ad: ad).frame(height: 180).padding(.top, topSpacing)
                }
            }
        }
        .task(id: ads.canRequestAds) {
            if ads.canRequestAds { model.load() } else { model.clear() }
        }
    }
}

/// Rows rather than individual cells determine cadence, including on iPad.
/// Native slots own their margins so an empty/no-fill ad takes exactly zero space.
struct AdSupportedGrid<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    let columns: Int
    var spacing: CGFloat = 12
    @ViewBuilder var cell: (Item) -> Cell

    private var rows: [[Item]] {
        let count = max(columns, 1)
        return stride(from: 0, to: items.count, by: count).map { Array(items[$0..<min($0 + count, items.count)]) }
    }
    var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(row) { item in cell(item).frame(maxWidth: .infinity) }
                        ForEach(0..<max(0, columns - row.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) }
                    }
                    if AdPolicy.insertsNative(afterRow: index + 1) {
                        NativeAdSlot(topSpacing: spacing)
                    }
                }
            }
        }
    }
}

private struct DetailAdsModifier: ViewModifier {
    var bannerEnabled = true
    @State private var token = UUID()
    @State private var keyboardVisible = false
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            if bannerEnabled && !keyboardVisible { BannerAdSlot() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
        .onAppear { AdsController.shared.setAppOpenBlocked(true, id: token) }
        .onDisappear { AdsController.shared.setAppOpenBlocked(false, id: token) }
    }
}

private struct SuppressAppOpenModifier: ViewModifier {
    @State private var token = UUID()
    func body(content: Content) -> some View {
        content.onAppear { AdsController.shared.setAppOpenBlocked(true, id: token) }
            .onDisappear { AdsController.shared.setAppOpenBlocked(false, id: token) }
    }
}

extension View {
    func detailAds(bannerEnabled: Bool = true) -> some View {
        modifier(DetailAdsModifier(bannerEnabled: bannerEnabled))
    }
    func suppressAppOpenAds() -> some View { modifier(SuppressAppOpenModifier()) }
}

struct AdExportShareSheet: UIViewControllerRepresentable {
    let url: URL
    var completed: (Bool) -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, success, _, _ in
            #if DEBUG
            NSLog("[Ads] System share finished; completed=%d", success)
            #endif
            completed(success)
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
