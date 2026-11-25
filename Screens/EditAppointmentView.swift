import SwiftUI
import SwiftData

struct EditAppointmentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var appointment: Appointment
    
    // Для экспорта
    @State private var isSharingFormula = false
    @State private var isSharingVisit = false
    
    // Для полноэкранного фото
    @State private var fullScreenImage: UIImage? = nil
    @State private var scale: CGFloat = 1.0
    
    // Получаем настройки адреса из базы
    @Query private var settings: [AppSettings]
    private var salonAddress: String {
        settings.first?.salonAddress ?? "Адрес не указан"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Клиент") {
                    if let client = appointment.client {
                        TextField("Имя", text: Bindable(client).name)
                        TextField("Телефон", text: Bindable(client).phone)
                        TextField("Соцсеть", text: Bindable(client).socialLink)
                    } else {
                        Text("Клиент не указан")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Время и Статус") {
                    DatePicker("Начало", selection: $appointment.startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Конец", selection: $appointment.endDate, displayedComponents: [.hourAndMinute])
                    
                    Picker("Статус", selection: $appointment.status) {
                        ForEach(AppointmentStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }
                
                Section("Финансы") {
                    TextField("Цена для клиента", value: $appointment.price, format: .number)
                    TextField("Расход на материалы", value: $appointment.materialCost, format: .number)
                    Toggle("Цена окончательная", isOn: $appointment.isPriceConfirmed)
                }
                
                Section("Формула") {
                    if let formula = appointment.formula {
                        TextField("Бренд", text: Bindable(formula).brand)
                        TextField("Состав", text: Bindable(formula).composition)
                        
                        Button {
                            isSharingFormula = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Отправить формулу клиенту")
                            }
                            .foregroundStyle(.blue)
                        }
                    } else {
                        Button("Добавить формулу") {
                            let newFormula = ColorFormula(brand: "", composition: "", processingTime: 30)
                            newFormula.appointment = appointment
                            context.insert(newFormula)
                        }
                    }
                }
                
                Section("Фото (До / После)") {
                    PhotoGalleryView(appointment: appointment) { image in
                        withAnimation(.easeInOut) {
                            fullScreenImage = image
                            scale = 1.0
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Заметка") {
                    TextField("Комментарий", text: $appointment.note, axis: .vertical)
                }
                
                Section {
                    Button {
                        isSharingVisit = true
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.green)
                            Text("Отправить подтверждение визита")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // НОВАЯ СЕКЦИЯ УДАЛЕНИЯ ЗАПИСИ
                Section {
                    Button(role: .destructive) {
                        // Отменяем уведомление перед удалением
                        NotificationManager.shared.cancelReminder(for: appointment)
                        
                        context.delete(appointment)
                        try? context.save()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Удалить запись")
                                .font(.system(.body, design: .rounded).weight(.bold))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        try? context.save()
                        // Планируем уведомление при сохранении
                        NotificationManager.shared.scheduleAppointmentReminder(for: appointment)
                        dismiss()
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "ru_RU"))
            
            // ОКНО ДЛЯ ОТПРАВКИ ФОРМУЛЫ
            .sheet(isPresented: $isSharingFormula) {
                if let formula = appointment.formula {
                    let text = "Ваша формула окрашивания: \(formula.brand) — \(formula.composition). Время выдержки: \(formula.processingTime) мин."
                    SharingView(text: text, isPresented: $isSharingFormula)
                }
            }
            
            // ОКНО ДЛЯ ОТПРАВКИ ВИЗИТА
            .sheet(isPresented: $isSharingVisit) {
                let dateStr = appointment.startDate.formatted(.dateTime.day().month(.wide).weekday(.wide).locale(Locale(identifier: "ru_RU")))
                let timeStr = appointment.startDate.formatted(date: .omitted, time: .shortened)
                let clientName = appointment.client?.name ?? "Клиент"
                
                let text = """
                Здравствуйте, \(clientName)!
                
                Подтверждаю вашу запись:
                📅 \(dateStr)
                🕒 \(timeStr)
                📍 \(salonAddress)
                
                Ждем вас! Если планы изменятся, пожалуйста, предупредите заранее.
                """
                
                SharingView(text: text, isPresented: $isSharingVisit)
            }
        }
        // НАЛОЖЕНИЕ ФОТО НА ВЕСЬ ЭКРАН (С ЗУМОМ)
        .overlay {
            if let image = fullScreenImage {
                ZStack {
                    // СЕРЫЙ МАТОВЫЙ ФОН
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .opacity(0.95)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                fullScreenImage = nil
                                scale = 1.0
                            }
                        }
                    
                    // ФОТО С ЖЕСТАМИ
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
                        .padding(20)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in scale = value }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        if scale < 1.0 { scale = 1.0 }
                                        else if scale > 4.0 { scale = 4.0 }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                scale = scale > 1.0 ? 1.0 : 2.5
                            }
                        }
                    
                    // КРЕСТИК
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeInOut) {
                                    fullScreenImage = nil
                                    scale = 1.0
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.primary, .ultraThinMaterial)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
                .zIndex(999)
                .transition(.opacity)
            }
        }
    }
}

// УНИВЕРСАЛЬНЫЙ ЭКРАН ДЛЯ ОТПРАВКИ ТЕКСТА
struct SharingView: View {
    let text: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Сообщение готово")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                Text(text)
                    .padding()
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
            .frame(maxHeight: 200)
            
            ShareLink(item: text) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Поделиться")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Button("Закрыть") {
                isPresented = false
            }
            .foregroundStyle(.secondary)
            .padding(.bottom)
        }
        .presentationDetents([.height(400)])
    }
}
