import SwiftUI
import SwiftData

@main
struct MyApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            CalendarScreen()
        }
        .modelContainer(for: [Client.self, Appointment.self, ColorFormula.self, DayOff.self, AppSettings.self])
    }
}
