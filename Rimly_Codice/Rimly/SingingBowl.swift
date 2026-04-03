import SwiftUI

// MARK: - Modello Dati Aggiornato

// 1. Modello per la singola campana
struct SingingBowl: Identifiable {
    let id = UUID()
    let categoryName: String
    let note: String
    let frequency: Int
    let imageName: String
    let rubAudio: String
    let strikeAudio: String
}

// 2. Modello per la categoria di campane
struct BowlCategory: Identifiable {
    let id = UUID()
    let name: String         // Es: Mani Bowl, Jambati Bowl...
    let bowls: [SingingBowl] // La lista delle campane in questa categoria
}

struct BellsScreen: View {
    
    private let categories = BowlData.categories
    
    // Rimosso @State private var playingBowlID, ora usiamo direttamente quello dell'AudioManager
    @EnvironmentObject private var audioManager: AudioManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tibetan Bowls")
                        .font(ThemeFonts.displayLarge)
                        .foregroundColor(ThemeColors.onSurface)
                    
                    // Testo leggermente aggiornato per far capire che è un "percorso"
                    Text("Tap a card to select a bowl.")
                        .font(ThemeFonts.bodyLarge)
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .opacity(0.8)
                    Text("Create your own path.")
                        .font(ThemeFonts.bodyLarge)
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .opacity(0.8)
                }
                .padding(.bottom, 8)
                
                // 2. Loop per le Categorie
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // A. Divider
                        if category.id != categories.first?.id {
                            Divider()
                                .opacity(0)
                                .padding(.bottom, 8)
                        }
                        
                        // B. Titolo della Categoria
                        Text(category.name)
                            .font(ThemeFonts.labelSmall)
                            .trackingLabel()
                            .foregroundColor(ThemeColors.tertiary)
                            .textCase(.uppercase)
                            .padding(.bottom, 4)
                        
                        // C. Loop per le Campane
                        VStack(spacing: 24) {
                            ForEach(category.bowls) { bowl in
                                // Controlliamo se la campana è dentro il Set di quelle selezionate
                                let isSelected = audioManager.selectedBowlIDs.contains(bowl.imageName)
                                
                                // Usiamo l'ID gestito in AudioManager per sapere se sta suonando
                                let isPlaying = (bowl.imageName == audioManager.playingBowlID)
                                
                                BowlCard(
                                    bowl: bowl,
                                    isSelected: isSelected,
                                    isPlaying: isPlaying,
                                    onCardTap: {
                                        withAnimation {
                                            // Aggiunge o rimuove la campana dal percorso
                                            audioManager.toggleSelection(for: bowl)
                                        }
                                    },
                                    onPlayPauseTap: {
                                        if isPlaying {
                                            withAnimation {
                                                audioManager.stopPreview()
                                            }
                                        } else {
                                            withAnimation {
                                                audioManager.playPreviewStrike(for: bowl)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onDisappear {
            // Se l'utente cambia schermata (es. va sulla mappa o sulle statistiche)
            // ci assicuriamo di spegnere l'anteprima
            audioManager.stopPreview()
        }
    }
}

// MARK: - Componente per la singola Campana
struct BowlCard: View {
    let bowl: SingingBowl
    let isSelected: Bool
    let isPlaying: Bool
    
    var onCardTap: () -> Void
    var onPlayPauseTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            
            // COLONNA 1: Immagine
            Image(bowl.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(color: ThemeColors.onSurface.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // COLONNA 2: Contenuto testuale
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Note: \(bowl.note)")
                        .font(ThemeFonts.labelMedium)
                        .trackingLabel()
                        .foregroundColor(isSelected ? ThemeColors.tertiary : ThemeColors.secondary)
                        .textCase(.uppercase)
                        .offset(y: -2)
                    
                    Text("\(bowl.frequency )Hz")
                        .font(ThemeFonts.labelMedium)
                        .trackingLabel()
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .textCase(.uppercase)
                        .offset(y: 2)
                }
            }
            
            Spacer()
            
            // COLONNA 3: Area Azioni
            Button(action: onPlayPauseTap) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? ThemeColors.surface : ThemeColors.onSecondaryContainer)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? ThemeColors.tertiary : ThemeColors.secondaryContainer)
                    .clipShape(Circle())
                    .shadow(color: isSelected ? ThemeColors.tertiary.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    .contentTransition(.symbolEffect(.replace))
            }
            .glassEffect(.clear.interactive(), in: .circle)
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPlaying)
        }
        .padding(24)
        .frame(height: 160)
        .glassEffect(
            .regular
                .tint(isSelected ? ThemeColors.primaryContainer.opacity(0.25) : .clear)
                .interactive(),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: ThemeColors.onSurface.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 40 : 20, x: 0, y: 20)
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap()
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        ThemeColors.surface.ignoresSafeArea()
        BellsScreen()
        
        // Finta Horizon Bar
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(height: 80)
            .cornerRadius(40)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
    }
    .environmentObject(AudioManager())
}
