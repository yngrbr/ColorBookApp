import SwiftData
import Foundation
import Observation

@Model
final class Client {
    var name: String
    var phone: String
    var socialLink: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Appointment.client)
    var appointments: [Appointment] = []

    init(name: String, phone: String = "", socialLink: String = "", notes: String = "") {
        self.name = name
        self.phone = phone
        self.socialLink = socialLink
        self.notes = notes
        self.createdAt = .now
    }
}

enum AppointmentStatus: String, Codable, CaseIterable {
    case planned = "Запланирована"
    case completed = "Выполнена"
    case cancelled = "Отменена"
    case noShow = "Не пришла"
    case rescheduled = "Перенесена"
}

@Model
final class Appointment {
    @Attribute(.unique) var id: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var price: Decimal
    var materialCost: Decimal
    var isPriceConfirmed: Bool
    var statusRaw: String
    var note: String

    // ФОТО "ДО" И "ПОСЛЕ" (ХРАНЯТСЯ ВНЕ БАЗЫ, ЧТОБЫ НЕ ТОРМОЗИТЬ)
    @Attribute(.externalStorage) var photoBefore: Data?
    @Attribute(.externalStorage) var photoAfter: Data?

    var client: Client?
    
    @Relationship(deleteRule: .cascade, inverse: \ColorFormula.appointment)
    var formula: ColorFormula?

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(startDate: Date, endDate: Date, price: Decimal = 0, materialCost: Decimal = 0, isPriceConfirmed: Bool = false, status: AppointmentStatus = .planned, note: String = "") {
        self.startDate = startDate
        self.endDate = endDate
        self.price = price
        self.materialCost = materialCost
        self.isPriceConfirmed = isPriceConfirmed
        self.statusRaw = status.rawValue
        self.note = note
    }
}

@Model
final class ColorFormula {
    var brand: String
    var composition: String
    var processingTime: Int
    var note: String
    var appointment: Appointment?

    init(brand: String, composition: String, processingTime: Int, note: String = "") {
        self.brand = brand
        self.composition = composition
        self.processingTime = processingTime
        self.note = note
    }
}

@Model
final class DayOff {
    @Attribute(.unique) var dateString: String
    var date: Date
    
    init(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.date = Calendar.current.startOfDay(for: date)
    }
}

@Model
final class AppSettings {
    var salonAddress: String
    
    init(salonAddress: String = "г. Москва, ул. Примерная, д. 1") {
        self.salonAddress = salonAddress
    }
}

enum CalendarScale: String, CaseIterable, Identifiable {
    case year = "Год"
    case month = "Месяц"
    case day = "День"
    var id: String { rawValue }
}

@Observable
final class CalendarState {
    var scale: CalendarScale = .day
    var selectedDate: Date = .now
    let cal = Calendar.current
}
