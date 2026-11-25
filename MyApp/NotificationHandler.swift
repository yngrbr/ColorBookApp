import SwiftUI
import Combine

@Observable
class NotificationHandler {
    static let shared = NotificationHandler()
    var pendingAppointmentID: String? = nil
}
