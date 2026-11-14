import SwiftUI
import StoreKit
import HushbalmDesignSystem

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @State private var showManage = false
    @State private var showUpgrade = false
    @State private var reminderTime = Date.now

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HBSpacing.lg) {
                    HStack {
                        HBScreenHeader(title: "Settings")
                        HBIconButton(.close, accessibilityLabel: "Close") { dismiss() }
                    }

                    HBCard {
                        HBSectionHeader("Family")
                        field("Your name", text: $state.answers.parentName)
                        field("Child's name", text: $state.answers.childName)
                    }

                    HBCard {
                        HBSectionHeader("Bedtime reminder")
                        Toggle(isOn: $state.answers.wantsReminder) {
                            Text("Remind me each night").hbText(.callout)
                        }
                        .tint(HBColor.accentCalm)
                        if appState.answers.wantsReminder {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .hbText(.callout)
                        }
                    }

                    HBCard {
                        HBSectionHeader("Subscription")
                        if store.isSubscribed {
                            if let end = store.trialEndDate {
                                Text("Free trial until \(end.formatted(date: .abbreviated, time: .omitted)).")
                                    .hbText(.body)
                            } else {
                                Text("Premium is active.").hbText(.body)
                            }
                            Button("Manage or cancel subscription") { showManage = true }.buttonStyle(.hbSecondary)
                        } else {
                            Text("You're on the free version.").hbText(.body)
                            Button("See Premium plans") { showUpgrade = true }.buttonStyle(.hbPrimary)
                        }
                        Button("Restore purchases") { Task { await store.restore() } }.buttonStyle(.hbGhost)
                    }

                    HBCard {
                        HBSectionHeader("About")
                        Link("Terms of Use", destination: AppConfig.termsURL).hbText(.callout, color: HBColor.accentCalm)
                        Link("Privacy Policy", destination: AppConfig.privacyURL).hbText(.callout, color: HBColor.accentCalm)
                        if let mail = URL(string: "mailto:\(AppConfig.supportEmail)") {
                            Link("Contact support", destination: mail).hbText(.callout, color: HBColor.accentCalm)
                        }
                        Text(AppConfig.medicalDisclaimer).hbText(.footnote, color: HBColor.textSecondary)
                    }
                }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.vertical, HBSpacing.lg)
            }
            .background(HBColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .manageSubscriptionsSheet(isPresented: $showManage)
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
            .onAppear {
                reminderTime = Calendar.current.date(bySettingHour: appState.answers.reminderHour,
                                                     minute: appState.answers.reminderMinute, second: 0, of: .now) ?? .now
            }
            .onChange(of: reminderTime) { _, time in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                appState.answers.reminderHour = parts.hour ?? 19
                appState.answers.reminderMinute = parts.minute ?? 30
                updateReminder()
            }
            .onChange(of: appState.answers.wantsReminder) { _, _ in updateReminder() }
        }
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).hbText(.footnote, color: HBColor.textSecondary)
            TextField(label, text: text).hbText(.callout).textInputAutocapitalization(.words)
        }
    }

    private func updateReminder() {
        let a = appState.answers
        if a.wantsReminder {
            Task { await ReminderScheduler.enable(hour: a.reminderHour, minute: a.reminderMinute, childName: a.displayChild) }
        } else {
            ReminderScheduler.disable()
        }
    }
}
