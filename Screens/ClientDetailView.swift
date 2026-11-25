import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Bindable var client: Client
    @Environment(\.modelContext) private var context
    
    // Сортируем историю визитов от новых к старым
    var history: [Appointment] {
        client.appointments.sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        ZStack {
            MeshBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // СЕКЦИЯ: ДАННЫЕ КЛИЕНТА
                    GlassSection(title: "Контакты") {
                        HStack {
                            Text("Имя")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Имя", text: $client.name)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .padding(.vertical, 8)
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Телефон")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Телефон", text: $client.phone)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .rounded))
                                .keyboardType(.phonePad)
                        }
                        .padding(.vertical, 8)
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack {
                            Text("Соцсеть")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Ссылка", text: $client.socialLink)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .rounded))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // СЕКЦИЯ: ИСТОРИЯ ВИЗИТОВ
                    GlassSection(title: "История визитов (\(history.count))") {
                        if history.isEmpty {
                            Text("Пока нет визитов")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(history) { appointment in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(appointment.startDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        Spacer()
                                        Text("\(NSDecimalNumber(decimal: appointment.price).intValue) ₽")
                                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                                            .foregroundStyle(.green)
                                    }
                                    
                                    if let formula = appointment.formula, !formula.brand.isEmpty {
                                        Text("\(formula.brand) · \(formula.composition)")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if appointment != history.last {
                                    Divider().background(Color.white.opacity(0.2))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Сохраняем изменения при выходе
            try? context.save()
        }
    }
}
