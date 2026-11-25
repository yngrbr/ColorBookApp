import SwiftUI

struct SummaryTile: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

struct DayStrip: View {
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    let allDayOffs: [DayOff]

    private let calendar = Calendar.current
    private let daysRange = -7...30
    private let russianShortWeekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysRange, id: \.self) { offset in
                        if let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) {
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            let isDayOff = allDayOffs.contains { calendar.isDate($0.date, inSameDayAs: date) }
                            
                            let dayAppointments = appointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
                            let dominantStatus = getDominantStatus(dayAppointments)
                            
                            // Цвет фона
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
                            
                            let weekday = calendar.component(.weekday, from: date)
                            let dayIndex = (weekday + 5) % 7
                            
                            // Логика контраста текста
                            let isColored = (dominantStatus != nil || isDayOff)
                            let textColor: Color = isSelected ? .white : (isColored ? .black.opacity(0.8) : .primary)
                            let secondaryTextColor: Color = isSelected ? .white.opacity(0.8) : (isColored ? .black.opacity(0.6) : .secondary)
                            
                            VStack(spacing: 2) {
                                Text(russianShortWeekdays[dayIndex])
                                    .font(.caption2)
                                    .foregroundStyle(secondaryTextColor)
                                
                                Text(date, format: .dateTime.day())
                                    .font(.headline)
                                    .foregroundStyle(textColor)
                                
                                // ЭМОДЗИ СТАТУСА
                                if isDayOff {
                                    Text("🌴")
                                        .font(.caption2)
                                } else if let status = dominantStatus {
                                    Text(statusEmoji(status))
                                        .font(.caption2)
                                } else {
                                    Color.clear.frame(width: 10, height: 10)
                                }
                            }
                            .frame(width: 48, height: 66)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isSelected ? Color(.darkGray) : (statusColor.opacity(statusColor == .clear ? 0 : 0.2)))
                                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                            }
                            .overlay(alignment: .top) {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .frame(height: 20)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.8), .white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .inset(by: 1)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.clear, .black.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedDate = date
                                }
                            }
                            .id(date)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onAppear {
                proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
            }
        }
    }
    
    private func getDominantStatus(_ appointments: [Appointment]) -> AppointmentStatus? {
        if appointments.isEmpty { return nil }
        if appointments.contains(where: { $0.status == .completed }) { return .completed }
        if appointments.contains(where: { $0.status == .planned }) { return .planned }
        if appointments.contains(where: { $0.status == .rescheduled }) { return .rescheduled }
        return .cancelled
    }
    
    // ФУНКЦИЯ ДЛЯ ВЫБОРА ЭМОДЗИ
    private func statusEmoji(_ status: AppointmentStatus) -> String {
        switch status {
        case .planned: return "⏳"
        case .completed: return "✅"
        case .cancelled: return "❌"
        case .noShow: return "🚫"
        case .rescheduled: return "🔄"
        }
    }
}

struct GlassSegmentedPicker: View {
    @Binding var selection: CalendarScale
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarScale.allCases) { scale in
                let isSelected = scale == selection
                
                Text(scale.rawValue)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .zIndex(isSelected ? 1 : 0)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .overlay(alignment: .top) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.6), .clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                        .frame(height: 12)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.8), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                                .matchedGeometryEffect(id: "selection", in: animation)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selection = scale
                        }
                    }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct MeshBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: proxy.size.width * 0.8)
                        .blur(radius: 80)
                        .offset(x: -proxy.size.width * 0.3, y: -proxy.size.height * 0.2)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: proxy.size.width * 0.7)
                        .blur(radius: 80)
                        .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: proxy.size.width * 0.6)
                        .blur(radius: 80)
                        .offset(x: -proxy.size.width * 0.1, y: proxy.size.height * 0.4)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct SkeletonCard: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 60, height: 20)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 100, height: 12)
            
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 80, height: 20)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
        .opacity(isPulsing ? 0.6 : 0.3)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct EmptyDayView: View {
    let isDayOff: Bool
    let onAddTap: () -> Void
    
    @State private var isFloating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: isDayOff ? "sun.max.fill" : "calendar.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(isDayOff ? .purple : .blue.opacity(0.8))
            }
            .offset(y: isFloating ? -8 : 8)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isFloating)
            .onAppear {
                isFloating = true
            }
            
            VStack(spacing: 8) {
                Text(isDayOff ? "Выходной день" : "День свободен")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(isDayOff ? "Наслаждайся отдыхом! 🌿" : "Самое время записать клиента")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !isDayOff {
                Button {
                    onAddTap()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить первую запись")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
}

struct FullScreenPhotoView: View {
    let imageData: Data
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in scale = value }
                                .onEnded { _ in withAnimation { scale = 1.0 } }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation { scale = scale > 1 ? 1.0 : 2.0 }
                        }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                        Text("Не удалось загрузить фото")
                    }
                    .foregroundStyle(.white)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .black.opacity(0.5))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
