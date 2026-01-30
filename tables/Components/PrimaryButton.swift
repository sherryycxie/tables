import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(DesignSystem.Colors.primary)
            .clipShape(Capsule())
            .shadow(color: DesignSystem.Colors.primary.opacity(0.25), radius: 10, y: 6)
        }
    }
}

#Preview {
    PrimaryButton(title: "New Table", systemImage: "plus") {}
}
