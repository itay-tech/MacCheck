import SwiftUI

struct ProBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: MacCheckTheme.Spacing.xs) {
            Image(systemName: "crown.fill")
                .font(compact ? .caption2 : .caption)
            if !compact {
                Text("PRO")
                    .font(.caption.weight(.bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(MacCheckTheme.proGradient)
        .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        ProBadge()
        ProBadge(compact: true)
    }
    .padding()
}
