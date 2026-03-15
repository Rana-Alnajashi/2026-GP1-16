//
//  FontManager.swift
//  Nafas
//
//  Created by Rana Alngashy on 15/03/2026.
//
import SwiftUI

extension View {
    func appFont(size: CGFloat) -> some View {
        self.modifier(SmartFontModifier(size: size))
    }
}

struct SmartFontModifier: ViewModifier {
    var size: CGFloat
    
    func body(content: Content) -> some View {
        // This will allow us to pass the text style down
        content.font(.custom("IBMPlexSansArabic-Regular", size: size))
            // This ensures that if the text is English, it falls back to Inter
            // Note: You can also explicitly check the string, but
            // IBM Plex Sans Arabic actually supports English characters too!
    }
}
