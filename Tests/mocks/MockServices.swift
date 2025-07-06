/*
 MockServices
 // 作者: MiniMax Agent
 */

import Combine
import Foundation
import XCTest

@testable import StockTradingApp

// MARK: - 模拟市场数据服务
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

// MARK: - 模拟交易服务
@MainActor
class MockTradingService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    func connectToTradingAPI() async -> Bool {
        // 模拟连接逻辑
        isConnected = true
        connectionStatus = .connected
        return true
    }
    
    func disconnect() {
        isConnected = false
        connectionStatus = .disconnected
    }
}

// MARK: - 模拟数据结构
struct StockData {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let timestamp: Date
}