import Foundation

struct Formatters {
    // MARK: - Turkish Locale
    static let turkishLocale = Locale(identifier: "tr_TR")
    
    // MARK: - Number Formatters
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = turkishLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter
    }()
    
    static let gramFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = turkishLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter
    }()
    
    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = turkishLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        return formatter
    }()
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = turkishLocale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Date Formatters
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = turkishLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = turkishLocale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = turkishLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = turkishLocale
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = turkishLocale
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
    
    // MARK: - Helper Methods
    static func formatGrams(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        return "\(gramFormatter.string(from: NSNumber(value: value)) ?? "0") gr"
    }
    
    static func formatNumber(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        return numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    static func formatInteger(_ value: Int?) -> String {
        guard let value = value else { return "–" }
        return integerFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    static func formatAdet(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        return "\(numberFormatter.string(from: NSNumber(value: value)) ?? "0") adet"
    }
    
    static func formatPercentage(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        return percentageFormatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "–" }
        return dateFormatter.string(from: date)
    }
    
    static func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "–" }
        return timeFormatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "–" }
        return dateTimeFormatter.string(from: date)
    }
    
    static func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "–" }
        return timestampFormatter.string(from: date)
    }
    
    static func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)sa \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
    
    // MARK: - Ayar Conversion for Milyem Calculation
    static func ayarToConversionFactor(_ ayar: Int) -> Double {
        switch ayar {
        case 14: return 585
        case 18: return 750
        case 21: return 875
        case 22: return 916
        default: return 750 // Default to 18 ayar
        }
    }
    
    // MARK: - Parse Double from Turkish formatted string
    static func parseDouble(from string: String) -> Double? {
        let cleanString = string
            .replacingOccurrences(of: ".", with: "")  // Remove thousands separator
            .replacingOccurrences(of: ",", with: ".")  // Replace decimal separator
        return Double(cleanString)
    }
    
    // MARK: - Parse Integer from Turkish formatted string
    static func parseInt(from string: String) -> Int? {
        let cleanString = string.replacingOccurrences(of: ".", with: "")
        return Int(cleanString)
    }
    
    // MARK: - Safe formatting for text fields
    static func safeFormat(_ value: Double?, defaultValue: String = "") -> String {
        guard let value = value, !value.isNaN, !value.isInfinite else { return defaultValue }
        return numberFormatter.string(from: NSNumber(value: value)) ?? defaultValue
    }
    
    static func safeFormatGrams(_ value: Double?, defaultValue: String = "") -> String {
        guard let value = value, !value.isNaN, !value.isInfinite else { return defaultValue }
        return gramFormatter.string(from: NSNumber(value: value)) ?? defaultValue
    }
}

// Alias for easier usage throughout the app
typealias NomisFormatters = Formatters
