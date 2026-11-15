import SwiftUI
import StoreKit
import AljiDesignSystem

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
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    HStack {
                        AJScreenHeader(title: "Settings")
                        AJIconButton(.close, accessibilityLabel: "Close") { dismiss() }
                    }

                    AJCard {
                        AJSectionHeader("Family")
                        field("Your name", text: $state.answers.parentName)
                        field("Child's name", text: $state.answers.childName)
                    }

                    AJCard {
                        AJSectionHeader("Bedtime reminder")
                        Toggle(isOn: $state.answers.wantsReminder) {
                            Text("Remind me each night").ajText(.callout)
                        }
                        .tint(AJColor.accentCalm)
                        if appState.answers.wantsReminder {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .ajText(.callout)
                        }
                    }

                    AJCard {
                        AJSectionHeader("Subscription")
                        if store.isSubscribed {
                            if let end = store.trialEndDate {
                                Text("Free trial until \(end.formatted(date: .abbreviated, time: .omitted)).")
                                    .ajText(.body)
                            } else {
                                Text("Premium is active.").ajText(.body)
                            }
                            Button("Manage or cancel subscription") { showManage = true }.buttonStyle(.ajSecondary)
                        } else {
                            Text("You're on the free version.").ajText(.body)
                            Button("See Premium plans") { showUpgrade = true }.buttonStyle(.ajPrimary)
                        }
                        Button("Restore purchases") { Task { await store.restore() } }.buttonStyle(.ajGhost)
                    }

                    AJCard {
                        AJSectionHeader("About")
                        Link("Terms of Use", destination: AppConfig.termsURL).ajText(.callout, color: AJColor.accentCalm)
                        Link("Privacy Policy", destination: AppConfig.privacyURL).ajText(.callout, color: AJColor.accentCalm)
                        if let mail = URL(string: "mailto:\(AppConfig.supportEmail)") {
                            Link("Contact support", destination: mail).ajText(.callout, color: AJColor.accentCalm)
                        }
                        Text(AppConfig.medicalDisclaimer).ajText(.footnote, color: AJColor.textSecondary)
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.lg)
            }
            .background(AJColor.background.ignoresSafeArea())
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
            Text(label).ajText(.footnote, color: AJColor.textSecondary)
            TextField(label, text: text).ajText(.callout).textInputAutocapitalization(.words)
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
