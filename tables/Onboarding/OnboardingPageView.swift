import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()

            // Icon with circular background
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 180, height: 180)

                Image(systemName: page.iconName)
                    .font(.system(size: 72))
                    .foregroundStyle(page.iconColor)
            }

            Spacer()
                .frame(height: DesignSystem.Spacing.medium)

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Padding.screen)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Padding.screen)
    }
}

#Preview {
    OnboardingPageView(page: OnboardingContent.pages[0])
}
