/*
 KLineEntity CoreDataClass
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

/*
 // KLineEntity Core Data类扩展
 // K线数据实体类
 */

@objc(KLineEntity)
public class KLineEntity: NSManagedObject {
    
    // MARK: - 便利属性
    
    /// 时间周期枚举
    enum TimeFrame: String, CaseIterable {
        case oneMinute = "1m"
        case fiveMinutes = "5m"
        case fifteenMinutes = "15m"
        case thirtyMinutes = "30m"
        case oneHour = "1h"
        case oneDay = "1d"
        case oneWeek = "1w"
        case oneMonth = "1M"
        
        var displayName: String {
            switch self {
            case .oneMinute: return "1分钟"
            case .fiveMinutes: return "5分钟"
            case .fifteenMinutes: return "15分钟"
            case .thirtyMinutes: return "30分钟"
            case .oneHour: return "1小时"
            case .oneDay: return "日线"
            case .oneWeek: return "周线"
            case .oneMonth: return "月线"
            }
            return ""  // 默认返回值
        }
    }
    
    /// 时间周期类型
    var timeFrameType: TimeFrame? {
        return TimeFrame(rawValue: timeframe)
    }
    
    /// 涨跌额
    var change: Double {
        return close - open
    }
    
    /// 涨跌幅
    var changePercent: Double {
        guard open > 0 else { return 0 }
        return (change / open) * 100
    }
    
    /// 振幅
    var amplitude: Double {
        guard open > 0 else { return 0 }
        return ((high - low) / open) * 100
    }
    
    /// 是否上涨
    var isUp: Bool {
        return close > open
    }
    
    /// 是否下跌
    var isDown: Bool {
        return close < open
    }
    
    /// 是否十字星
    var isDoji: Bool {
        return close == open
    }
    
    /// 实体大小（相对于开盘价的百分比）
    var bodySize: Double {
        guard open > 0 else { return 0 }
        return abs(close - open) / open * 100
    }
    
    /// 上影线长度（相对于开盘价的百分比）
    var upperShadow: Double {
        guard open > 0 else { return 0 }
        let bodyTop = max(open, close)
        return (high - bodyTop) / open * 100
    }
    
    /// 下影线长度（相对于开盘价的百分比）
    var lowerShadow: Double {
        guard open > 0 else { return 0 }
        let bodyBottom = min(open, close)
        return (bodyBottom - low) / open * 100
    }
    
    // MARK: - 便利方法
    
    /// 更新K线数据
    func updateOHLC(
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Int64,
        amount: Double
    ) {
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.amount = amount
    }
    
    /// 格式化时间显示
    var formattedTime: String {
        let formatter = DateFormatter()
        switch timeFrameType {
        case .oneMinute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes, .oneHour:
            formatter.dateFormat = "HH:mm"
        case .oneDay:
            formatter.dateFormat = "MM-dd"
        case .oneWeek, .oneMonth:
            formatter.dateFormat = "yyyy-MM"
        case .none:
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: timestamp)
    }
    
    /// 格式化价格（保留两位小数）
    func formatPrice(_ price: Double) -> String {
        return String(format: "%.2f", price)
    }
    
    /// K线数据描述
    var description: String {
        return "O:\(formatPrice(open)) H:\(formatPrice(high)) L:\(formatPrice(low)) C:\(formatPrice(close))"
    }
    
    /// 成交量显示
    var formattedVolume: String {
        if volume >= 100_000_000 {
            return String(format: "%.1f亿", Double(volume) / 100_000_000)
        } else if volume >= 10_000 {
            return String(format: "%.1f万", Double(volume) / 10_000)
        } else {
            return "\(volume)"
        }
    }
    
    /// 成交额显示
    var formattedAmount: String {
        if amount >= 100_000_000 {
            return String(format: "%.1f亿", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.1f万", amount / 10_000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}

// MARK: - Identifiable
extension KLineEntity: Identifiable {
    public var id: String { 
        return "\(symbol)_\(timeframe)_\(timestamp.timeIntervalSince1970)"
    }
}

// MARK: - Comparable
extension KLineEntity: Comparable {
    public static func < (lhs: KLineEntity, rhs: KLineEntity) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}

// MARK: - 创建方法
extension KLineEntity {
    /// 创建新的K线数据实体
    static func create(in context: NSManagedObjectContext,
                      symbol: String,
                      timeframe: String,
                      timestamp: Date,
                      open: Double,
                      high: Double,
                      low: Double,
                      close: Double,
                      volume: Int64,
                      amount: Double) -> KLineEntity {
        let kline = KLineEntity(context: context)
        kline.symbol = symbol
        kline.timeframe = timeframe
        kline.timestamp = timestamp
        kline.open = open
        kline.high = high
        kline.low = low
        kline.close = close
        kline.volume = volume
        kline.amount = amount
        return kline
    }
    
    /// 便利的创建方法，从字典数据创建
    static func create(in context: NSManagedObjectContext,
                      symbol: String,
                      timeframe: String,
                      data: [String: Any]) -> KLineEntity? {
        guard let timestampInterval = data["timestamp"] as? TimeInterval,
              let open = data["open"] as? Double,
              let high = data["high"] as? Double,
              let low = data["low"] as? Double,
              let close = data["close"] as? Double,
              let volume = data["volume"] as? Int64,
              let amount = data["amount"] as? Double else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        return create(in: context,
                     symbol: symbol,
                     timeframe: timeframe,
                     timestamp: timestamp,
                     open: open,
                     high: high,
                     low: low,
                     close: close,
                     volume: volume,
                     amount: amount)
    }
}