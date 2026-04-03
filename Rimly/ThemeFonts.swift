//
//  ThemeFonts.swift
//  Breath
//
//  Created by AFP PAR 58 on 21/03/26.
//


import SwiftUI

struct ThemeFonts {
    // Display & Headline (Manrope) - Extreme kerning for editorial feel
    static var displayLarge: Font {
        .custom("Manrope-ExtraBold", size: 50)
    }
    
    static var headlineSmall: Font {
        .custom("Manrope-Bold", size: 24)
    }
    
    static var bodyLarge: Font {
        .custom("Manrope-Regular", size: 20)
    }
    
    static var bodyLarge2: Font {
        .custom("Manrope-Regular", size: 17)
    }
    
    static var labelMedium: Font {
        .custom("PlusJakartaSans-Bold", size: 14)
    }
    static var labelSmall: Font {
        .custom("PlusJakartaSans-Bold", size: 16)
    }
}

// Estensione per applicare facilmente il tracking (letter-spacing)
extension View {
    func trackingLabel() -> some View {
        self.tracking(1.5) // Aggiunge respiro alle etichette maiuscole
    }
}
