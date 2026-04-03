//
//  ProgressView.swift
//  Breath
//

import SwiftUI
import SwiftData
import Combine

// MARK: - ViewModel

class ProgressViewModel: ObservableObject {

    var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 { return 6 }
        return weekday - 2
    }

    func addSession(seconds totalNewSeconds: Int, context: ModelContext,
                    stats: [DailyStat], progress: UserProgress) {
        
        // Somma i secondi accumulati precedentemente ai nuovi
        let combinedSeconds = progress.totalZenSeconds + totalNewSeconds
        let newMinutes = combinedSeconds / 60
        let remainingSeconds = combinedSeconds % 60
        
        // Aggiorna i totali globali
        progress.totalZenMinutes += newMinutes
        progress.totalZenSeconds = remainingSeconds   // Solo il resto (0-59)

        // Logica streak invariata
        let now = Date()
        if let lastDate = progress.lastMeditationDate {
            if Calendar.current.isDateInYesterday(lastDate) {
                progress.dailyStreak += 1
            } else if !Calendar.current.isDateInToday(lastDate) {
                progress.dailyStreak = 1
            }
        } else {
            progress.dailyStreak = 1
        }
        progress.lastMeditationDate = now

        // Aggiorna il giorno corrente con lo stesso meccanismo di carry
        if let todayStat = stats.first(where: { $0.weekDayIndex == todayIndex }) {
            let combinedDaySeconds = todayStat.secondsMeditated + totalNewSeconds
            let newDayMinutes = combinedDaySeconds / 60
            let remainingDaySeconds = combinedDaySeconds % 60
            
            todayStat.minutesMeditated += newDayMinutes
            todayStat.secondsMeditated = remainingDaySeconds
            
            let goal = CGFloat(todayStat.dailyGoal)
            let meditated = CGFloat(todayStat.minutesMeditated)
            todayStat.percentageFilled = min(meditated / goal, 1.0)
        }

        try? context.save()
    }
}

// MARK: - Main View

struct ProgressView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var viewModel: ProgressViewModel

    @Query private var userProgresses: [UserProgress]
    @Query(sort: \DailyStat.weekDayIndex) private var weeklyChartData: [DailyStat]

    let dailyGoalMinutes = 20

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    Text("Progress")
                        .font(ThemeFonts.displayLarge)
                        .foregroundColor(ThemeColors.onSurface)

                    Text("A record of your stillness")
                        .font(ThemeFonts.bodyLarge)
                        .foregroundColor(ThemeColors.onSurfaceVariant)
                        .opacity(0.8)
                }
                .padding(.bottom, 8)

                let currentProgress = userProgresses.first ?? UserProgress()
                let minutesToday = weeklyChartData.first(where: { $0.weekDayIndex == viewModel.todayIndex })?.minutesMeditated ?? 0

                // MARK: Daily Goal Card
                DailyGoalCard(minutesToday: minutesToday, dailyGoalMinutes: dailyGoalMinutes)

                // MARK: Stat Cards
                HStack(spacing: 12) {
                    StatCard(
                        icon: "flame.fill",
                        iconColor: ThemeColors.tertiary,
                        iconBg: ThemeColors.tertiary.opacity(0.12),
                        title: "Daily Streak",
                        value: "\(currentProgress.dailyStreak)",
                        unit: "days"
                    )
                    StatCard(
                        icon: "clock.fill",
                        iconColor: ThemeColors.primary,
                        iconBg: ThemeColors.primary.opacity(0.12),
                        title: "Total Zen",
                        value: "\(currentProgress.totalZenMinutes)",
                        unit: "min"
                    )
                }
                .padding(.top, 12)

                // MARK: Weekly Chart Card
                WeeklyCyclesCard(chartData: weeklyChartData, todayIndex: viewModel.todayIndex)
                    .padding(.top, 12)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 160)
            .onAppear {
                setupInitialDataIfNeeded()
                checkAndResetWeekIfNeeded()
                checkAndResetStreakIfNeeded()
            }
        }
    }

    // MARK: - Setup & Week Management

    private func setupInitialDataIfNeeded() {
        if userProgresses.isEmpty {
            modelContext.insert(UserProgress())
        }
        if weeklyChartData.isEmpty {
            let days = ["M", "T", "W", "T", "F", "S", "S"]
            for (index, label) in days.enumerated() {
                modelContext.insert(DailyStat(dayLabel: label, weekDayIndex: index))
            }
        }
        try? modelContext.save()
    }

    private func checkAndResetWeekIfNeeded() {
        guard let progress = userProgresses.first else { return }
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = Date()
        let currentWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let currentWeekStart = calendar.date(from: currentWeek) ?? now
        if progress.currentWeekStartDate < currentWeekStart {
            progress.currentWeekStartDate = currentWeekStart
            for day in weeklyChartData {
                day.percentageFilled = 0.0
                day.minutesMeditated = 0
                day.secondsMeditated = 0
            }
            try? modelContext.save()
        }
    }

    private func checkAndResetStreakIfNeeded() {
        guard let progress = userProgresses.first,
              let lastDate = progress.lastMeditationDate else { return }
        if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) {
            if progress.dailyStreak != 0 {
                progress.dailyStreak = 0
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Daily Goal Card

struct DailyGoalCard: View {
    let minutesToday: Int
    let dailyGoalMinutes: Int

    private var progress: CGFloat {
        min(CGFloat(minutesToday) / CGFloat(dailyGoalMinutes), 1.0)
    }

    private var percentageText: String {
        "\(Int(progress * 100))% of daily goal"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            //CardSectionLabel("Daily goal")

            HStack(spacing: 30) {
                // Native Apple Gauge
                Gauge(value: Double(minutesToday), in: 0...Double(dailyGoalMinutes)) {
                    EmptyView()
                } currentValueLabel: {
                } minimumValueLabel: {
                    EmptyView()
                } maximumValueLabel: {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(ThemeColors.tertiary)
                .frame(width: 90, height: 90)
                .offset(x:15)
                Spacer()

                // Text block
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Goal")
                        .font(ThemeFonts.labelSmall)
                        .textCase(.uppercase)
                        .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.35))

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(minutesToday)")
                            .font(.custom("Manrope-ExtraBold", size: 36))
                            .foregroundColor(ThemeColors.onSurface)

                        Text("/\(dailyGoalMinutes) min")
                            .font(ThemeFonts.bodyLarge)
                            .font(.system(size: 30))
                            .fontWeight(.medium)
                            .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.4))
                    }
                }
                .offset(x: -20)
            }
        }
        .zenCardStyle()
        .padding(.top, 16)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon badge
            HStack(alignment: .center){
                Image(systemName: icon)
                    .font(.system(size: 25))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                CardSectionLabel(title)
                    .multilineTextAlignment(.trailing)
                    
                    
                    
            }

            Spacer(minLength: 6)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.custom("Manrope-ExtraBold", size: 34))
                    .foregroundColor(ThemeColors.onSurface)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(ThemeFonts.bodyLarge)
                    .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.4))
                    
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCardStyle()
    }
}

// MARK: - Weekly Cycles Card

// MARK: - Weekly Cycles Card

struct WeeklyCyclesCard: View {
    let chartData: [DailyStat]
    let todayIndex: Int

    let maxBarHeight: CGFloat = 110

    // 1. Estraiamo il calcolo come computed property. In questo modo
    // SwiftUI ricalcolerà sempre questo valore quando chartData si aggiorna.
    private var chartMax: Int {
        let maxGoal = chartData.map(\.dailyGoal).max() ?? 20
        let maxMeditated = chartData.map(\.minutesMeditated).max() ?? 0
        // Se si medita 60 min, chartMax diventerà 60.
        // Assicuriamo un minimo di 1 per evitare divisioni per 0.
        return max(maxGoal, maxMeditated, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack(alignment: .center) {
                CardSectionLabel("Weekly cycles")
                Spacer()
            }

            // Chart + Y-axis
            HStack(alignment: .top, spacing: 0) {

                // Y-axis labels dinamicamente legati a chartMax
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(chartMax)m")
                    Spacer()
                    Text("\(chartMax / 2)m")
                    Spacer()
                    Text("0m")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.25))
                .frame(height: maxBarHeight)
                .padding(.vertical, 2)

                // Divider
                Rectangle()
                    .fill(ThemeColors.onSurfaceVariant.opacity(0.1))
                    .frame(width: 0.5, height: maxBarHeight)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 22)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                // Bars
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(chartData.enumerated()), id: \.element.id) { index, data in
                        let isToday = (index == todayIndex)
                        
                        // 2. Calcolo dinamico reale basato sul valore massimo raggiunto nella settimana
                        let dynamicPercentage = CGFloat(data.minutesMeditated) / CGFloat(chartMax)

                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                // Track grigio di sfondo (rappresenta il 100% dell'asse Y attuale)
                                Capsule()
                                    .fill(ThemeColors.surface.opacity(0.5))
                                    .frame(width: 22, height: maxBarHeight)

                                // Fill colorato dei minuti meditati reali
                                Capsule()
                                    .fill(isToday ? ThemeColors.tertiary : ThemeColors.primary.opacity(0.6))
                                    .frame(width: 22, height: maxBarHeight * dynamicPercentage)
                            }
                            .frame(width: 22)
                            // 3. Spostiamo l'animazione sullo ZStack per farla reagire correttamente
                            // a tutte le variazioni di altezza fluide
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: dynamicPercentage)

                            Text(data.dayLabel)
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.4)
                                .foregroundColor(
                                    isToday
                                        ? ThemeColors.tertiary
                                        : ThemeColors.onSurfaceVariant.opacity(0.3)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .zenCardStyle()
    }
}

// MARK: - Shared Label Component

struct CardSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(ThemeFonts.labelSmall)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(ThemeColors.onSurfaceVariant.opacity(0.35))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyStat.self, UserProgress.self, configurations: config)
    
    // 1. Creiamo dati fittizi per la settimana
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    for (index, label) in days.enumerated() {
        // Simuliamo che mercoledì (index 2) l'utente abbia fatto un'ora intera (60 min)
        // e gli altri giorni numeri casuali o bassi
        let minutes = (index == 2) ? 300 : Int.random(in: 5...35)
        
        let stat = DailyStat(dayLabel: label, minutesMeditated: minutes, dailyGoal: 20, weekDayIndex: index)
        container.mainContext.insert(stat)
    }
    
    // 2. Inseriamo il progresso utente
    container.mainContext.insert(UserProgress(dailyStreak: 5, totalZenMinutes: 120))
    
    return ZStack {
        ThemeColors.surface.ignoresSafeArea()
        ProgressView()
    }
    .environmentObject(ProgressViewModel())
    .modelContainer(container)
}
