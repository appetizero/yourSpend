import Foundation
import SwiftData
import SwiftUI
import Combine

@Model
final class Transaction {
    var timestamp: Date
    var amount: Double
    var categoryRawValue: String
    var note: String
    var currency: String = "CNY"
    
    var categoryModel: CategoryModel {
        CategoryManager.shared.getCategory(by: categoryRawValue)
    }

    init(timestamp: Date = Date(), amount: Double, categoryID: String, note: String = "", currency: String = "CNY") {
        self.timestamp = timestamp
        self.amount = amount
        self.categoryRawValue = categoryID
        self.note = note
        self.currency = currency
    }
}

struct Currency: Identifiable, Hashable {
    let id: String
    let symbol: String
    let nameKey: String
    
    var localizedName: String {
        String(localized: String.LocalizationValue(nameKey))
    }
}

struct CategoryModel: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var icon: String
    var isSystem: Bool
}

class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    @AppStorage("savedCategories") private var savedCategoriesJSON: String = ""
    
    var categories: [CategoryModel] {
        get {
            if savedCategoriesJSON.isEmpty {
                return defaultCategories
            }
            guard let data = savedCategoriesJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([CategoryModel].self, from: data) else {
                return defaultCategories
            }
            return decoded
        }
        set {
            objectWillChange.send()
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                savedCategoriesJSON = json
            }
        }
    }
    
    // ✅ 本地化键
    private let defaultCategories: [CategoryModel] = [
        CategoryModel(id: "food", name: String(localized: "category.food"), icon: "fork.knife", isSystem: true),
        CategoryModel(id: "drink", name: String(localized: "category.drink"), icon: "wineglass.fill", isSystem: true),
        CategoryModel(id: "transport", name: String(localized: "category.transport"), icon: "car.fill", isSystem: true),
        CategoryModel(id: "wear", name: String(localized: "category.wear"), icon: "tshirt.fill", isSystem: true),
    ]
    
    func getCategory(by id: String) -> CategoryModel {
        categories.first(where: { $0.id == id }) ?? defaultCategories.last!
    }
    
    func addCategory(name: String, icon: String) {
        var current = categories
        let newCat = CategoryModel(id: UUID().uuidString, name: name, icon: icon, isSystem: false)
        if let otherIndex = current.firstIndex(where: { $0.id == "other" }) {
            current.insert(newCat, at: otherIndex)
        } else {
            current.append(newCat)
        }
        categories = current
    }
    
    func deleteCategory(at offsets: IndexSet) {
        var current = categories
        let indicesToDelete = offsets.filter { !current[$0].isSystem }
        for index in indicesToDelete.reversed() {
            current.remove(at: index)
        }
        categories = current
    }
}

class ExchangeRateManager {
    static let shared = ExchangeRateManager()
    
    private let ratesToCNY: [String: Double] = [
        "CNY": 1.0,
        "USD": 7.25,
        "GBP": 9.20,
        "EUR": 7.85,
        "JPY": 0.048,
        "KRW": 0.0054
    ]
    
    func convert(amount: Double, from currencyCode: String, to targetCurrency: String) -> Double {
        let fromRate = ratesToCNY[currencyCode] ?? 1.0
        let toRate = ratesToCNY[targetCurrency] ?? 1.0
        let amountInCNY = amount * fromRate
        return amountInCNY / toRate
    }
    
    func getSymbol(for code: String) -> String {
        switch code {
        case "CNY", "JPY": return "¥"
        case "USD": return "$"
        case "GBP": return "£"
        case "EUR": return "€"
        case "KRW": return "₩"
        default: return code
        }
    }
}
