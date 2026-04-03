import SwiftUI

// 
enum AppTab {
    case stats
    case session
    case bells
}

struct ContentView: View {
    
    @State private var selectedTab: AppTab = .session
    
    @StateObject private var audioManager = AudioManager()
    @EnvironmentObject private var progressViewModel: ProgressViewModel
    
    // Inizializzatore per la TabBar
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            Tab(value: AppTab.stats) {
                ZStack {
                    ThemeColors.surface.ignoresSafeArea()
                    ProgressView()
                }
            } label: {
                Image(systemName: "chart.bar.fill")
                Text("Stats")
            }
            
            Tab(value: AppTab.session) {
                SessionScreen()
            } label: {
                Image(systemName: "figure.mind.and.body")
                Text("Session")
            }
            
            Tab(value: AppTab.bells) {
                ZStack{
                    ThemeColors.surface.ignoresSafeArea()
                    BellsScreen()
                }
            } label: {
                Image(systemName: "bell.fill")
                Text("Bowls")
            }
        }
        .tint(ThemeColors.tertiary)
        .preferredColorScheme(ColorScheme.dark)
        .environmentObject(audioManager)
        .environmentObject(progressViewModel)
        .onChange(of: selectedTab) { oldValue, newValue in
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

#Preview {
    ContentView()
}
