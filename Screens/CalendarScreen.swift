import SwiftUI
import SwiftData
import UIKit

struct CalendarScreen: View {
    @Environment(\.modelContext) private var context
    @State private var state = CalendarState()
    @State private var showAddSheet = false
    @State private var appointmentToEdit: Appointment?
    @State private var appointmentToDelete: Appointment?
    @State private var appointmentForReminder: Appointment? // ДЛЯ ОКНА НАПОМИНАНИЯ
    @State private var showStats = false
    @State private var showSettings = false
    @State private var showClients = false
    @State private var showDayOffAlert = false
    @State private var isLoading = true
    
    // ДЛЯ ПЕРЕХВАТА УВЕДОМЛЕНИЙ
    @State private var notificationHandler = NotificationHandler.shared
    
    @Query private var allAppointments: [Appointment]
    @Query private var allDayOffs: [DayOff]

    private var russianDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GlassSegmentedPicker(selection: $state.scale)

                if state.scale == .day {
                    DayStrip(selectedDate: $state.selectedDate, appointments: allAppointments, allDayOffs: allDayOffs)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Spacer().frame(height: 12)
                }

                ZStack {
                    switch state.scale {
                    case .year:
                        YearView(selectedDate: $state.selectedDate, scale: $state.scale, allAppointments: allAppointments, allDayOffs: allDayOffs)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity.combined(with: .scale(scale: 1.05))))
                        
                    case .month:
                        MonthView(selectedDate: $state.selectedDate, scale: $state.scale, allAppointments: allAppointments, allDayOffs: allDayOffs)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity.combined(with: .scale(scale: 1.05))))
                        
                    case .day:
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(russianDayFormatter.string(from: state.selectedDate).capitalized)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                
                                if isCurrentDayOff {
                                    Text("Выходной день")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.9), in: Capsule())
                                }
                                
                                Text("Записей: \(dayAppointments.count)")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            
                            if isLoading {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(0..<3) { _ in SkeletonCard() }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if dayAppointments.isEmpty {
                                EmptyDayView(isDayOff: isCurrentDayOff) { showAddSheet = true }
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(dayAppointments) { a in
                                            Button { appointmentToEdit = a } label: {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack(spacing: 8) {
                                                        Text(a.client?.name ?? "Без имени")
                                                            .font(.system(.title3, design: .rounded).weight(.bold))
                                                            .foregroundStyle(.primary)
                                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                        
                                                        if !a.isPriceConfirmed { Text("~").font(.system(.title3, design: .rounded)).foregroundStyle(.secondary) }
                                                        
                                                        Spacer()
                                                        
                                                        Text("\(NSDecimalNumber(decimal: a.price).intValue) ₽")
                                                            .font(.system(.title3, design: .rounded).weight(.semibold))
                                                            .foregroundStyle(.green.opacity(0.9))
                                                    }
                                                    
                                                    HStack(spacing: 12) {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "clock").font(.caption)
                                                            Text("\(a.startDate.formatted(date: .omitted, time: .shortened)) – \(a.endDate.formatted(date: .omitted, time: .shortened))")
                                                                .font(.system(.caption, design: .rounded).weight(.medium))
                                                        }
                                                        .foregroundStyle(.secondary)
                                                        
                                                        Spacer()
                                                        
                                                        if let phone = a.client?.phone, !phone.isEmpty {
                                                            Button { call(phone) } label: {
                                                                Image(systemName: "phone.fill").font(.caption.weight(.bold)).foregroundStyle(.primary.opacity(0.8))
                                                                    .padding(6).background(.ultraThinMaterial, in: Circle()).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                            }.buttonStyle(.plain)
                                                        }
                                                        
                                                        if let social = a.client?.socialLink, !social.isEmpty {
                                                            Button { openLink(social) } label: {
                                                                Image(systemName: "link").font(.caption.weight(.bold)).foregroundStyle(.primary.opacity(0.8))
                                                                    .padding(6).background(.ultraThinMaterial, in: Circle()).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                            }.buttonStyle(.plain)
                                                        }
                                                    }
                                                    
                                                    Rectangle().fill(LinearGradient(colors: [.primary.opacity(0.0), .primary.opacity(0.15), .primary.opacity(0.0)], startPoint: .leading, endPoint: .trailing)).frame(height: 1).padding(.vertical, 2)
                                                    
                                                    HStack {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: statusIcon(a.status)).font(.caption2.weight(.bold))
                                                            Text(a.status.rawValue).font(.system(.caption2, design: .rounded).weight(.bold))
                                                        }
                                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                                        .background(statusColor(a.status).opacity(0.15), in: Capsule())
                                                        .foregroundStyle(statusColor(a.status))
                                                        
                                                        if a.materialCost > 0 {
                                                            Text("Расходники: \(NSDecimalNumber(decimal: a.materialCost).intValue) ₽").font(.system(.caption, design: .rounded)).foregroundStyle(.secondary).padding(.leading, 8)
                                                        }
                                                        
                                                        Spacer()
                                                    }
                                                    
                                                    if let f = a.formula, !f.brand.isEmpty || !f.composition.isEmpty {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "paintpalette").font(.caption2)
                                                            Text("\(f.brand) · \(f.composition)").font(.system(.caption, design: .rounded))
                                                        }.foregroundStyle(.secondary)
                                                    }
                                                }
                                                .padding(16)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
                                                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                                                        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)) }
                                                }
                                                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) }
                                                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).inset(by: 1).stroke(Color.white.opacity(0.2), lineWidth: 0.5) }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 80)
                                }
                            }
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity.combined(with: .scale(scale: 1.05))))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.scale)
            }
            .background {
                MeshBackground()
                    .ignoresSafeArea()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showDayOffAlert = true } label: {
                        Image(systemName: isCurrentDayOff ? "sun.max.fill" : "moon.zzz").foregroundStyle(isCurrentDayOff ? .purple : .primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("C").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)).shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                        Text("olorNote").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(LinearGradient(colors: [.primary, .primary.opacity(0.6)], startPoint: .top, endPoint: .bottom)).shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape").font(.headline).foregroundStyle(.primary).frame(width: 36, height: 36).background(.ultraThinMaterial, in: Circle())
                        }
                        
                        Menu {
                            Button { showStats = true } label: {
                                Label("Статистика", systemImage: "chart.bar.xaxis")
                            }
                            Button { showClients = true } label: {
                                Label("Клиенты", systemImage: "person.2.fill")
                            }
                            
                            Divider()
                            
                            Link(destination: URL(string: "https://yngrbr.github.io/colorbook/")!) {
                                Label("Политика конфиденциальности", systemImage: "shield.checkerboard")
                            }
                            
                            Link(destination: URL(string: "https://yngrbr.github.io/colorbook/")!) {
                                Label("Поддержка", systemImage: "envelope")
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !isCurrentDayOff {
                    Button { showAddSheet = true } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 60, height: 60).shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                            Circle().fill(LinearGradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 52, height: 52)
                            Image(systemName: "plus").font(.title2.weight(.bold)).foregroundStyle(.white)
                        }
                        .overlay { Circle().stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) }
                    }.padding(20)
                }
            }
            .sheet(isPresented: $showAddSheet) { AddAppointmentView(initialDate: state.selectedDate) }
            .sheet(item: $appointmentToEdit) { appointment in EditAppointmentView(appointment: appointment) }
            .sheet(isPresented: $showStats) { StatsScreen() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showClients) { ClientsScreen() }
            
            // ОКНО ДЛЯ НАПОМИНАНИЯ КЛИЕНТУ (ПРИ НАЖАТИИ НА УВЕДОМЛЕНИЕ)
            .sheet(item: $appointmentForReminder) { appointment in
                ReminderShareView(appointment: appointment)
            }
            
            .alert("Выходной день", isPresented: $showDayOffAlert) {
                Button(isCurrentDayOff ? "Сделать рабочим" : "Сделать выходным", role: isCurrentDayOff ? .none : .destructive) { toggleDayOff() }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text(isCurrentDayOff ? "Этот день сейчас выходной. Хотите открыть его для записи?" : "Вы уверены, что хотите сделать этот день выходным? Записи будут заблокированы.")
            }
            
            .alert("Удалить запись?", isPresented: .constant(appointmentToDelete != nil)) {
                Button("Отмена", role: .cancel) {
                    appointmentToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    if let a = appointmentToDelete {
                        deleteAppointment(a)
                    }
                    appointmentToDelete = nil
                }
            } message: {
                if let a = appointmentToDelete {
                    Text("Вы уверены, что хотите удалить запись клиента \(a.client?.name ?? "")? Это действие нельзя отменить.")
                } else {
                    Text("Вы уверены?")
                }
            }
            
            .onAppear {
                // ПРОВЕРКА НА ОТЛОЖЕННОЕ УВЕДОМЛЕНИЕ ПРИ ЗАПУСКЕ
                if let id = notificationHandler.pendingAppointmentID {
                    if let appointment = allAppointments.first(where: { String(describing: $0.id) == id }) {
                        appointmentForReminder = appointment
                    }
                    notificationHandler.pendingAppointmentID = nil // Сбрасываем
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) { isLoading = false }
                }
            }
        }
    }

    private var dayAppointments: [Appointment] {
        let start = Calendar.current.startOfDay(for: state.selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return allAppointments.filter { $0.startDate >= start && $0.startDate < end }.sorted { $0.startDate < $1.startDate }
    }
    
    private var isCurrentDayOff: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentStr = formatter.string(from: state.selectedDate)
        return allDayOffs.contains { $0.dateString == currentStr }
    }
    
    private func toggleDayOff() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentStr = formatter.string(from: state.selectedDate)
        
        if let existing = allDayOffs.first(where: { $0.dateString == currentStr }) {
            context.delete(existing)
        } else {
            let newDayOff = DayOff(date: state.selectedDate)
            context.insert(newDayOff)
        }
    }
    
    private func statusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .planned: return .orange
        case .completed: return .green
        case .cancelled, .noShow: return .red
        case .rescheduled: return .pink
        }
    }
    
    private func statusIcon(_ status: AppointmentStatus) -> String {
        switch status {
        case .planned: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "person.crop.circle.badge.xmark"
        case .rescheduled: return "arrow.triangle.2.circlepath"
        }
    }
    
    private func call(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openLink(_ link: String) {
        var formatted = link
        if !formatted.lowercased().hasPrefix("http://") && !formatted.lowercased().hasPrefix("https://") {
            formatted = "https://" + formatted
        }
        if let url = URL(string: formatted) {
            UIApplication.shared.open(url)
        }
    }
    
    private func deleteAppointment(_ appointment: Appointment) {
        NotificationManager.shared.cancelReminder(for: appointment)
        withAnimation {
            context.delete(appointment)
            try? context.save()
        }
    }
}
