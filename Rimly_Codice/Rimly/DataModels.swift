import Foundation
import SwiftData

// Modello per le singole giornate
@Model
class DailyStat {
    var id: UUID
    var dayLabel: String
    var percentageFilled: CGFloat
    var minutesMeditated: Int
    var secondsMeditated: Int
    var dailyGoal: Int
    var weekDayIndex: Int // Ci serve per mantenere i giorni in ordine (0 = Lun, 6 = Dom)
    
    init(dayLabel: String, percentageFilled: CGFloat = 0.0, minutesMeditated: Int = 0, secondsMeditated: Int = 0, dailyGoal: Int = 20, weekDayIndex: Int) {
        self.id = UUID()
        self.dayLabel = dayLabel
        self.percentageFilled = percentageFilled
        self.minutesMeditated = minutesMeditated
        self.secondsMeditated = secondsMeditated
        self.dailyGoal = dailyGoal
        self.weekDayIndex = weekDayIndex
    }
}

// Modello per le statistiche globali (Streak, Zen Totale e Data inizio settimana)
@Model
class UserProgress {
    var dailyStreak: Int
    var totalZenMinutes: Int
    var totalZenSeconds: Int
    var currentWeekStartDate: Date
    var lastMeditationDate: Date?
    
    init(dailyStreak: Int = 0, totalZenMinutes: Int = 0, totalZenSeconds: Int = 0, currentWeekStartDate: Date = Date(), lastMeditationDate: Date? = nil) {
        self.dailyStreak = dailyStreak
        self.totalZenMinutes = totalZenMinutes
        self.totalZenSeconds = totalZenSeconds
        self.currentWeekStartDate = currentWeekStartDate
        self.lastMeditationDate = lastMeditationDate
    }
}
