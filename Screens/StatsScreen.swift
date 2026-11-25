import SwiftUI
import SwiftData
import Charts

enum StatsPeriod: String, CaseIterable {
    case month = "Месяц"
    case year = "Год"
    case custom = "Свой"
}

struct StatsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allAppointments: [Appointment]
    
    @State private var period: StatsPeriod = .month
    @State private var referenceDate = Date.now
    
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd = Date()
    @State private var showCustomPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Переключатель периода
                    Picker("Период", selection: $period) {
                        ForEach(StatsPeriod.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: period) { _, newValue in
                        if newValue == .custom {
                            showCustomPicker = true
                        }
                    }

                    // 2. Навигация по датам
                    if period != .custom {
                        HStack {
                            Button { shiftDate(-1) } label: { Image(systemName: "chevron.left").padding() }
                            Spacer()
                            Text(periodLabel).font(.headline)
                            Spacer()
                            Button { shiftDate(1) } label: { Image(systemName: "chevron.right").padding() }
                        }
                        .padding(.horizontal)
                    } else {
                        Text(periodLabel).font(.headline).padding(.top, 4)
                    }

                    // 3. Главные плитки (Деньги)
                    HStack(spacing: 12) {
                        SummaryTile(icon: "banknote", title: "Доход", value: "\(NSDecimalNumber(decimal: stats.income).intValue) ₽", tint: .blue)
                        SummaryTile(icon: "cart", title: "Расходники", value: "\(NSDecimalNumber(decimal: stats.materials).intValue) ₽", tint: .orange)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        SummaryTile(icon: "chart.line.uptrend.xyaxis", title: "Чистый доход", value: "\(NSDecimalNumber(decimal: stats.netProfit).intValue) ₽", tint: .green)
                        SummaryTile(icon: "clock", title: "Время работы", value: "\(stats.workHours) ч", tint: .purple)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        SummaryTile(icon: "tag", title: "Средний чек", value: "\(NSDecimalNumber(decimal: stats.averageCheck).intValue) ₽", tint: .pink)
                        SummaryTile(icon: "speedometer", title: "Прибыль/час", value: "\(NSDecimalNumber(decimal: stats.profitPerHour).intValue) ₽", tint: .teal)
                    }
                    .padding(.horizontal)

                    // 4. Сравнение с прошлым периодом
                    if stats.previousIncome > 0 {
                        let diff = stats.income - stats.previousIncome
                        let isPositive = diff >= 0
                        HStack {
                            Image(systemName: isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                .foregroundStyle(isPositive ? .green : .red)
                            Text(isPositive ? "Рост на" : "Падение на")
                                .font(.subheadline)
                            Text("\(NSDecimalNumber(decimal: abs(diff)).intValue) ₽")
                                .font(.subheadline.bold())
                                .foregroundStyle(isPositive ? .green : .red)
                            Text("к прошлому периоду")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // 5. Статусы записей
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Статусы записей").font(.headline)
                        HStack {
                            StatusRow(title: "Выполнено", count: stats.completedCount, color: .green)
                            Spacer()
                            StatusRow(title: "Запланировано", count: stats.plannedCount, color: .blue)
                        }
                        HStack {
                            StatusRow(title: "Перенесено", count: stats.rescheduledCount, color: .orange)
                            Spacer()
                            StatusRow(title: "Отменено/Не пришёл", count: stats.cancelledCount + stats.noShowCount, color: .red)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                    .padding(.horizontal)

                    // 6. Топ-3 Клиентов (за год)
                    if !stats.topClients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Топ клиентов (за год)").font(.headline)
                            ForEach(stats.topClients, id: \.name) { client in
                                HStack {
                                    Text(client.name)
                                    Spacer()
                                    Text("\(NSDecimalNumber(decimal: client.amount).intValue) ₽")
                                        .foregroundStyle(.green)
                                        .bold()
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                    }

                    // 7. Топ-3 Брендов (за 3 месяца)
                    if !stats.topBrands.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Топ брендов краски (3 мес.)").font(.headline)
                            ForEach(stats.topBrands, id: \.name) { brand in
                                HStack {
                                    Text(brand.name)
                                    Spacer()
                                    Text("\(brand.count) раз")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                    }

                    // 8. График
                    if !stats.dailyData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Динамика дохода").font(.headline)
                            Chart(stats.dailyData, id: \.date) { item in
                                BarMark(
                                    x: .value("Дата", item.date, unit: period == .year ? .month : .day),
                                    y: .value("Доход", item.amount)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(MeshBackground())
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let url = ExportManager.exportAppointmentsCSV(appointments: filteredAppointments) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomPicker) {
                CustomDatePicker(start: $customStart, end: $customEnd)
                    .presentationDetents([.height(300)])
            }
        }
    }

    private var periodLabel: String {
        if period == .custom {
            return "\(customStart.formatted(.dateTime.day().month())) – \(customEnd.formatted(.dateTime.day().month()))"
        } else if period == .month {
            return referenceDate.formatted(.dateTime.month(.wide).year())
        } else {
            return referenceDate.formatted(.dateTime.year())
        }
    }

    private func shiftDate(_ direction: Int) {
        let comp: Calendar.Component = period == .month ? .month : .year
        if let newDate = Calendar.current.date(byAdding: comp, value: direction, to: referenceDate) {
            referenceDate = newDate
        }
    }

    private var stats: StatsResult {
        computeStats(period: period, refDate: referenceDate, customStart: customStart, customEnd: customEnd, all: allAppointments)
    }
    
    // ФИЛЬТРОВАННЫЕ ЗАПИСИ ДЛЯ ЭКСПОРТА
    private var filteredAppointments: [Appointment] {
        let cal = Calendar.current
        var start: Date
        var end: Date
        
        switch period {
        case .month:
            start = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))!
            end = cal.date(byAdding: .month, value: 1, to: start)!
        case .year:
            start = cal.date(from: cal.dateComponents([.year], from: referenceDate))!
            end = cal.date(byAdding: .year, value: 1, to: start)!
        case .custom:
            start = cal.startOfDay(for: customStart)
            end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEnd))!
        }
        
        return allAppointments.filter { $0.startDate >= start && $0.startDate < end }
    }
}

// Вспомогательные вью
struct StatusRow: View {
    let title: String
    let count: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text("\(count)").font(.title3.bold())
        }
    }
}

struct CustomDatePicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var start: Date
    @Binding var end: Date
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("С", selection: $start, displayedComponents: .date)
                DatePicker("По", selection: $end, in: start..., displayedComponents: .date)
            }
            .navigationTitle("Свой период")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

// Модель подсчета
struct StatsResult {
    var income: Decimal = 0
    var materials: Decimal = 0
    var netProfit: Decimal { income - materials }
    var workHours: Int = 0
    
    var previousIncome: Decimal = 0
    var averageCheck: Decimal { completedCount > 0 ? income / Decimal(completedCount) : 0 }
    var profitPerHour: Decimal { workHours > 0 ? netProfit / Decimal(workHours) : 0 }
    var topClients: [(name: String, amount: Decimal)] = []
    var topBrands: [(name: String, count: Int)] = []
    
    var completedCount: Int = 0
    var plannedCount: Int = 0
    var rescheduledCount: Int = 0
    var cancelledCount: Int = 0
    var noShowCount: Int = 0
    
    var dailyData: [(date: Date, amount: Double)] = []
}

func computeStats(period: StatsPeriod, refDate: Date, customStart: Date, customEnd: Date, all: [Appointment]) -> StatsResult {
    let cal = Calendar.current
    var start: Date
    var end: Date
    var prevStart: Date
    var prevEnd: Date
    
    switch period {
    case .month:
        start = cal.date(from: cal.dateComponents([.year, .month], from: refDate))!
        end = cal.date(byAdding: .month, value: 1, to: start)!
        prevStart = cal.date(byAdding: .month, value: -1, to: start)!
        prevEnd = start
    case .year:
        start = cal.date(from: cal.dateComponents([.year], from: refDate))!
        end = cal.date(byAdding: .year, value: 1, to: start)!
        prevStart = cal.date(byAdding: .year, value: -1, to: start)!
        prevEnd = start
    case .custom:
        start = cal.startOfDay(for: customStart)
        end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEnd))!
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 1
        prevStart = cal.date(byAdding: .day, value: -days, to: start)!
        prevEnd = start
    }
    
    let filtered = all.filter { $0.startDate >= start && $0.startDate < end }
    let prevFiltered = all.filter { $0.startDate >= prevStart && $0.startDate < prevEnd }
    
    var res = StatsResult()
    res.previousIncome = prevFiltered.filter { $0.status == .completed }.reduce(0) { $0 + $1.price }
    
    for a in filtered {
        switch a.status {
        case .completed:
            res.completedCount += 1
            res.income += a.price
            res.materials += a.materialCost
            let diff = a.endDate.timeIntervalSince(a.startDate)
            res.workHours += Int(diff / 3600)
        case .planned: res.plannedCount += 1
        case .rescheduled: res.rescheduledCount += 1
        case .cancelled: res.cancelledCount += 1
        case .noShow: res.noShowCount += 1
        }
    }
    
    let completed = filtered.filter { $0.status == .completed }
    
    // --- ТОП-3 КЛИЕНТОВ ЗА ГОД ---
    let yearStart = cal.date(from: cal.dateComponents([.year], from: refDate))!
    let yearEnd = cal.date(byAdding: .year, value: 1, to: yearStart)!
    let yearCompleted = all.filter { $0.startDate >= yearStart && $0.startDate < yearEnd && $0.status == .completed }
    
    let clientGroup = Dictionary(grouping: yearCompleted) { $0.client?.name ?? "Без имени" }
    res.topClients = clientGroup.map { (name, appts) in
        (name, appts.reduce(0) { $0 + $1.price })
    }.sorted { $0.1 > $1.1 }.prefix(3).map { $0 }
    
    // --- ТОП-3 БРЕНДОВ ЗА ПОСЛЕДНИЕ 3 МЕСЯЦА ---
    let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: Date())!
    let recentCompleted = all.filter { $0.startDate >= threeMonthsAgo && $0.startDate <= Date() && $0.status == .completed }
    
    let brands = recentCompleted.compactMap { $0.formula?.brand }.filter { !$0.isEmpty }
    let brandGroup = Dictionary(grouping: brands, by: { $0 })
    res.topBrands = brandGroup.map { (name, items) in
        (name, items.count)
    }.sorted { $0.1 > $1.1 }.prefix(3).map { $0 }
    
    let grouped = Dictionary(grouping: completed) { a in
        period == .year ? cal.date(from: cal.dateComponents([.year, .month], from: a.startDate))! : cal.startOfDay(for: a.startDate)
    }
    res.dailyData = grouped.map { (date, appts) in
        (date, NSDecimalNumber(decimal: appts.reduce(0) { $0 + $1.price }).doubleValue)
    }.sorted { $0.date < $1.date }
    
    return res
}
