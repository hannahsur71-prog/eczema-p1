import SwiftUI
import SwiftData
import AljiDesignSystem

@main
struct AljiApp: App {
    @State private var appState = AppState()
    @State private var store = StoreManager()

    init() { AJFonts.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(AJColor.accentCalm)
        }
        .modelContainer(for: NightLog.self)
    }
}

/// Onboarding → paywall → (yes: welcome → app) or (no: second offer → free version).
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingFlow()
            } else if !store.hasLoaded {
                LaunchView()
            } else if store.isSubscribed && appState.showWelcomeAfterPurchase {
                WelcomeAfterPurchaseView()
            } else if store.isSubscribed || appState.paywallDismissed {
                MainTabView()
            } else {
                PaywallView(context: .onboarding)
            }
        }
        .animation(.easeInOut, value: appState.paywallDismissed)
        .animation(.easeInOut, value: appState.showWelcomeAfterPurchase)
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
        .animation(.easeInOut, value: store.isSubscribed)
        .task { await store.load() }
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            StarryBackground()
            AJStar(size: 56)
        }
    }
}
