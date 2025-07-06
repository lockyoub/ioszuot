/*
 UnifiedModels
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

extension NSDecimalNumber {
    /// 从字符串安全创建NSDecimalNumber
    static func fromString(_ string: String?) -> NSDecimalNumber {
        guard let string = string, !string.isEmpty else {
            return NSDecimalNumber.zero
        }
        let decimal = NSDecimalNumber(string: string)
        return decimal == NSDecimalNumber.notANumber ? NSDecimalNumber.zero : decimal
    }
    
    /// 转换为字符串
    var displayString: String {
        return self.stringValue
    }
}

// MARK: - CoreData实体扩展
// 注意: 实际的CoreData实体类在CoreData目录中定义
// 这里提供一些辅助扩展和数据转换工具

// MARK: - StockEntity扩展 (实际实体在StockEntity+CoreDataClass.swift中定义)
extension StockEntity {
    
    /// 从字典数据更新实体
    func updateFromDictionary(_ data: [String: Any]) {
        if let lastPriceValue = data["lastPrice"] as? Double {
            self.lastPrice = NSDecimalNumber(value: lastPriceValue)
        }
        if let changeValue = data["change"] as? Double {
            self.change = NSDecimalNumber(value: changeValue)
        }
        if let changePercentValue = data["changePercent"] as? Double {
            self.changePercent = NSDecimalNumber(value: changePercentValue)
        }
        if let volumeValue = data["volume"] as? Int64 {
            self.volume = volumeValue
        }
        if let amountValue = data["amount"] as? Double {
            self.amount = NSDecimalNumber(value: amountValue)
        }
        self.timestamp = Date()
    }
}

// MARK: - KLineEntity扩展
extension KLineEntity {
    /// 从字典数据更新K线实体
    func updateFromDictionary(_ data: [String: Any]) {
        if let openValue = data["open"] as? Double {
            self.open = NSDecimalNumber(value: openValue)
        }
        if let highValue = data["high"] as? Double {
            self.high = NSDecimalNumber(value: highValue)
        }
        if let lowValue = data["low"] as? Double {
            self.low = NSDecimalNumber(value: lowValue)
        }
        if let closeValue = data["close"] as? Double {
            self.close = NSDecimalNumber(value: closeValue)
        }
        if let volumeValue = data["volume"] as? Int64 {
            self.volume = volumeValue
        }
        if let amountValue = data["amount"] as? Double {
            self.amount = NSDecimalNumber(value: amountValue)
        }
        if let timeframeValue = data["timeframe"] as? String {
            self.timeframe = timeframeValue
        }
        self.timestamp = Date()
    }
}

// MARK: - 辅助扩展

extension Date {
    func iso8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
}

// 继续定义其他统一模型...
// (由于长度限制，这里只展示核心模型)