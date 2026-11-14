import SwiftUI
import HushbalmDesignSystem

struct MainTabView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Tonight", systemImage: HBIcon.tonight.rawValue) }
            LibraryView()
                .tabItem { Label("Library", systemImage: HBIcon.library.rawValue) }
            ReportView()
                .tabItem { Label("Report", systemImage: HBIcon.report.rawValue) }
        }
        .tint(HBColor.accentWarm)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(HBColor.background)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
