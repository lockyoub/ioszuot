/*
 MockClassesFixed
 // 作者: MiniMax Agent
 */

import Combine
import Foundation
import XCTest

  // 移除重复定义，使用主模块的类型

@testable import StockTradingApp

// MARK: - 模拟网络管理器
class MockNetworkManager {
    var mockResponse: Data? = nil
    var mockError: Error? = nil
    var requestCount = 0

    func clear() {
        mockResponse = nil
        mockError = nil
        requestCount = 0
    }
    
    func request(url: URL) async throws -> Data {
        requestCount += 1
        
        if let error = mockError {
            throw error
        }
        
        return mockResponse ?? Data()
    }
}

// MARK: - 模拟风险管理器
class MockRiskManager {
    var checkResult: RiskCheckResult = .approved
    var checkCallCount = 0
    var lastOrderRequest: OrderRequest? = nil

    func check(order: OrderRequest) -> RiskCheckResult {
        checkCallCount += 1
        lastOrderRequest = order
        return checkResult
    }
}

// MARK: - Mock增强型交易服务 (用于测试)
@MainActor
class MockEnhancedTradingService: ObservableObject {
    private var riskManager: MockRiskManager?
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var accountInfo = AccountInfo(balance: 0.0, available_balance: 0.0, positions: [])

    func setRiskManager(_ manager: MockRiskManager) {
        riskManager = manager
    }

    func connectToTradingAPI() async -> Bool {
        // 模拟连接逻辑
        isConnected = true
        connectionStatus = .connected
        return true
    }

    func placeOrder(_ order: OrderRequest) -> Future<Order, Error> {
        return Future { promise in
            DispatchQueue.main.async {
                // 模拟下单逻辑
                if let riskManager = self.riskManager, case .rejected(let reason) = riskManager.check(order: order) {
                    promise(.failure(TradingError.riskCheckFailed(reason: reason)))
                    return
                }
                let newOrder = Order(id: "order_123", symbol: order.symbol, quantity: order.quantity, status: .pending)
                promise(.success(newOrder))
            }
        }
    }

    func cancelOrder(orderId: String) async throws -> Bool {
        // 模拟撤单逻辑
        return true
    }

    func refreshAccountInfo() async {
        // 模拟刷新账户信息
        accountInfo = AccountInfo(
            balance: 100000.0, 
            available_balance: 95000.0, 
            positions: [Position(symbol: "AAPL", quantity: 100, average_price: 150.0)]
        )
    }
}

// MARK: - Mock投资组合计算器
class MockPortfolioCalculator {
    var totalValue: Double = 100000.0
    var totalPnL: Double = 5000.0
    var positions: [Position] = []
    
    func calculateTotalValue() -> Double {
        return totalValue
    }
    
    func calculateTotalPnL() -> Double {
        return totalPnL
    }
    
    func getPositions() -> [Position] {
        return positions
    }
}

// MARK: - Mock策略引擎
class MockStrategyEngine {
    var isRunning: Bool = false
    var activeStrategies: [String] = []
    
    func start() async {
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
    
    func addStrategy(_ strategy: String) {
        activeStrategies.append(strategy)
    }
}

// MARK: - Mock数据同步管理器
class MockDataSyncManager {
    var syncCount: Int = 0
    var lastSyncTime: Date? = nil
    
    func sync() async -> Bool {
        syncCount += 1
        lastSyncTime = Date()
        return true
    }
    
    func getSyncStatus() -> String {
        return "synced"
    }
}

// MARK: - Mock价格提醒服务
class MockPriceAlertService {
    var alerts: [String] = []
    
    func addAlert(symbol: String, price: Double) {
        alerts.append("\(symbol)@\(price)")
    }
    
    func removeAlert(symbol: String) {
        alerts.removeAll { $0.contains(symbol) }
    }
    
    func checkAlerts() -> [String] {
        return alerts
    }
}

// MARK: - Mock市场数据服务
@MainActor
class MockMarketDataService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var stockData: [String: StockData] = [:]
    
    func start() async {
        // 模拟启动逻辑
        isConnected = true
    }
    
    func stop() {
        isConnected = false
    }
    
    func addTestData(symbol: String, price: Double) {
        let data = StockData(
            symbol: symbol,
            price: price,
            change: 0.0,
            changePercent: 0.0,
            volume: 1000,
            timestamp: Date()
        )
        stockData[symbol] = data
    }
}

// MARK: - 股票数据结构
struct StockData {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let timestamp: Date
}