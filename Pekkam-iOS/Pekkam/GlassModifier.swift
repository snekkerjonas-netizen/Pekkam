import SwiftUI

struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect()
                .cornerRadius(12)
        } else {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
}

extension View {
    func glassPanel() -> some View {
        modifier(GlassPanel())
    }
}
