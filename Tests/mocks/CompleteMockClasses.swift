/*
 CompleteMockClasses
 // 作者: MiniMax Agent
 */

import Combine
import Foundation

 // 完整的Mock类集合
 // 为所有测试提供Mock对象支持

@testable import StockTradingApp

// MARK: - Mock Services

class MockService {
    var isRunning: Bool = false
    
    func start() {
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
}

class MockEnhancedTradingService {
    var riskManager: MockRiskManager?
    
    func setRiskManager(_ riskManager: MockRiskManager) {
        self.riskManager = riskManager
    }
    
    func placeOrder(_ request: OrderRequest) async throws -> String {
        if let riskManager = riskManager, riskManager.shouldRejectOrder {
            throw TradingError.riskCheckFailed
        }
        return "order_123"
    }
    
    func cancelOrder(orderId: String) async throws -> Bool {
        return true
    }
    
    func fetchAccountInfo() async throws -> AccountInfo {
        return AccountInfo(balance: NSDecimalNumber(string: "10000"))
    }
    
    func subscribeToRealtimeData(symbols: [String]) -> AnyPublisher<MarketData, Error> {
        return Just(MarketData(symbol: "AAPL", price: NSDecimalNumber(string: "150.00")))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func simulateMarketDataReceived() {
        // 模拟接收市场数据
    }
}

class MockNetworkManager {
    var shouldFail: Bool = false
    var requestCount: Int = 0
    var mockResponse: Data?
    
    func makeRequest() async throws -> Data {
        requestCount += 1
        
        if shouldFail {
            throw NetworkError.connectionFailed
        }
        
        return mockResponse ?? Data()
    }
}

class MockRiskManager {
    var shouldRejectOrder: Bool = false
    
    func validateRiskParameters(_ data: RiskControlData) -> Bool {
        return !shouldRejectOrder
    }
}

class MockDataManager {
    var isUpdating: Bool = false
    
    func startRealTimeUpdates() {
        isUpdating = true
    }
    
    func stopRealTimeUpdates() {
        isUpdating = false
    }
}

class MockErrorManager {
    var canRecover: Bool = true
    
    func simulateError() {
        // 模拟错误
    }
}

class MockUserSession {
    func performCompleteJourney() -> Bool {
        return true
    }
}

class MockEngine {
    var isRunning: Bool = false
    private var strategies: [MockStrategy] = []
    
    func start() {
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
    
    func addStrategy(_ strategy: MockStrategy) {
        strategies.append(strategy)
    }
    
    func removeStrategy(_ strategy: MockStrategy) {
        strategies.removeAll { $0.id == strategy.id }
    }
    
    func hasStrategy(_ strategy: MockStrategy) -> Bool {
        return strategies.contains { $0.id == strategy.id }
    }
}

class MockStrategy {
    let id: String = UUID().uuidString
}

// MARK: - Mock Data Models

struct MarketData {
    let symbol: String
    let price: NSDecimalNumber
}

struct AccountInfo {
    let balance: NSDecimalNumber
}

struct RiskControlData {
    let maxPositionSize: NSDecimalNumber
    let maxDailyLoss: NSDecimalNumber
    let maxLeverage: NSDecimalNumber
}

// MARK: - Mock Service Extensions

extension MockService {
    var unsubscribedSymbols: [String] {
            return ["AAPL", "GOOGL"] // 模拟取消订阅的股票
    }
    
    func subscribeToSymbols(_ symbols: [String]) {
        // 模拟订阅
    }
    
    func unsubscribeFromSymbols(_ symbols: [String]) {
        // 模拟取消订阅
    }
}

// MARK: - Chart Data Support

extension ChartDataManager {
    var hasData: Bool {
            return true // 模拟有数据
    }
    
    func updateData(_ data: [MarketDataPoint]) {
        // 模拟更新数据
    }
}

extension ChartUtilities {
    static func formatPrice(_ price: NSDecimalNumber) -> String {
        return price.stringValue
    }
    
    static func formatPercentage(_ percentage: NSDecimalNumber) -> String {
        return "\(percentage.stringValue)%"
    }
}

// MARK: - Error Types

enum TradingError: Error {
    case riskCheckFailed
    case invalidOrder
    case networkError
    case invalidResponse
}

enum NetworkError: Error {
    case connectionFailed
    case timeout
    case invalidURL
}

// MARK: - Additional Mock Classes

class MockPersistenceController {
    static let shared = MockPersistenceController()
    
    var container: MockNSPersistentContainer {
        return MockNSPersistentContainer()
    }
}

class MockNSPersistentContainer {
    var viewContext: MockNSManagedObjectContext {
        return MockNSManagedObjectContext()
    }
}

class MockNSManagedObjectContext {
    func save() throws {
        // 模拟保存
    }
    
    func fetch<T>(_ request: Any) throws -> [T] {
        return []
    }
}

// MARK: - View Model Support

extension NotificationManager {
    static let shared = NotificationManager()
}

class NotificationManager {
    // 模拟通知管理器
}

// MARK: - NSDecimalNumber Extensions for Testing

extension NSDecimalNumber {
    static func fromString(_ string: String) -> NSDecimalNumber {
        return NSDecimalNumber(string: string)
    }
}

// MARK: - Mock Entity Extensions

extension StockEntity {
    convenience init(context: MockNSManagedObjectContext) {
        self.init()
    }
}

extension UnifiedStockEntity {
    convenience init(context: MockNSManagedObjectContext) {
        self.init()
    }
}

extension UnifiedMarketDepthEntity {
    convenience init(context: MockNSManagedObjectContext) {
        self.init()
    }
}