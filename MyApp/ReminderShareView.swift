import SwiftUI
import SwiftData

struct ReminderShareView: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    
    var salonAddress: String {
        settings.first?.salonAddress ?? "Адрес не указан"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ЗАГОЛОВОК
                HStack {
                    Text("Напоминание клиенту")
                        .font(.headline)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                
                // ТЕКСТ СООБЩЕНИЯ (РАСТЯГИВАЕТСЯ НА ВСЁ ДОСТУПНОЕ МЕСТО)
                ScrollView {
                    Text(generateMessage())
                        .font(.system(.body, design: .rounded))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
                
                // КНОПКА ВНИЗУ
                VStack(spacing: 12) {
                    ShareLink(item: generateMessage()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Поделиться")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .presentationDetents([.large]) // ОКНО НА ВЕСЬ ЭКРАН
            .presentationDragIndicator(.visible) // ПОЛОСКА ДЛЯ СВАЙПА ВНИЗ
        }
    }
    
    private func generateMessage() -> String {
        let dateStr = appointment.startDate.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "ru_RU")))
        let timeStr = appointment.startDate.formatted(date: .omitted, time: .shortened)
        let clientName = appointment.client?.name ?? "Клиент"
        
        return """
        Добрый день, \(clientName)!
        
        Напоминаем, что вы записаны на \(dateStr) в \(timeStr).
        
        Наш адрес: \(salonAddress).
        
        Подтвердите, пожалуйста, визит ответным сообщением: Да или Нет.
        
        Ждем вас! 🌸
        """
    }
}
