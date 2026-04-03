import SwiftUI

struct HeadphonesSuggestionView: View {
    @Binding var showSuggestion: Bool
    @State private var isBreathing = true
    
    var body: some View {
        ZStack {
            
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], isBreathing ? [0.3, 0.5] : [0.7, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    ThemeColors.surfaceContainerLowest, ThemeColors.surfaceContainerLow,  ThemeColors.surfaceContainerLowest,
                    ThemeColors.surfaceContainerLow,    ThemeColors.primaryContainer,      ThemeColors.primary.opacity(0.3),
                    ThemeColors.primaryContainer,       ThemeColors.tertiary.opacity(0.5), ThemeColors.tertiary.opacity(0.8)
                ]
            )
            .ignoresSafeArea(.all)
            .preferredColorScheme(ColorScheme.dark)
            .background(.black)
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "airpods")
                    .font(.system(size: 70, weight: .heavy))
                    .foregroundColor(ThemeColors.primary)
                
                VStack() {
                    
                    Text("For an immersive experience and deep relaxation")
                        .font(ThemeFonts.bodyLarge2)
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                    
                    Text("We recommend wearing headphones")
                        .font(ThemeFonts.bodyLarge2)
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)

                }
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                withAnimation {
                    showSuggestion = false
                }
            }
        }
    }
}

struct HeadphonesSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        HeadphonesSuggestionView(showSuggestion: .constant(true))
    }
}
