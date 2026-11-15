import SwiftUI
import AljiDesignSystem

struct MainTabView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Tonight", systemImage: AJIcon.tonight.rawValue) }
            LibraryView()
                .tabItem { Label("Library", systemImage: AJIcon.library.rawValue) }
            ReportView()
                .tabItem { Label("Report", systemImage: AJIcon.report.rawValue) }
        }
        .tint(AJColor.accentWarm)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AJColor.background)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
