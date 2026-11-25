import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // Запрос разрешения на уведомления
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self // Устанавливаем делегат для перехвата нажатий
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Разрешение на уведомления получено")
            } else if let error = error {
                print("❌ Ошибка разрешения: \(error.localizedDescription)")
            }
        }
    }
    
    // Планирование уведомления РОВНО ЗА 24 ЧАСА ДО ВИЗИТА
    func scheduleAppointmentReminder(for appointment: Appointment) {
        // Сначала отменяем старое уведомление для этой записи
        cancelReminder(for: appointment)
        
        guard let clientName = appointment.client?.name else { return }
        
        // Вычитаем 24 часа из даты начала
        let reminderDate = appointment.startDate.addingTimeInterval(-24 * 60 * 60)
        
        // Если дата напоминания уже в прошлом, не планируем
        guard reminderDate > Date() else {
            print("⚠️ Дата напоминания в прошлом, уведомление не запланировано")
            return
        }
        
        // Создаем контент уведомления
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о записи"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: appointment.startDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        let dateString = dateFormatter.string(from: appointment.startDate)
        
        content.body = "Завтра (\(dateString)) в \(timeString) запись: \(clientName)"
        content.sound = .default
        
        // ДОБАВЛЯЕМ ID ЗАПИСИ В userInfo
        content.userInfo = ["appointmentID": String(describing: appointment.id)]
        
        // Создаем триггер
        let calendar = Calendar.current
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Создаем запрос
        let request = UNNotificationRequest(
            identifier: String(describing: appointment.id),
            content: content,
            trigger: trigger
        )
        
        // Добавляем в центр уведомлений
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования уведомления: \(error.localizedDescription)")
            } else {
                print("✅ Уведомление запланировано на \(reminderDate) (за 24 часа до \(appointment.startDate))")
            }
        }
    }
    
    // Отмена уведомления
    func cancelReminder(for appointment: Appointment) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(describing: appointment.id)])
    }
    
    // ПЕРЕХВАТ НАЖАТИЯ НА УВЕДОМЛЕНИЕ
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let appointmentID = userInfo["appointmentID"] as? String {
            // СОХРАНЯЕМ ID В ГЛОБАЛЬНЫЙ ОБРАБОТЧИК (ВМЕСТО NOTIFICATIONCENTER)
            NotificationHandler.shared.pendingAppointmentID = appointmentID
        }
        
        completionHandler()
    }
    
    // Показывать уведомление даже когда приложение открыто
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
