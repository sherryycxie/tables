import SwiftUI

struct SupabaseNudgeReminderView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let table: SupabaseTable
    var onReminderSet: ((Date) -> Void)?

    @State private var selectedPreset: ReminderPreset? = .tonight
    @State private var selectedDate: Date = Date()
    @State private var reminderMode: ReminderMode = .nudgeEveryone
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                        Text("Set a Reminder")
                            .font(.system(size: 22, weight: .bold))

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            Text("When should we talk?")
                                .font(.headline)

                            presetGrid
                        }

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            Text("Or pick a specific time")
                                .font(.headline)

                            dateTimePicker
                        }

                        modePicker

                        Text("Selecting \"Nudge everyone\" will notify all participants in this Table.")
                            .font(.footnote)
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }
                    .padding(.horizontal, DesignSystem.Padding.screen)
                    .padding(.top, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.large)
                }

                PrimaryButton(title: isSaving ? "Saving..." : "Confirm Reminder") {
                    Task {
                        await confirmReminder()
                    }
                }
                .disabled(isSaving)
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.vertical, DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.screenBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let existing = table.nextReminderDate {
                    selectedDate = existing
                } else {
                    applyPreset(.tonight)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var presetGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.medium) {
            ForEach(ReminderPreset.allCases) { preset in
                Button {
                    selectedPreset = preset
                    applyPreset(preset)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(presetBackground(for: preset))
                            .frame(height: 120)
                            .overlay(
                                Text(preset.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(),
                                alignment: .bottomLeading
                            )

                        if selectedPreset == preset {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                    }
                }
            }
        }
    }

    private var dateTimePicker: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "calendar")
                    .foregroundStyle(DesignSystem.Colors.primary)
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "clock")
                    .foregroundStyle(DesignSystem.Colors.primary)
                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, 12)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Picker("Mode", selection: $reminderMode) {
                ForEach(ReminderMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func applyPreset(_ preset: ReminderPreset) {
        selectedDate = preset.date(from: Date())
    }

    private func presetBackground(for preset: ReminderPreset) -> LinearGradient {
        switch preset {
        case .tonight:
            return LinearGradient(colors: [Color.black.opacity(0.7), DesignSystem.Colors.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tomorrow:
            return LinearGradient(colors: [Color.black.opacity(0.6), Color.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .thisWeekend:
            return LinearGradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .nextWeek:
            return LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func confirmReminder() async {
        isSaving = true

        do {
            // Update table with reminder date
            var updatedTable = table
            updatedTable.nextReminderDate = selectedDate
            try await supabaseManager.updateTable(updatedTable)

            // Create nudge if nudging everyone
            if reminderMode == .nudgeEveryone {
                _ = try await supabaseManager.createNudge(
                    tableId: table.id,
                    message: "Nudge: revisit \(table.title)"
                )
            }

            // Schedule local notification
            let notificationMessage = reminderMode == .nudgeEveryone
                ? "Time to check in with your collaborators!"
                : "You set a reminder to revisit this table."

            try await NotificationManager.shared.scheduleTableReminder(
                tableId: table.id,
                tableTitle: table.title,
                message: notificationMessage,
                date: selectedDate
            )

            // Notify parent view of the new reminder date
            onReminderSet?(selectedDate)
            dismiss()
        } catch {
            // Handle error
            print("❌ Failed to set reminder: \(error.localizedDescription)")
        }

        isSaving = false
    }
}

private enum ReminderMode: String, CaseIterable, Identifiable {
    case nudgeEveryone
    case remindMeOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nudgeEveryone:
            return "Nudge everyone"
        case .remindMeOnly:
            return "Remind me only"
        }
    }
}

private enum ReminderPreset: String, CaseIterable, Identifiable {
    case tonight
    case tomorrow
    case thisWeekend
    case nextWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tonight:
            return "Tonight"
        case .tomorrow:
            return "Tomorrow"
        case .thisWeekend:
            return "This weekend"
        case .nextWeek:
            return "Next week"
        }
    }

    func date(from base: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .tonight:
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: base) ?? base
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: base) ?? base
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        case .thisWeekend:
            let weekday = calendar.component(.weekday, from: base)
            let daysUntilSaturday = (7 - weekday + 7) % 7
            let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday, to: base) ?? base
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: saturday) ?? saturday
        case .nextWeek:
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: base) ?? base
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextWeek) ?? nextWeek
        }
    }
}

#Preview {
    SupabaseNudgeReminderView(
        table: SupabaseTable(
            id: UUID(),
            title: "Career crossroads",
            context: nil,
            status: "active",
            createdAt: Date(),
            updatedAt: Date(),
            members: ["Sarah", "Marcus"],
            nextReminderDate: nil,
            ownerId: UUID()
        )
    )
    .environmentObject(SupabaseManager())
}
