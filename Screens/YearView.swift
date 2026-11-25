import SwiftUI

struct YearView: View {
    @Binding var selectedDate: Date
    @Binding var scale: CalendarScale
    let allAppointments: [Appointment]
    let allDayOffs: [DayOff]
    
    private let calendar = Calendar.current
    
    private var availableYears: [Int] {
        Array(2020...2035)
    }
    
    var body: some View {
        let year = calendar.component(.year, from: selectedDate)
        
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Menu {
                    ForEach(availableYears, id: \.self) { y in
                        Button {
                            if let newDate = calendar.date(from: DateComponents(year: y, month: 1, day: 1)) {
                                withAnimation { selectedDate = newDate }
                            }
                        } label: {
                            if y == year {
                                Label(String(y), systemImage: "checkmark")
                            } else {
                                Text(String(y))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(String(year))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.red)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { row in
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(0..<3, id: \.self) { col in
                                    let month = row * 3 + col + 1
                                    MiniMonth(
                                        year: year,
                                        month: month,
                                        selectedDate: $selectedDate,
                                        scale: $scale,
                                        allAppointments: allAppointments,
                                        allDayOffs: allDayOffs
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                                    
                                    if col < 2 {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 1)
                                    }
                                }
                            }
                            
                            if row < 3 {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
    }
}

struct MiniMonth: View {
    let year: Int
    let month: Int
    @Binding var selectedDate: Date
    @Binding var scale: CalendarScale
    let allAppointments: [Appointment]
    let allDayOffs: [DayOff]
    
    private let calendar = Calendar.current
    
    private let russianMonths = [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
    ]
    
    private var russianMonthName: String {
        return russianMonths[month - 1]
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(russianMonthName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: 0) {
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            if dayIndex < week.count, let date = week[dayIndex] {
                                let isToday = calendar.isDateInToday(date)
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let isDayOff = allDayOffs.contains { calendar.isDate($0.date, inSameDayAs: date) }
                                
                                let dayAppointments = allAppointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
                                let dominantStatus = getDominantStatus(dayAppointments)
                                
                                // ЦВЕТА: ВЫХОДНОЙ ФИОЛЕТОВЫЙ
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
                                
                                VStack(spacing: 2) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(size: 10, weight: (isToday || isDayOff || isSelected) ? .bold : .regular))
                                        .foregroundStyle(isSelected ? .white : (statusColor != .clear ? .black.opacity(0.8) : .primary))
                                        .frame(width: 16, height: 16)
                                        .background(
                                            Circle()
                                                .fill(isSelected ? Color(.darkGray) : (statusColor != .clear ? statusColor.opacity(0.25) : (isToday ? Color.blue.opacity(0.15) : Color.clear)))
                                        )
                                        .overlay(
                                            Circle().stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
                                        )
                                    
                                    if isDayOff {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(isSelected ? .white : .purple)
                                            .frame(width: 4, height: 4)
                                    } else if dominantStatus != nil {
                                        Circle()
                                            .fill(isSelected ? .white : statusColor)
                                            .frame(width: 3, height: 3)
                                    } else {
                                        Color.clear.frame(width: 3, height: 3)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .onTapGesture {
                                    selectedDate = date
                                    withAnimation { scale = .month }
                                }
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 24)
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
    }
    
    private var weeks: [[Date?]] {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let firstWeekdayOffset = (weekday + 5) % 7
        
        var allDays: [Date?] = Array(repeating: nil, count: firstWeekdayOffset)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                allDays.append(date)
            }
        }
        
        while allDays.count % 7 != 0 {
            allDays.append(nil)
        }
        
        var result: [[Date?]] = []
        for i in stride(from: 0, to: allDays.count, by: 7) {
            let week = Array(allDays[i..<min(i + 7, allDays.count)])
            result.append(week)
        }
        
        return result
    }
    
    private func getDominantStatus(_ appointments: [Appointment]) -> AppointmentStatus? {
        if appointments.isEmpty { return nil }
        if appointments.contains(where: { $0.status == .completed }) { return .completed }
        if appointments.contains(where: { $0.status == .planned }) { return .planned }
        if appointments.contains(where: { $0.status == .rescheduled }) { return .rescheduled }
        return .cancelled
    }
}
