import Combine
import Foundation

// MARK: - 连接状态
public enum ConnectionStatus {
    case disconnected
    case connecting  
    case connected
    case failed
}

// MARK: - 订单请求
public struct OrderRequest {
    public enum OrderType: String, CaseIterable {
        case market = "market"
        case limit = "limit"
    }
    
    public enum Side: String, CaseIterable {
        case buy = "buy"
        case sell = "sell"
    }
    
    public enum TimeInForce: String, CaseIterable {
        case day = "DAY"
        case gtc = "GTC"
        case ioc = "IOC"
        case fok = "FOK"
    }
    
    public let symbol: String
    public let quantity: Int
    public let price: Double
    public let orderType: OrderType
    public let side: Side
    public let timeInForce: TimeInForce?
    
    public init(symbol: String, quantity: Int, orderType: OrderType, side: Side, price: Double = 0.0, timeInForce: TimeInForce? = nil) {
        self.symbol = symbol
        self.quantity = quantity
        self.orderType = orderType
        self.side = side
        self.price = price
        self.timeInForce = timeInForce
    }
}

// MARK: - 订单响应
public struct OrderResponse {
    public let success: Bool
    public let orderId: String?
    public let message: String
    public let errorCode: String?
    
    public init(success: Bool, orderId: String?, message: String, errorCode: String? = nil) {
        self.success = success
        self.orderId = orderId
        self.message = message
        self.errorCode = errorCode
    }
}

// MARK: - 订单状态
public enum OrderStatus: String, CaseIterable {
    case pending = "pending"
    case partiallyFilled = "partially_filled"
    case filled = "filled"
    case cancelled = "cancelled"
    case rejected = "rejected"
}

// MARK: - 订单成交详情
public struct OrderFillDetails {
    public let filledQuantity: Int
    public let avgFillPrice: Double
    public let fillTime: Date
    public let commission: Double
    
    public init(filledQuantity: Int, avgFillPrice: Double, fillTime: Date, commission: Double) {
        self.filledQuantity = filledQuantity
        self.avgFillPrice = avgFillPrice
        self.fillTime = fillTime
        self.commission = commission
    }
}

// MARK: - 账户信息
public struct AccountInfo {
    public let balance: Double
    public let available_balance: Double
    public let positions: [Position]
    
    public init(balance: Double = 0.0, available_balance: Double = 0.0, positions: [Position] = []) {
        self.balance = balance
        self.available_balance = available_balance
        self.positions = positions
    }
}

// MARK: - 持仓信息
public struct Position {
    public let symbol: String
    public let quantity: Int
    public let average_price: Double
    
    public init(symbol: String, quantity: Int, average_price: Double) {
        self.symbol = symbol
        self.quantity = quantity
        self.average_price = average_price
    }
}

// MARK: - 订单（简化版本）
public struct Order {
    public enum Status {
        case pending
        case filled
        case cancelled
    }
    
    public let id: String
    public let symbol: String
    public let quantity: Int
    public let status: Status
    
    public init(id: String, symbol: String, quantity: Int, status: Status) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.status = status
    }
}

// MARK: - 交易错误
public enum TradingError: Error {
    case riskCheckFailed(reason: String)
    case networkError(Error)
    case invalidResponse
    case orderNotFound
    case insufficientBalance
    case connectionError
    case invalidParameters
}

// MARK: - 风险检查结果
public enum RiskCheckResult {
    case approved
    case rejected(reason: String)
}

