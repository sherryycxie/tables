import SwiftUI

struct ReminderChipView: View {
    let date: Date

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 12, weight: .semibold))
            Text("Remind: \(formattedDate)")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(DesignSystem.Colors.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.primary.opacity(0.12))
        .clipShape(Capsule())
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

#Preview {
    ReminderChipView(date: Date())
}
