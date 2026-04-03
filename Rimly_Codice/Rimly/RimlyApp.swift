import SwiftUI
import SwiftData
import Combine

@main
struct RimlyApp: App {
    
    @State private var showHeadphoneSuggestion: Bool = true
    @StateObject private var progressViewModel = ProgressViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(progressViewModel)
                
                if showHeadphoneSuggestion {
                    HeadphonesSuggestionView(showSuggestion: $showHeadphoneSuggestion)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showHeadphoneSuggestion)
        }
        .modelContainer(for: [DailyStat.self, UserProgress.self])
    }
}
