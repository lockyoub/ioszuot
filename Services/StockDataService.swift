/*
 StockDataService
 // 作者: MiniMax Agent
 */

import Foundation
import Combine

class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    @Published var stocks: [ServiceStockData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkManager = EnhancedNetworkManager.shared
    private let configManager = ConfigurationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNetworkObservers()
    }
    
    private func setupNetworkObservers() {
        // 设置网络状态观察者
        networkManager.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.refreshStockData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 公共API
    
    /// 获取股票数据
    func fetchStockData(symbols: [String]) async throws -> [ServiceStockData] {
        isLoading = true
        defer { isLoading = false }
        
        // 检查是否启用模拟数据（仅开发环境）
        if configManager.enableMockData {
            return generateMockStockData(symbols: symbols)
        }
        
        // 真实API调用
        let endpoint = "/api/v1/stocks/batch"
        let parameters = ["symbols": symbols.joined(separator: ",")]
        
        do {
            let response = try await networkManager.get(endpoint, parameters: parameters)
            
            if let data = response.data {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let stockResponse = try decoder.decode(StockDataResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.stocks = stockResponse.stocks
                    self.error = nil
                }
                
                return stockResponse.stocks
            } else {
                throw APIError.invalidResponse
            }
            
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            throw error
        }
    }
    
    /// 刷新股票数据
    func refreshStockData() {
        Task {
            let popularSymbols = ["AAPL", "TSLA", "NVDA", "AMZN", "GOOGL", "MSFT", "META", "BRK.B", "LLY", "V"]
            do {
                _ = try await fetchStockData(symbols: popularSymbols)
            } catch {
                // print("刷新股票数据失败: \(error)")
            }
        }
    }
    
    // MARK: - 模拟数据（仅开发环境）
    
    private func generateMockStockData(symbols: [String]) -> [ServiceStockData] {
        return symbols.map { symbol in
            ServiceStockData(
                symbol: symbol,
                name: "\(symbol) Inc.",
                lastPrice: NSDecimalNumber(value: Double.random(in: 50...500)),
                change: NSDecimalNumber(value: Double.random(in: -10...10)),
                changePercent: NSDecimalNumber(value: Double.random(in: -0.1...0.1)),
                volume: Int64.random(in: 1000000...10000000),
                amount: NSDecimalNumber(value: Double.random(in: 100000000...1000000000)),
                timestamp: Date()
            )
        }
    }
}

// MARK: - 数据模型

struct StockDataResponse: Codable {
    let stocks: [ServiceStockData]
    let timestamp: Date
}

struct ServiceStockData: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let lastPrice: NSDecimalNumber
    let change: NSDecimalNumber
    let changePercent: NSDecimalNumber
    let volume: Int64
    let amount: NSDecimalNumber
    let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case symbol, name, lastPrice, change, changePercent, volume, amount, timestamp
    }
}

// MARK: - 错误定义

enum APIError: Error, LocalizedError {
    case invalidResponse
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "API响应无效"
        case .noData:
            return "无数据返回"
        case .decodingError:
            return "数据解析失败"
        }
    }
}
