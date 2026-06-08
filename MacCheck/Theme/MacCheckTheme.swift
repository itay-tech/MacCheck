import SwiftUI

enum MacCheckTheme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    enum KPI {
        static let height: CGFloat = 272
    }

    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let secondaryBackground = Color(nsColor: .windowBackgroundColor)
    static let tertiaryFill = Color.primary.opacity(0.05)
    static let heroTint = Color.accentColor.opacity(0.08)
    static let cardShadow = Color.black.opacity(0.06)
    static let proGradient = LinearGradient(
        colors: [Color(red: 0.45, green: 0.35, blue: 1.0), Color(red: 0.25, green: 0.55, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = MacCheckTheme.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

struct HeroCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(MacCheckTheme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
                    .fill(MacCheckTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
                            .fill(MacCheckTheme.heroTint)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.xl, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 14, x: 0, y: 6)
    }
}

struct PanelCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(MacCheckTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MacCheckTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MacCheckTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: MacCheckTheme.cardShadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func macCheckCard(padding: CGFloat = MacCheckTheme.Spacing.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func macCheckHeroCard() -> some View {
        modifier(HeroCardStyle())
    }

    func macCheckPanel() -> some View {
        modifier(PanelCardStyle())
    }
}
