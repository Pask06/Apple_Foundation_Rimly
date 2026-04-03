import SwiftUI

// Modificatore per applicare lo stile Zen Card
struct ZenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24) // Spaziatura interna ampia per far respirare il contenuto
            .background(ThemeColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            // Ambient Shadow: un bagliore morbido come richiesto dal design system
            .shadow(color: ThemeColors.onSurface.opacity(0.04), radius: 40, x: 0, y: 20)
    }
}

// Estensione per usarlo facilmente sulle View
extension View {
    func zenCardStyle() -> some View {
        self.modifier(ZenCardModifier())
    }
}

struct Components_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ThemeColors.surface.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Test della Zen Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAILY STREAK")
                        .font(ThemeFonts.labelMedium)
                        .trackingLabel()
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                    
                    Text("12 days")
                        .font(ThemeFonts.displayLarge)
                        .foregroundColor(ThemeColors.onSurface)
                }
                .zenCardStyle()
                
                // Test del Glassmorphism (es. finta barra di navigazione)
                HStack(spacing: 40) {
                    Image(systemName: "equalizer")
                    Image(systemName: "bell.fill")
                    Image(systemName: "figure.mind.and.body")
                }
                .font(.system(size: 24))
                .foregroundColor(ThemeColors.onSurface)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                
                // Test del bottone Primario
                Button("Avvia Sessione") {
                    print("Sessione avviata")
                }
                .buttonStyle(PrimaryGradientButtonStyle())
            }
        }
    }
}
