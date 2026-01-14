import Foundation
import SwiftData

@Model
final class Transaction {
    var timestamp: Date
    var amount: Double
    var categoryRawValue: String // 存储枚举的原始值
    var note: String
    
    // 计算属性：方便在 UI 中直接使用枚举
    var category: Category {
        get { Category(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(timestamp: Date = Date(), amount: Double, category: Category, note: String = "") {
        self.timestamp = timestamp
        self.amount = amount
        self.categoryRawValue = category.rawValue
        self.note = note
    }
}

// 配合模型的分类枚举
enum Category: String, CaseIterable, Codable, Identifiable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
