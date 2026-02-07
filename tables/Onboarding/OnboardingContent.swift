import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
}

enum OnboardingContent {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Quick Wins & Deep Reflections",
            description: "Capture your thoughts in two ways: quick wins for brief moments of gratitude, and deep reflections for when you want to explore your feelings more fully.",
            iconName: "star.fill",
            iconColor: .yellow
        ),
        OnboardingPage(
            title: "Daily Prompts",
            description: "Get inspired with thoughtful prompts each day to help you reflect on what matters most. Answer them or skip and write freely.",
            iconName: "lightbulb.fill",
            iconColor: DesignSystem.Colors.primary
        ),
        OnboardingPage(
            title: "Your Garden",
            description: "Watch your garden grow as you reflect. Each reflection adds to your personal garden, creating a beautiful visual record of your journey.",
            iconName: "leaf.fill",
            iconColor: .green
        ),
        OnboardingPage(
            title: "Creating & Sharing Tables",
            description: "Create tables to organize reflections around themes, goals, or relationships. Invite others to join and reflect together.",
            iconName: "rectangle.split.3x3.fill",
            iconColor: DesignSystem.Colors.primary
        ),
        OnboardingPage(
            title: "Share Reflections to Tables",
            description: "Share your personal reflections to tables you're part of. Transform private thoughts into shared conversations.",
            iconName: "arrowshape.turn.up.right.fill",
            iconColor: .purple
        ),
        OnboardingPage(
            title: "Cards & Comments",
            description: "Each shared reflection becomes a card. Add comments to discuss, support, and connect with others on their reflections.",
            iconName: "bubble.left.and.bubble.right.fill",
            iconColor: .blue
        ),
        OnboardingPage(
            title: "Nudge Feature",
            description: "Gently remind table members to share their thoughts. A friendly nudge can spark meaningful conversations.",
            iconName: "bell.badge.fill",
            iconColor: .orange
        )
    ]
}
