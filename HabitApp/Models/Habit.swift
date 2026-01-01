import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var frequency: [String]      // Días de la semana o ["Diario"]
    var reminderTime: Date?      // Hora de recordatorio (opcional)
    var iconName: String         // Nombre del icono SF Symbol
    var completedDates: [Date] = []  // Fechas en las que se completó el hábito
    
    var dailyNotes: [String: String] = [:]
    var createdAt: Date? = nil
    
    // MARK: - Cálculo de la racha actual
    var currentStreak: Int {
        let sorted = completedDates.sorted(by: >)
        guard let last = sorted.first else { return 0 }
        
        var streak = 1		
        var previousDate = last
        
        for date in sorted.dropFirst() {
            if Calendar.current.isDate(date, inSameDayAs: previousDate.addingTimeInterval(-86400)) {
                streak += 1
                previousDate = date
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Verificar si se completó un día concreto
    func wasCompleted(on date: Date) -> Bool {
        completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    // MARK: - Porcentaje de cumplimiento en el mes actual
    func completionRate(for month: Date = Date()) -> Double {
        let calendar = Calendar.current

        guard
            let range = calendar.range(of: .day, in: .month, for: month),
            let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return 0.0
        }

        let creationDay = createdAt.map { calendar.startOfDay(for: $0) } ?? Date.distantPast

        var activeDays = 0
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth),
               date >= creationDay {
                activeDays += 1
            }
        }

        let completedThisMonth = completedDates.filter {
            calendar.isDate($0, equalTo: month, toGranularity: .month)
        }.count

        return activeDays > 0 ? Double(completedThisMonth) / Double(activeDays) : 0.0
    }
    
    // MARK: - Fecha de última vez completado
    var lastCompletedDate: Date? {
        completedDates.sorted(by: >).first
    }
}
