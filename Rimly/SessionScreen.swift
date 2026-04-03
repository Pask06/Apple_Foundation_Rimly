import SwiftUI
import SwiftData
import ActivityKit


// ============================================================
// MARK: - TimerDuration
// ============================================================
enum TimerDuration: Int, CaseIterable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case twentyFive = 25
    case thirty = 30
    case thirtyFive = 35
    case fourty = 40
    case fortyFive = 45
    case fifty = 50
    
    var label: String { "\(self.rawValue):00" }
    var seconds: Int { self.rawValue * 60 }
}

// ============================================================
// MARK: - SessionScreen
// ============================================================
struct SessionScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgresses: [UserProgress]
    @Query(sort: \DailyStat.weekDayIndex) private var weeklyChartData: [DailyStat]
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var progressViewModel: ProgressViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isBreathing = false
    @State private var selectedDuration: TimerDuration = .twenty
    @State private var totalSeconds: Int = 20 * 60
    @State private var remainingSeconds: Int = 20 * 60
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var timer: Timer? = nil
    @State private var showDurationPicker: Bool = false
    @State private var restartCount: Int = 0
    @State private var backgroundDate: Date? = nil
    @State private var currentActivity: Activity<RimlyTimerAttributes>? = nil
    
    private var elapsed: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }
    
    private var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // ============================================================
    // MARK: - Body
    // ============================================================
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
            .preferredColorScheme(.dark)
            
            VStack {
                Spacer().frame(height: 120)
                timerCircle
                Spacer()
                controlsRow
                Spacer().frame(height: 120)
            }
            
            if showDurationPicker {
                durationPickerOverlay
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if isRunning && !isPaused {
                    backgroundDate = Date()
                    timer?.invalidate()
                    timer = nil
                }
            }
            else if newPhase == .active {
                if isRunning && !isPaused, let bgDate = backgroundDate {
                    let elapsed = Int(Date().timeIntervalSince(bgDate))
                    remainingSeconds = max(remainingSeconds - elapsed, 0)
                    backgroundDate = nil
                    if remainingSeconds <= 0 {
                        finishSession()
                    } else {
                        // Riavvia il timer ora che siamo tornati in foreground
                        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                            if self.remainingSeconds > 0 { self.remainingSeconds -= 1 }
                            else { self.finishSession() }
                        }
                    }
                }
            }
        }
    }
    
    // ============================================================
    // MARK: - Timer Circle
    // ============================================================
    private var timerCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ThemeColors.primary.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 80,
                        endRadius: 200
                    )
                )
                .frame(width: 420, height: 420)
                .scaleEffect(isBreathing ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: isBreathing)
            
            Circle()
                .fill(ThemeColors.primary.opacity(0.08))
                .frame(width: 300, height: 300)
                .overlay(Circle().stroke(ThemeColors.primary.opacity(0.25), lineWidth: 1.5))
                .shadow(color: ThemeColors.primary.opacity(0.2), radius: 20, x: 0, y: 0)
            
            Circle()
                .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 12)
                .frame(width: 300, height: 300)
            
            Circle()
                .trim(from: 0.0, to: elapsed)
                .stroke(
                    AngularGradient(
                        colors: [
                            ThemeColors.tertiary.opacity(0.8),
                            ThemeColors.tertiary,
                            ThemeColors.tertiary.opacity(0.8)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-90))
                .shadow(color: ThemeColors.tertiary.opacity(0.6), radius: 8, x: 0, y: 0)
                .shadow(color: ThemeColors.tertiary.opacity(0.3), radius: 16, x: 0, y: 0)
                .animation(.linear(duration: 1), value: elapsed)
            
            Button(action: {
                if !isRunning && !isPaused {
                    withAnimation(.spring()) { showDurationPicker = true }
                }
            }) {
                // Usiamo uno ZStack in modo che il tempo rimanga SEMPRE ancorato al centro
                ZStack {
                    // La scritta viene posizionata sopra i numeri, senza influenzarne la centratura
                    Text("Tap to set timer")
                        .font(ThemeFonts.labelSmall)
                        .trackingLabel()
                        .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.6))
                        .offset(y: -50) // Sposta la scritta verso l'alto (aggiusta questo valore se necessario)
                        .opacity(!isRunning && !isPaused ? 1.0 : 0.0) // Appare e scompare in modo fluido
                        .animation(.easeInOut(duration: 0.3), value: isRunning || isPaused)
                    
                    // Il timer resta fermo, immobile e perfettamente centrato
                    Text(timeString)
                        .font(.system(size: 80, weight: .medium, design: .rounded))
                        .tracking(-2.0)
                        .foregroundColor(ThemeColors.onSurface)
                        .shadow(
                            color: ThemeColors.tertiary.opacity(0.4),
                            radius: 12, x: 0, y: 0
                        )
                        .monospacedDigit()
                }
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!isRunning && !isPaused)
        }
        .frame(width: 420, height: 420)
    }
    
    // ============================================================
    // MARK: - Controls Row
    // ============================================================
    private var controlsRow: some View {
        HStack(spacing: 32) {
            Button(action: {
                restartTimer()
                restartCount += 1
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
            }
            .glassEffect(.clear.interactive(), in: .circle)
            .opacity(elapsed > 0 ? 1.0 : 0.4)
            .disabled(elapsed == 0)
            .sensoryFeedback(.impact(weight: .medium), trigger: restartCount)
            .contentTransition(.symbolEffect(.replace))
            
            Button(action: { togglePause() }) {
                Image(systemName: isRunning && !isPaused ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(ThemeColors.surfaceContainerLowest)
                    .frame(width: 80, height: 80)
            }
            .buttonStyle(.plain)
            .glassEffect(.clear.interactive(), in: .circle)
            .sensoryFeedback(.impact(weight: .heavy), trigger: isRunning)
            .sensoryFeedback(.impact(weight: .heavy), trigger: isPaused)
            
            Button(action: { stopAndSave() }) {
                Image(systemName: "square.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ThemeColors.tertiary)
                    //.contrast(4.0)
                    .frame(width: 56, height: 56)
                    .opacity(isRunning || isPaused ? 1.0 : 0.3)
                
            }
            .glassEffect(.clear.interactive(), in: .circle)
            .disabled(!isRunning && !isPaused)
            .opacity(isRunning || isPaused ? 1.0 : 0.3)
        }
    }
    
    // ============================================================
    // MARK: - Duration Picker Overlay
    // ============================================================
    private var durationPickerOverlay: some View {
        ZStack {
            // Dimmed backdrop — tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) { showDurationPicker = false }
                }
            
            VStack(spacing: 16) {
                Text("Set up timer")
                    .font(ThemeFonts.headlineSmall)
                    .foregroundColor(ThemeColors.onSurface)
                    .padding(.top, 4)
                
                Picker("Durata", selection: $selectedDuration) {
                    ForEach(TimerDuration.allCases, id: \.self) { duration in
                        Text(duration.label)
                            .tag(duration)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .onChange(of: selectedDuration) { _, newValue in
                    selectDuration(newValue)
                }
                
                Button(action: {
                    withAnimation(.spring()) { showDurationPicker = false }
                }) {
                    Text("Select")
                        .font(ThemeFonts.headlineSmall)
                        .foregroundColor(ThemeColors.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 4)
            }
            .padding(24)
            .glassEffect(
                .regular.tint(ThemeColors.primary.opacity(0.1)).interactive(),
                in: .rect(cornerRadius: 28)
            )
            .padding(.horizontal, 45)
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
    }
    
    // ============================================================
    // MARK: - Actions
    // ============================================================
    
    private func selectDuration(_ duration: TimerDuration) {
        selectedDuration = duration
        totalSeconds = duration.seconds
        remainingSeconds = duration.seconds
    }
    
    private func startTimer() {
        isRunning = true
        isPaused = false
        
        if remainingSeconds == totalSeconds {
            audioManager.startSessionAudio()
        } else {
            audioManager.resumeSessionAudio()
        }
        
        startLiveActivity()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.finishSession()
            }
        }
    }
    
    private func saveElapsedTime() {
        let secondsElapsed = totalSeconds - remainingSeconds
        guard secondsElapsed > 0 else { return }   // Non salvare sessioni a zero
        
        // Controlliamo se esiste già un progresso utente
        let progress: UserProgress
        
        if let existingProgress = userProgresses.first {
            // Se esiste, usiamo quello
            progress = existingProgress
        } else {
            // Se NON esiste (primo avvio in assoluto), ne creiamo uno nuovo
            // sfruttando i valori di default forniti dal tuo modello
            let newProgress = UserProgress()
            
            // Inseriamo il nuovo oggetto nel database (modelContext)
            modelContext.insert(newProgress)
            
            progress = newProgress
        }
        
        // Ora procediamo con l'aggiornamento passando il 'progress' corretto
        progressViewModel.addSession(
            seconds: secondsElapsed,
            context: modelContext,
            stats: weeklyChartData,
            progress: progress
        )
    }
    
    private func finishSession() {
        saveElapsedTime()
        stopTimer()
        audioManager.playStrike()
    }
    
    // Aggiorna questa funzione (o mettila in startTimer)
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let progressValue = Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
        let state = RimlyTimerAttributes.ContentState(endTime: endDate, isPaused: isPaused, progress: progressValue)
        
        if let activity = currentActivity {
            // Se esiste già, aggiornala
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        } else {
            // Creala solo se non esiste
            let bowlName = audioManager.primaryBowlName
            let attributes = RimlyTimerAttributes(bowlName: bowlName)
            do {
                currentActivity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            } catch {
                print("Errore avvio: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopAndSave() {
        saveElapsedTime()
        stopTimer()
    }
    
    // Funzione per chiudere la Live Activity
    private func endLiveActivity() {
        Task {
            let state = RimlyTimerAttributes.ContentState(endTime: Date(), isPaused: true, progress: 1.0)
            await currentActivity?.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
        }
    }
    
    private func togglePause() {
        if isRunning && !isPaused {
            timer?.invalidate()
            timer = nil
            isPaused = true
            isRunning = false
            audioManager.pauseSessionAudio()
        } else if isPaused {
            startTimer()
        } else {
            startTimer()
        }
    }
    
    private func stopTimer() {
        endLiveActivity()
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = totalSeconds
        audioManager.stopSessionAudio()
    }
    
    private func restartTimer() {
        saveElapsedTime()
        remainingSeconds = totalSeconds
        audioManager.stopSessionAudio()
        audioManager.startSessionAudio()
        if currentActivity != nil { startLiveActivity() }
    }
}

#Preview {
    SessionScreen()
        .environmentObject(AudioManager())
        .environmentObject(ProgressViewModel()) // Aggiunto!
        .modelContainer(for: [DailyStat.self, UserProgress.self], inMemory: true) // Aggiunto!
}
