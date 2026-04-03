import Foundation
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    
    // Set che contiene gli imageName (ID univoci) delle campane selezionate per il percorso
    @Published var selectedBowlIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(selectedBowlIDs), forKey: "savedBowlIDs")
        }
    }
    
    // Variabile per tracciare quale campana sta riproducendo l'anteprima
    @Published var playingBowlID: String? = nil
    
    // Proprietà calcolata per non rompere la Live Activity in SessionScreen.swift
    var primaryBowlName: String {
        if let firstID = selectedBowlIDs.first,
           let bowl = BowlData.categories.flatMap({ $0.bowls }).first(where: { $0.imageName == firstID }) {
            return selectedBowlIDs.count > 1 ? "Percorso Tibetano" : bowl.categoryName
        }
        return "Tibetan Bowl"
    }
    
    // Player dedicato esclusivamente all'anteprima
    private var previewPlayer: AVAudioPlayer?
    
    // Array di player per permettere l'accavallamento dei suoni durante la sessione
    private var sessionPlayers: [AVAudioPlayer] = []
    
    // Timer che gestisce i rintocchi casuali durante il timer
    private var randomChimeTimer: Timer?
    
    init() {
        if let savedIDs = UserDefaults.standard.stringArray(forKey: "savedBowlIDs"), !savedIDs.isEmpty {
            self.selectedBowlIDs = Set(savedIDs)
        } else {
            // Default: seleziona la prima campana se non c'è nulla di salvato
            if let firstBowl = BowlData.categories.first?.bowls.first {
                self.selectedBowlIDs.insert(firstBowl.imageName)
            }
        }
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Errore nella configurazione della sessione audio: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Gestione Selezione
    
    func toggleSelection(for bowl: SingingBowl) {
        if selectedBowlIDs.contains(bowl.imageName) {
            if selectedBowlIDs.count > 1 { // Impedisce di deselezionare l'ultima rimasta
                selectedBowlIDs.remove(bowl.imageName)
            }
        } else {
            selectedBowlIDs.insert(bowl.imageName)
        }
    }
    
    // MARK: - Riproduzione Anteprima
    
    func playPreviewStrike(for bowl: SingingBowl) {
        // Ferma eventuali anteprime in corso in modo rapido
        stopPreview(duration: 0.1)
        
        // Aggiorna la UI per mostrare che questa campana sta suonando
        self.playingBowlID = bowl.imageName
        
        guard let url = Bundle.main.url(forResource: bowl.strikeAudio, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 1.0
            player.play()
            
            // Assegna il player al previewPlayer per gestirne il ciclo di vita
            self.previewPlayer = player
            
            // Cattura l'istanza per essere sicuri di non fermare una nuova campana se l'utente cambia velocemente
            let capturedPlayer = player
            
            // 1. Aspetta 2.5 secondi, poi inizia la dissolvenza (fade out) di 1.5 secondi per un totale di 4 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self, self.previewPlayer === capturedPlayer else { return }
                
                capturedPlayer.setVolume(0.0, fadeDuration: 1.5)
                
                // 2. Dopo la dissolvenza (1.5s), ferma definitivamente l'audio e resetta l'UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.previewPlayer === capturedPlayer {
                        capturedPlayer.stop()
                        self.previewPlayer = nil
                        self.playingBowlID = nil // Fa tornare l'icona su "Play" nella UI
                    }
                }
            }
        } catch {
            print("Errore strike: \(error.localizedDescription)")
            self.playingBowlID = nil
        }
    }
    
    func stopPreview(duration: TimeInterval = 1.5) {
        guard let player = previewPlayer else {
            playingBowlID = nil
            return
        }
        player.setVolume(0.0, fadeDuration: duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            player.stop()
            
            if self?.previewPlayer === player {
                self?.previewPlayer = nil
                self?.playingBowlID = nil
            }
        }
    }
    
    // MARK: - Logica Percorso Sessione (Timer)
    
    func startSessionAudio() {
        playRandomSelectedBowl()
        scheduleNextRandomChime()
    }
    
    private func scheduleNextRandomChime() {
        randomChimeTimer?.invalidate()
        let randomInterval = TimeInterval.random(in: 15...40)
        
        randomChimeTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { [weak self] _ in
            self?.playRandomSelectedBowl()
            self?.scheduleNextRandomChime()
        }
    }
    
    private func playRandomSelectedBowl() {
        let allBowls = BowlData.categories.flatMap { $0.bowls }
        let selectedBowls = allBowls.filter { selectedBowlIDs.contains($0.imageName) }
        
        guard let randomBowl = selectedBowls.randomElement() else { return }
        
        let useStrike = Bool.random()
        let audioName = useStrike ? randomBowl.strikeAudio : randomBowl.rubAudio
        
        guard let url = Bundle.main.url(forResource: audioName, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = useStrike ? 0 : 2
            player.volume = Float.random(in: 0.7...1.0)
            player.play()
            sessionPlayers.append(player)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.cleanUpPlayers()
            }
        } catch {
            print("Errore rintocco casuale: \(error.localizedDescription)")
        }
    }
    
    private func cleanUpPlayers() {
        sessionPlayers.removeAll { !$0.isPlaying }
    }
    
    func pauseSessionAudio() {
        randomChimeTimer?.invalidate()
        sessionPlayers.forEach { $0.pause() }
    }
    
    func resumeSessionAudio() {
        sessionPlayers.forEach { $0.play() }
        scheduleNextRandomChime()
    }
    
    func stopSessionAudio() {
        randomChimeTimer?.invalidate()
        randomChimeTimer = nil
        
        sessionPlayers.forEach { $0.setVolume(0.0, fadeDuration: 2.0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.sessionPlayers.forEach { $0.stop() }
            self.sessionPlayers.removeAll()
        }
    }
    
    func playStrike() {
        playRandomSelectedBowl()
    }
}
