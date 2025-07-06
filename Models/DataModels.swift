/*
 DataModels
 // 作者: MiniMax Agent
 */

import Foundation

/*
 // Cleaned data model definitions
 // Contains only non-Core Data structs and enums
 // Core Data实体定义已移至CoreData目录中的单独文件
 */

// MARK: - 非Core Data数据模型

// MARK: - 股票数据结构体 (用于API响应)
public struct StockData: Codable {
    public let symbol: String
    public let name: String
    public let exchange: String
    public let lastPrice: Double
    public let change: Double
    public let changePercent: Double
    public let volume: Int64
    public let amount: Double
    public let timestamp: Date
    
    // Level 5 market data
    public let bidPrices: [Double]
    public let bidVolumes: [Int64]
    public let askPrices: [Double]
    public let askVolumes: [Int64]
    
    public init(symbol: String, name: String, exchange: String, lastPrice: Double, 
                change: Double, changePercent: Double, volume: Int64, amount: Double,
                timestamp: Date, bidPrices: [Double] = [], bidVolumes: [Int64] = [],
                askPrices: [Double] = [], askVolumes: [Int64] = []) {
        self.symbol = symbol
        self.name = name
        self.exchange = exchange
        self.lastPrice = lastPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.timestamp = timestamp
        self.bidPrices = bidPrices
        self.bidVolumes = bidVolumes
        self.askPrices = askPrices
        self.askVolumes = askVolumes
    }
}

// MARK: - 市场股票数据结构体 (用于实时数据)
public struct MarketStockData: Codable {
    public let symbol: String
    public let name: String
    public let exchange: String
    public let lastPrice: Double
    public let change: Double
    public let changePercent: Double
    public let volume: Int64
    public let amount: Double
    public let timestamp: Date
    
    public init(symbol: String, name: String, exchange: String, lastPrice: Double, 
                change: Double, changePercent: Double, volume: Int64, amount: Double, timestamp: Date) {
        self.symbol = symbol
        self.name = name
        self.exchange = exchange
        self.lastPrice = lastPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.timestamp = timestamp
    }
}

// MARK: - 订单簿数据结构体
public struct OrderBookData: Codable {
    public let symbol: String
    public let bidLevels: [OrderBookLevel]
    public let askLevels: [OrderBookLevel]
    public let timestamp: Date
    
    public init(symbol: String, bidLevels: [OrderBookLevel], askLevels: [OrderBookLevel], timestamp: Date) {
        self.symbol = symbol
        self.bidLevels = bidLevels
        self.askLevels = askLevels
        self.timestamp = timestamp
    }
}

// MARK: - 订单簿档位数据
public struct OrderBookLevel: Codable {
    public let price: Double
    public let volume: Int64
    public let level: Int
    
    public init(price: Double, volume: Int64, level: Int) {
        self.price = price
        self.volume = volume
        self.level = level
    }
}

// MARK: - K线数据结构体
public struct KLineData {
    public let symbol: String
    public let timeframe: String
    public let timestamp: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Int64
    public let amount: Double
    
    public init(symbol: String, timeframe: String, timestamp: Date, open: Double, high: Double, 
                low: Double, close: Double, volume: Int64, amount: Double) {
        self.symbol = symbol
        self.timeframe = timeframe
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.amount = amount
    }
}

// MARK: - 交易数据结构体
public struct TradeData {
    public let id: String
    public let symbol: String
    public let direction: TradeDirection
    public let quantity: Int32
    public let price: Double
    public let amount: Double
    public let commission: Double
    public let timestamp: Date
    public let pnl: Double
    
    public init(id: String, symbol: String, direction: TradeDirection, quantity: Int32,
                price: Double, amount: Double, commission: Double, timestamp: Date, pnl: Double) {
        self.id = id
        self.symbol = symbol
        self.direction = direction
        self.quantity = quantity
        self.price = price
        self.amount = amount
        self.commission = commission
        self.timestamp = timestamp
        self.pnl = pnl
    }
}

// MARK: - 持仓数据结构体
public struct PositionData {
    public let symbol: String
    public let quantity: Int32
    public let avgPrice: Double
    public let currentPrice: Double
    public let marketValue: Double
    public let unrealizedPnL: Double
    public let updateTime: Date
    
    public init(symbol: String, quantity: Int32, avgPrice: Double, currentPrice: Double,
                marketValue: Double, unrealizedPnL: Double, updateTime: Date) {
        self.symbol = symbol
        self.quantity = quantity
        self.avgPrice = avgPrice
        self.currentPrice = currentPrice
        self.marketValue = marketValue
        self.unrealizedPnL = unrealizedPnL
        self.updateTime = updateTime
    }
}

// MARK: - 枚举定义

public enum TradeDirection: String, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    
    public var displayName: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        }
    }
}

public enum OrderType: String, CaseIterable {
    case market = "market"
    case limit = "limit"
    case stop = "stop"
    case stopLimit = "stop_limit"
    
    public var displayName: String {
        switch self {
        case .market: return "市价单"
        case .limit: return "限价单"
        case .stop: return "止损单"
        case .stopLimit: return "止损限价单"
        }
    }
}

public enum OrderStatus: String, CaseIterable {
    case pending = "pending"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case cancelled = "cancelled"
    case rejected = "rejected"
    
    public var displayName: String {
        switch self {
        case .pending: return "待成交"
        case .partiallyFilled: return "部分成交"
        case .filled: return "已成交"
        case .cancelled: return "已撤销"
        case .rejected: return "已拒绝"
        }
    }
}

public enum TimeInForce: String, CaseIterable {
    case day = "DAY"
    case gtc = "GTC"    // Good Till Cancelled
    case ioc = "IOC"    // Immediate Or Cancel
    case fok = "FOK"    // Fill Or Kill
    
    public var displayName: String {
        switch self {
        case .day: return "当日有效"
        case .gtc: return "撤销前有效"
        case .ioc: return "立即成交或撤销"
        case .fok: return "全部成交或撤销"
        }
    }
}

// MARK: - API响应模型

public struct APIResponse<T: Codable>: Codable {
    public let success: Bool
    public let data: T?
    public let message: String?
    public let errorCode: String?
    
    public init(success: Bool, data: T?, message: String?, errorCode: String? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.errorCode = errorCode
    }
}

public struct MarketDataResponse: Codable {
    public let stocks: [StockData]
    public let timestamp: Date
    
    public init(stocks: [StockData], timestamp: Date) {
        self.stocks = stocks
        self.timestamp = timestamp
    }
}

public struct TradingResponse: Codable {
    public let orderId: String
    public let status: String
    public let message: String
    
    public init(orderId: String, status: String, message: String) {
        self.orderId = orderId
        self.status = status
        self.message = message
    }
}