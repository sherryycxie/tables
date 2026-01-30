import SwiftUI

enum DesignSystem {
    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Padding {
        static let screen: CGFloat = 20
        static let card: CGFloat = 16
    }

    enum Colors {
        static let primary = Color(red: 0.07, green: 0.74, blue: 0.9)
        static let mutedText = Color.secondary
        static let cardBackground = Color.white
        static let screenBackground = Color(uiColor: .systemGroupedBackground)
        static let border = Color(uiColor: .systemGray5)
    }

    enum CardDimensions {
        static let carouselCardWidth: CGFloat = 340
        static let carouselCardHeight: CGFloat = 220
        static let carouselSpacing: CGFloat = 20
    }

    enum Effects3D {
        static let rotationAngle: Double = 15.0
        static let sideCardScale: CGFloat = 0.85
        static let sideCardOpacity: Double = 0.7
        static let perspective: CGFloat = 0.5
    }

    enum Shadows {
        static let cardElevated = [
            (color: Color.black.opacity(0.1), radius: CGFloat(8), y: CGFloat(4)),
            (color: Color.black.opacity(0.05), radius: CGFloat(20), y: CGFloat(10))
        ]
    }
}
