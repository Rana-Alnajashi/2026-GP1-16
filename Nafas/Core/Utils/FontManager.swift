import SwiftUI

extension View {
    func appFont(size: CGFloat) -> some View {
        self.modifier(SmartFontModifier(size: size))
    }
}

struct SmartFontModifier: ViewModifier {
    var size: CGFloat
    
    func body(content: Content) -> some View {
        content.font(.custom("IBMPlexSansArabic-Regular", size: size))
            
    }
}
