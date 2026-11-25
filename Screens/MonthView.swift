import SwiftUI
import SwiftData

struct MonthView: View {
    @Binding var selectedDate: Date
    @Binding var scale: CalendarScale
    let allAppointments: [Appointment]
    let allDayOffs: [DayOff]

    private let calendar = Calendar.current
    private let daysOfWeek = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var russianMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(russianMonthFormatter.string(from: selectedDate).capitalized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 50)
                    }

                    ForEach(daysInMonth, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        
                        let dayAppointments = allAppointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
                        let isDayOff = allDayOffs.contains { calendar.isDate($0.date, inSameDayAs: date) }
                        let dominantStatus = getDominantStatus(dayAppointments)
                        
                        // ЦВЕТА: ВЫХОДНОЙ ФИОЛЕТОВЫЙ, ПЕРЕНЕСЕНО РОЗОВЫЙ
                        let statusColor: Color = {
                            if isDayOff { return .purple }
                            guard let status = dominantStatus else { return .clear }
                            switch status {
                            case .completed: return .green
                            case .planned: return .yellow
                            case .rescheduled: return .pink
                            case .cancelled, .noShow: return .red
                            }
                        }()
                        
                        let selectedBgColor = Color(.darkGray)

                        Button {
                            selectedDate = date
                            withAnimation { scale = .day }
                        } label: {
                            VStack(spacing: 4) {
                                Text(date, format: .dateTime.day())
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(isSelected || isToday ? .bold : .regular)
                                    .foregroundStyle(isSelected ? .white : (isDayOff ? .black.opacity(0.8) : (dominantStatus != nil ? .black.opacity(0.8) : (isToday ? .blue : .primary))))

                                Circle()
                                    .fill(isSelected ? .white : statusColor)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? selectedBgColor : (statusColor.opacity(statusColor == .clear ? 0 : 0.2)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isToday && !isSelected ? Color.blue : (isSelected ? Color.clear : (statusColor.opacity(statusColor == .clear ? 0 : 0.3))), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
        }
    }

    private var firstWeekdayOffset: Int {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let firstOfMonth = calendar.date(from: components) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return (weekday + 5) % 7
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }
    
    private func getDominantStatus(_ appointments: [Appointment]) -> AppointmentStatus? {
        if appointments.isEmpty { return nil }
        if appointments.contains(where: { $0.status == .completed }) { return .completed }
        if appointments.contains(where: { $0.status == .planned }) { return .planned }
        if appointments.contains(where: { $0.status == .rescheduled }) { return .rescheduled }
        return .cancelled
    }
}
