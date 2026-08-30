import SwiftUI

/// Floty's window surface: blurred backdrop, colour tint, rounded corners.
///
/// One implementation for both windows. It used to be written out twice - once
/// in the scratchpad panel, once in the clipboard picker - which is exactly how
/// two windows of the same app drift apart.
///
/// The tint covers fully and the slider takes the whole surface back. Laying the
/// tint over the blur with the slider's opacity would let the material's grey
/// through and wash the colour out, worst of all at the translucent end.
struct PanelBackground: ViewModifier {
    let tint: PanelTint
    let opacity: Double
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            // Fill the window even when the content is shorter - otherwise an
            // empty list would leave the surface see-through below it.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    VisualEffectBackground()
                    tint.base
                }
                .opacity(opacity)
                .ignoresSafeArea()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .preferredColorScheme(.dark)
    }
}

extension View {
    func flotyBackground(tint: PanelTint, opacity: Double, cornerRadius: CGFloat = 12) -> some View {
        modifier(PanelBackground(tint: tint, opacity: opacity, cornerRadius: cornerRadius))
    }
}
