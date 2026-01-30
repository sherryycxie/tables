import SwiftUI

struct FriendAvatarView: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Avatar circle
                Text(initials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(avatarColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 3)
                    )

                // Blue dot indicator when selected
                if isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }

            // Name label
            Text(name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : DesignSystem.Colors.mutedText)
                .lineLimit(1)
                .frame(width: 64)
        }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        let letters = components.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }

    private var avatarColor: Color {
        // Generate consistent color from name hash
        let colors: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.3),  // Red
            Color(red: 0.3, green: 0.6, blue: 0.9),  // Blue
            Color(red: 0.3, green: 0.8, blue: 0.5),  // Green
            Color(red: 0.9, green: 0.6, blue: 0.2),  // Orange
            Color(red: 0.7, green: 0.4, blue: 0.9),  // Purple
            Color(red: 0.9, green: 0.7, blue: 0.2),  // Yellow
        ]

        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

#Preview {
    HStack(spacing: 16) {
        FriendAvatarView(name: "John Doe", isSelected: false)
        FriendAvatarView(name: "Jane Smith", isSelected: true)
        FriendAvatarView(name: "Bob", isSelected: false)
    }
    .padding()
}
