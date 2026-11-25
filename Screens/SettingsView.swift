import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss // ДОБАВЛЯЕМ DISMISS
    @Query private var settings: [AppSettings]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Адрес салона") {
                    if let currentSettings = settings.first {
                        TextField("Адрес", text: Bindable(currentSettings).salonAddress, axis: .vertical)
                            .lineLimit(3...5)
                    } else {
                        Text("Загрузка...")
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        try? context.save() // Сохраняем
                        dismiss()           // ЗАКРЫВАЕМ ОКНО
                    }
                }
            }
            .onAppear {
                if settings.isEmpty {
                    let newSettings = AppSettings()
                    context.insert(newSettings)
                }
            }
        }
    }
}
