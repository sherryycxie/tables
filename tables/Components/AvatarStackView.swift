import SwiftUI

struct AvatarStackView: View {
    let members: [String]
    let maxVisible: Int

    init(members: [String], maxVisible: Int = 3) {
        self.members = members
        self.maxVisible = maxVisible
    }

    var body: some View {
        HStack(spacing: -8) {
            ForEach(visibleMembers.indices, id: \.self) { index in
                let name = visibleMembers[index]
                AvatarCircle(initials: initials(for: name))
            }

            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 28, height: 28)
                    .background(DesignSystem.Colors.border)
                    .clipShape(Circle())
            }
        }
    }

    private var visibleMembers: [String] {
        Array(members.prefix(maxVisible))
    }

    private var overflowCount: Int {
        max(0, members.count - maxVisible)
    }

    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        let letters = components.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }
}

private struct AvatarCircle: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)
            .background(Color(uiColor: .systemGray5))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
}

#Preview {
    AvatarStackView(members: ["Sarah", "Marcus", "James", "Anna"])
}
