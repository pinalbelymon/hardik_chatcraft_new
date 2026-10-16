import Foundation
import Combine
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var currentPlan: UserPlan{
        didSet {
            UserDefaults.standard.set(currentPlan.rawValue, forKey: storageKey)
        }
    }
    @Published private(set) var hasResolvedEntitlements = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var purchaseErrorMessage: String?

    private let storageKey = "chatcraft_current_plan"
    private var transactionUpdatesTask: Task<Void, Never>?

    private static let allProductIDs: [String] = [
        "com.chatcraft.lite.weekly",
        "com.chatcraft.lite.monthly",
        "com.chatcraft.lite.yearly",
        "com.chatcraft.pro.weekly",
        "com.chatcraft.pro.monthly",
        "com.chatcraft.pro.yearly"
    ]

    private static let productIDsByPlanAndCadence: [UserPlan: [String: String]] = [
        .lite: [
            "Weekly": "com.chatcraft.lite.weekly",
            "Monthly": "com.chatcraft.lite.monthly",
            "Yearly": "com.chatcraft.lite.yearly"
        ],
        .pro: [
            "Weekly": "com.chatcraft.pro.weekly",
            "Monthly": "com.chatcraft.pro.monthly",
            "Yearly": "com.chatcraft.pro.yearly"
        ]
    ]

    init() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? UserPlan.free.rawValue
        currentPlan = UserPlan(rawValue: raw) ?? .free
        transactionUpdatesTask = listenForTransactionUpdates()

        Task {
            await refreshPurchasedPlan()
            await loadProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var subscriptionOptions: [SubscriptionOption] {
        [
            SubscriptionOption(plan: .free, cadence: "Forever", price: "₹0", badge: nil),
            SubscriptionOption(plan: .lite, cadence: "Weekly", price: priceText(for: .lite, cadence: "Weekly"), badge: "Popular"),
            SubscriptionOption(plan: .lite, cadence: "Monthly", price: priceText(for: .lite, cadence: "Monthly"), badge: "Popular"),
            SubscriptionOption(plan: .lite, cadence: "Yearly", price: priceText(for: .lite, cadence: "Yearly"), badge: "Popular"),
            SubscriptionOption(plan: .pro, cadence: "Weekly", price: priceText(for: .pro, cadence: "Weekly"), badge: "Best Value"),
            SubscriptionOption(plan: .pro, cadence: "Monthly", price: priceText(for: .pro, cadence: "Monthly"), badge: "Best Value"),
            SubscriptionOption(plan: .pro, cadence: "Yearly", price: priceText(for: .pro, cadence: "Yearly"), badge: "Best Value")
        ]
    }

    func upgrade(to plan: UserPlan) {
        Task {
            _ = await purchase(plan: plan, cadence: defaultCadence(for: plan))
        }
    }

    func restorePurchases() {
        Task {
            await restorePurchasesFromStore()
        }
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loadedProducts = try await Product.products(for: Self.allProductIDs)
            products = loadedProducts.sorted { Self.sortRank(for: $0.id) < Self.sortRank(for: $1.id) }
            purchaseErrorMessage = nil
        } catch {
            purchaseErrorMessage = "Unable to load subscriptions. Please try again."
        }
    }

    @discardableResult
    func purchase(plan: UserPlan, cadence: String) async -> Bool {
        purchaseErrorMessage = nil

        guard plan != .free else {
            await refreshPurchasedPlan()
            return currentPlan == .free
        }

        AppAnalytics.shared.track(.purchaseStart, ["plan": plan.rawValue, "cadence": cadence])
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = product(for: plan, cadence: cadence) else {
            AppAnalytics.shared.track(.purchaseFailed, ["plan": plan.rawValue, "reason": "product_unavailable"])
            purchaseErrorMessage = "Subscription is not available yet. Please check App Store Connect setup."
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try Self.checkVerified(verificationResult)
                AppAnalytics.shared.verifiedPurchase(transaction, plan: plan)
                await transaction.finish()
                await refreshPurchasedPlan()
                purchaseErrorMessage = nil
                return currentPlan >= plan
            case .userCancelled:
                AppAnalytics.shared.track(.purchaseCancelled, ["plan": plan.rawValue])
                return false
            case .pending:
                AppAnalytics.shared.track(.purchasePending, ["plan": plan.rawValue])
                purchaseErrorMessage = "Purchase is pending approval."
                return false
            @unknown default:
                AppAnalytics.shared.track(.purchaseFailed, ["plan": plan.rawValue, "reason": "unknown_result"])
                purchaseErrorMessage = "Purchase could not be completed."
                return false
            }
        } catch {
            AppAnalytics.shared.track(.purchaseFailed, ["plan": plan.rawValue, "reason": "storekit_error"])
            purchaseErrorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchasesFromStore() async {
        AppAnalytics.shared.track(.restoreStart)
        purchaseErrorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedPlan()
            AppAnalytics.shared.track(.restoreComplete, ["plan": currentPlan.rawValue])
        } catch {
            AppAnalytics.shared.track(.restoreFailed, ["reason": "storekit_error"])
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func refreshPurchasedPlan() async {
        defer { hasResolvedEntitlements = true }
        var bestPlan = UserPlan.free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result),
                  transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > Date() }) ?? true,
                  let plan = Self.plan(for: transaction.productID) else {
                continue
            }
            bestPlan = max(bestPlan, plan)
        }

        currentPlan = bestPlan
    }

    func product(for plan: UserPlan, cadence: String) -> Product? {
        guard let productID = productID(for: plan, cadence: cadence) else { return nil }
        return products.first { $0.id == productID }
    }

    func productID(for plan: UserPlan, cadence: String) -> String? {
        Self.productIDsByPlanAndCadence[plan]?[cadence]
    }

    func priceText(for plan: UserPlan, cadence: String) -> String {
        guard plan != .free else { return "₹0" }
        // A free-plan cadence (Forever) is never a valid paid product lookup.
        let cadence = ["Weekly", "Monthly", "Yearly"].contains(cadence) ? cadence : "Yearly"
        if let product = product(for: plan, cadence: cadence) {
            return "\(product.displayPrice)/\(cadence.lowercasedSingular)"
        }

        switch (plan, cadence) {
        case (.lite, "Weekly"): return "₹199/week"
        case (.lite, "Monthly"): return "₹499/month"
        case (.lite, "Yearly"): return "₹1,999/year"
        case (.pro, "Weekly"): return "₹399/week"
        case (.pro, "Monthly"): return "₹999/month"
        case (.pro, "Yearly"): return "₹3,999/year"
        default: return "Price unavailable"
        }
    }

    func isFeatureUnlocked(feature: FeatureAccess) -> Bool {
        switch currentPlan {
        case .free:
            return [.textMessages, .screenshotExport].contains(feature)
        case .lite:
            return [
                .textMessages,
                .imageMessages,
                .typingIndicators,
                .dateSeparators,
                .messageReactions,
                .autoplay,
                .screenshotExport
            ].contains(feature)
        case .pro:
            return true
        }
    }

    func canUse(feature: FeatureAccess) -> Bool {
        isFeatureUnlocked(feature: feature)
    }

    func canCreateStory(currentStoryCount: Int) -> Bool {
        switch currentPlan {
        case .free: return currentStoryCount < 3
        case .lite: return currentStoryCount < 25
        case .pro: return true
        }
    }

    func canAddCharacter(currentCharacterCount: Int) -> Bool {
        switch currentPlan {
        case .free: return currentCharacterCount < 2
        case .lite: return currentCharacterCount < 5
        case .pro: return true
        }
    }

    func canUseTheme(_ theme: ChatTheme) -> Bool {
        currentPlan >= theme.requiredPlan
    }

    func canExportWithoutWatermark() -> Bool {
        currentPlan == .pro
    }

    func canUseMessageType(_ type: MessageType) -> Bool {
       isFeatureUnlocked(feature: type.feature)
    }

    func watermarkLabel() -> String? {
        switch currentPlan {
        case .free:
            return "Made with ChatCraft"
        case .lite:
            return "ChatCraft"
        case .pro:
            return nil
        }
    }

    func planLimitDescription() -> String {
        switch currentPlan {
        case .free:
            return "3 stories, 2 characters, text only"
        case .lite:
            return "Ad-free · 25 stories, 5 characters, images and basic playback"
        case .pro:
            return "Ad-free · Unlimited stories, all media, exports, and themes"
        }
    }

    private func defaultCadence(for plan: UserPlan) -> String {
        switch plan {
        case .free: return "Forever"
        case .lite, .pro: return "Monthly"
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? Self.checkVerified(result) else { return }
        if let plan = Self.plan(for: transaction.productID), transaction.revocationDate == nil,
           transaction.expirationDate.map({ $0 > Date() }) ?? true {
            AppAnalytics.shared.verifiedPurchase(transaction, plan: plan)
        }
        await transaction.finish()
        await refreshPurchasedPlan()
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseVerificationError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private static func plan(for productID: String) -> UserPlan? {
        if productID.hasPrefix("com.chatcraft.pro.") { return .pro }
        if productID.hasPrefix("com.chatcraft.lite.") { return .lite }
        return nil
    }

    private static func sortRank(for productID: String) -> Int {
        switch productID {
        case "com.chatcraft.lite.weekly": return 0
        case "com.chatcraft.lite.monthly": return 1
        case "com.chatcraft.lite.yearly": return 2
        case "com.chatcraft.pro.weekly": return 3
        case "com.chatcraft.pro.monthly": return 4
        case "com.chatcraft.pro.yearly": return 5
        default: return 99
        }
    }
}

private enum PurchaseVerificationError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "The App Store could not verify this transaction."
    }
}

private extension String {
    var lowercasedSingular: String {
        switch self {
        case "Weekly": return "week"
        case "Monthly": return "month"
        case "Yearly": return "year"
        default: return lowercased()
        }
    }
}
