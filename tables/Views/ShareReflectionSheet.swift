import SwiftUI

struct ShareReflectionSheet: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let reflection: SupabaseReflection

    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var activeTables: [SupabaseTable] {
        supabaseManager.tables.filter { $0.status == "active" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if activeTables.isEmpty {
                    emptyState
                } else {
                    tablesList
                }
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Share to Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Spacer()

            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.mutedText)

            Text("No Tables Available")
                .font(.headline)

            Text("Create a Table first to share your reflections with friends.")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Padding.screen)

            Spacer()
        }
    }

    private var tablesList: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Choose a Table to share your reflection")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.medium)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, DesignSystem.Padding.screen)
            }

            if let successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(successMessage)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
            }

            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(activeTables) { table in
                        Button {
                            Task {
                                await shareToTable(table)
                            }
                        } label: {
                            TableRowForSharing(table: table, isSharing: isSharing)
                        }
                        .disabled(isSharing)
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
    }

    private func shareToTable(_ table: SupabaseTable) async {
        isSharing = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await supabaseManager.shareReflectionToTable(
                reflection: reflection,
                tableId: table.id
            )
            successMessage = "Shared to \(table.title)"

            // Dismiss after a short delay to show success
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        } catch {
            errorMessage = "Failed to share: \(error.localizedDescription)"
            isSharing = false
        }
    }
}

struct TableRowForSharing: View {
    let table: SupabaseTable
    let isSharing: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(table.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(table.members.count) members")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Spacer()

            if isSharing {
                ProgressView()
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

#Preview {
    ShareReflectionSheet(
        reflection: SupabaseReflection(
            id: UUID(),
            userId: UUID(),
            body: "This is a sample reflection that I wrote about my day.",
            prompt: "What made you smile today?",
            reflectionType: "deep_reflection",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .environmentObject(SupabaseManager())
}
