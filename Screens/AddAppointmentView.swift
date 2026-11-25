import SwiftUI
import SwiftData

struct AddAppointmentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var initialDate: Date = Date.now

    // Данные клиента
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var clientSocial = ""
    
    // Скрытие плашки
    @State private var isSuggestionHidden = false
    
    // Для выбора из базы (кнопка)
    @Query private var allClients: [Client]
    @State private var showClientPicker = false
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var priceString = ""
    @State private var materialCostString = ""
    @State private var isPriceConfirmed = false
    @State private var status: AppointmentStatus = .planned
    
    @State private var brand = ""
    @State private var composition = ""
    @State private var note = ""

    // ПОИСК КЛИЕНТА ПО ТЕЛЕФОНУ
    var suggestedClient: Client? {
        let cleanPhone = clientPhone.trimmingCharacters(in: .whitespaces)
        guard !cleanPhone.isEmpty, cleanPhone != "+7" else { return nil }
        return allClients.first { $0.phone == cleanPhone }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // СЕКЦИЯ: КЛИЕНТ
                        GlassSection(title: "Клиент") {
                            // Кнопка выбора из базы
                            Button {
                                showClientPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(.blue)
                                    Text("Выбрать из базы клиентов")
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                        .foregroundStyle(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                TextField("Имя", text: $clientName)
                                    .font(.system(.body, design: .rounded))
                            }
                            .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)
                                TextField("+7 999 999 99 99", text: $clientPhone)
                                    .font(.system(.body, design: .rounded))
                                    .keyboardType(.phonePad)
                                    .onChange(of: clientPhone) { _, newValue in
                                        clientPhone = formatPhoneNumber(newValue)
                                        // Если номер изменился, сбрасываем скрытие плашки
                                        isSuggestionHidden = false
                                    }
                            }
                            .padding(.vertical, 8)
                            
                            // ПЛАШКА С ПРЕДЛОЖЕНИЕМ И КРЕСТИКОМ
                            if let suggested = suggestedClient, !isSuggestionHidden {
                                HStack(spacing: 8) {
                                    Button {
                                        withAnimation(.snappy) {
                                            clientName = suggested.name
                                            clientSocial = suggested.socialLink
                                            isSuggestionHidden = true
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .foregroundStyle(.orange)
                                            Text("Найден: \(suggested.name). Заполнить?")
                                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                                .foregroundStyle(.primary)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.leading, 12)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    Button {
                                        withAnimation(.snappy) {
                                            isSuggestionHidden = true
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary.opacity(0.7))
                                            .padding(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                                .padding(.vertical, 4)
                            }
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .foregroundStyle(.purple)
                                    .frame(width: 24)
                                TextField("Соцсеть (ссылка)", text: $clientSocial)
                                    .font(.system(.body, design: .rounded))
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // ... (Остальные секции: Время, Финансы, Формула, Заметка) ...
                        // Они остаются без изменений, я не буду их дублировать, чтобы не раздувать сообщение, но в файле они должны быть!
                        GlassSection(title: "Время и Статус") {
                            DatePicker("Начало", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .font(.system(.body, design: .rounded))
                                .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            DatePicker("Конец", selection: $endDate, displayedComponents: [.hourAndMinute])
                                .font(.system(.body, design: .rounded))
                                .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            Picker("Статус", selection: $status) {
                                ForEach(AppointmentStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .font(.system(.body, design: .rounded))
                            .padding(.vertical, 8)
                        }
                        
                        GlassSection(title: "Финансы") {
                            HStack(spacing: 12) {
                                Image(systemName: "banknote.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)
                                TextField("Цена для клиента (₽)", text: $priceString)
                                    .font(.system(.body, design: .rounded))
                                    .keyboardType(.numberPad)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "cart.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                TextField("Расход на материалы (₽)", text: $materialCostString)
                                    .font(.system(.body, design: .rounded))
                                    .keyboardType(.numberPad)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            Toggle("Цена окончательная", isOn: $isPriceConfirmed)
                                .font(.system(.body, design: .rounded))
                                .tint(.green)
                                .padding(.vertical, 8)
                        }
                        
                        GlassSection(title: "Формула окрашивания") {
                            HStack(spacing: 12) {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundStyle(.pink)
                                    .frame(width: 24)
                                TextField("Бренд (напр. Wella)", text: $brand)
                                    .font(.system(.body, design: .rounded))
                            }
                            .padding(.vertical, 8)
                            
                            Divider().background(Color.white.opacity(0.2))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "eyedropper")
                                    .foregroundStyle(.cyan)
                                    .frame(width: 24)
                                TextField("Состав (напр. 7.1 + 6%)", text: $composition)
                                    .font(.system(.body, design: .rounded))
                            }
                            .padding(.vertical, 8)
                        }
                        
                        GlassSection(title: "Заметка") {
                            TextField("Комментарий к записи...", text: $note, axis: .vertical)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(3...6)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Новая запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                    }
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .disabled(clientName.isEmpty)
                }
            }
            .onAppear {
                let calendar = Calendar.current
                var startComponents = calendar.dateComponents([.year, .month, .day], from: initialDate)
                startComponents.hour = 9
                startComponents.minute = 0
                if let newStart = calendar.date(from: startComponents) {
                    startDate = newStart
                } else {
                    startDate = initialDate
                }
                
                var endComponents = calendar.dateComponents([.year, .month, .day], from: initialDate)
                endComponents.hour = 19
                endComponents.minute = 0
                if let newEnd = calendar.date(from: endComponents) {
                    endDate = newEnd
                } else {
                    endDate = initialDate
                }
            }
            .environment(\.locale, Locale(identifier: "ru_RU"))
            .sheet(isPresented: $showClientPicker) {
                ClientPickerView(selectedName: $clientName, selectedPhone: $clientPhone, selectedSocial: $clientSocial)
            }
        }
    }

    private func formatPhoneNumber(_ text: String) -> String {
        var digits = text.filter { $0.isNumber }
        if digits.hasPrefix("9") { digits = "7" + digits }
        if digits.isEmpty { return "" }
        let maxDigits = String(digits.prefix(11))
        var formatted = ""
        for (index, char) in maxDigits.enumerated() {
            if index == 0 { formatted += "+7" }
            else if index == 1 || index == 4 || index == 7 || index == 9 { formatted += " \(char)" }
            else { formatted += String(char) }
        }
        return formatted
    }

    private func save() {
        do {
            let finalPhone = clientPhone.trimmingCharacters(in: .whitespaces) == "+7" ? "" : clientPhone
            
            // ИЩЕМ СУЩЕСТВУЮЩЕГО КЛИЕНТА ПО ТЕЛЕФОНУ
            let existingClient = allClients.first { $0.phone == finalPhone && !finalPhone.isEmpty }
            
            let clientToUse: Client
            if let existing = existingClient {
                existing.name = clientName
                if !clientSocial.isEmpty { existing.socialLink = clientSocial }
                clientToUse = existing
            } else {
                let newClient = Client(name: clientName, phone: finalPhone, socialLink: clientSocial)
                context.insert(newClient)
                clientToUse = newClient
            }

            let appointment = Appointment(
                startDate: startDate,
                endDate: endDate,
                price: Decimal(string: priceString) ?? 0,
                materialCost: Decimal(string: materialCostString) ?? 0,
                isPriceConfirmed: isPriceConfirmed,
                status: status,
                note: note
            )
            appointment.client = clientToUse
            context.insert(appointment)

            if !brand.isEmpty || !composition.isEmpty {
                let formula = ColorFormula(brand: brand, composition: composition, processingTime: 30)
                formula.appointment = appointment
                context.insert(formula)
            }

            try context.save()
            NotificationManager.shared.scheduleAppointmentReminder(for: appointment)
            dismiss()
        } catch {
            print("❌ ОШИБКА СОХРАНЕНИЯ: \(error)")
        }
    }
}

// ОКНО ВЫБОРА КЛИЕНТА ИЗ БАЗЫ
struct ClientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Client.name) private var clients: [Client]
    
    @Binding var selectedName: String
    @Binding var selectedPhone: String
    @Binding var selectedSocial: String
    
    @State private var searchText = ""
    
    var filteredClients: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.phone.contains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClients) { client in
                    Button {
                        selectedName = client.name
                        selectedPhone = client.phone
                        selectedSocial = client.socialLink
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(client.name).font(.headline)
                                if !client.phone.isEmpty {
                                    Text(client.phone).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if client.phone == selectedPhone {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выбрать клиента")
            .searchable(text: $searchText, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
