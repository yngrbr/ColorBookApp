import Foundation
import SwiftData

struct ExportManager {
    static func exportAppointmentsCSV(appointments: [Appointment]) -> URL? {
        // Заголовки таблицы
        var csvString = "Дата,Время,Клиент,Телефон,Услуга,Цена,Расходники,Прибыль,Статус,Формула\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for a in appointments {
            let date = dateFormatter.string(from: a.startDate)
            let time = timeFormatter.string(from: a.startDate)
            let clientName = a.client?.name ?? "—"
            let phone = a.client?.phone ?? "—"
            let price = NSDecimalNumber(decimal: a.price).stringValue
            let materials = NSDecimalNumber(decimal: a.materialCost).stringValue
            let profit = NSDecimalNumber(decimal: a.price - a.materialCost).stringValue
            let status = a.status.rawValue
            
            let formula = a.formula != nil ? "\(a.formula!.brand) \(a.formula!.composition)" : "—"
            
            // Экранируем кавычки, чтобы CSV не ломался
            let cleanClient = clientName.replacingOccurrences(of: ",", with: "")
            let cleanFormula = formula.replacingOccurrences(of: ",", with: "")
            
            csvString += "\(date),\(time),\(cleanClient),\(phone),\(a.note),\(price),\(materials),\(profit),\(status),\(cleanFormula)\n"
        }
        
        // Сохраняем во временный файл
        let fileName = "ColorNote_Отчет.csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Ошибка создания CSV: \(error)")
            return nil
        }
    }
}
