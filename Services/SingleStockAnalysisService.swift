/*
 SingleStockAnalysisService
 // 单只股票分析服务
 // 作者: MiniMax Agent
 */

import Combine
import Foundation

/// 单只股票分析请求
struct SingleStockAnalysisRequest: Codable {
    let symbol: String
    let strategyName: String
    let timeframes: [String]
    let indicators: [String]
    let minConfidence: Double
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case strategyName = "strategy_name"
        case timeframes
        case indicators
        case minConfidence = "min_confidence"
    }
}

/// 技术指标结果
struct TechnicalIndicatorResult: Codable, Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let signal: String
    let confidence: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case name, value, signal, confidence, description
    }
}

/// 价格数据
struct PriceData: Codable {
    let current: Double
    let high: Double
    let low: Double
    let volume: Double
}

/// 时间周期分析结果
struct TimeframeAnalysisResult: Codable, Identifiable {
    let id = UUID()
    let timeframe: String
    let indicators: [TechnicalIndicatorResult]
    let overallSignal: String
    let confidence: Double
    let priceData: PriceData
    
    enum CodingKeys: String, CodingKey {
        case timeframe, indicators, confidence
        case overallSignal = "overall_signal"
        case priceData = "price_data"
    }
}

/// 单只股票分析结果
struct SingleStockAnalysisResult: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let currentPrice: Double
    let timeframeAnalyses: [TimeframeAnalysisResult]
    let overallRecommendation: String
    let overallConfidence: Double
    let summary: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, summary, timestamp
        case currentPrice = "current_price"
        case timeframeAnalyses = "timeframe_analyses"
        case overallRecommendation = "overall_recommendation"
        case overallConfidence = "overall_confidence"
    }
}

/// 单只股票分析服务
@MainActor
class SingleStockAnalysisService: ObservableObject {
    
    // MARK: - 属性
    
    @Published var isLoading: Bool = false
    @Published var lastResult: SingleStockAnalysisResult?
    @Published var lastError: NetworkError?
    
    private let networkManager: NetworkManager
    private let config: NetworkConfig
    
    // MARK: - 初始化
    
    init(networkManager: NetworkManager, config: NetworkConfig) {
        self.networkManager = networkManager
        self.config = config
    }
    
    // MARK: - 单只股票分析
    
    /// 分析单只股票
    func analyzeStock(
        symbol: String,
        // strategyName: String = "多周期综合策略",
        timeframes: [String] = ["1d", "1h", "15m"],
        indicators: [String] = ["RSI", "MACD", "BOLL"],
        minConfidence: Double = 0.5
    ) async throws -> SingleStockAnalysisResult {
        
        isLoading = true
        lastError = nil
        
        defer {
            isLoading = false
        }
        
        let request = SingleStockAnalysisRequest(
            symbol: symbol,
            strategyName: strategyName,
            timeframes: timeframes,
            indicators: indicators,
            minConfidence: minConfidence
        )
        
        let endpoint = "/api/strategy/single-stock/analyze"
        let url = config.baseURL + endpoint
        
        guard let requestURL = URL(string: url) else {
            let error = NetworkError.invalidURL
            lastError = error
            throw error
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60.0
        
        // 编码请求体
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        do {
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
        } catch {
            let networkError = NetworkError.encodingError(error)
            lastError = networkError
            throw networkError
        }
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    let error = NetworkError.httpError(httpResponse.statusCode)
                    lastError = error
                    throw error
                }
            }
            
            // 解码响应
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let result = try decoder.decode(SingleStockAnalysisResult.self, from: data)
            lastResult = result
            
            return result
            
        } catch let error as NetworkError {
            lastError = error
            throw error
        } catch {
            let networkError = NetworkError.decodingError(error)
            lastError = networkError
            throw networkError
        }
    }
    
    // MARK: - 便利方法
    
    /// 快速分析股票（使用默认参数）
    func quickAnalyze(symbol: String) async throws -> SingleStockAnalysisResult {
        return try await analyzeStock(symbol: symbol)
    }
    
    /// 分析股票（仅RSI指标）
    func analyzeWithRSI(symbol: String) async throws -> SingleStockAnalysisResult {
        return try await analyzeStock(
            symbol: symbol,
            timeframes: ["1d"],
            indicators: ["RSI"]
        )
    }
    
    /// 清除上次结果
    func clearLastResult() {
        lastResult = nil
        lastError = nil
    }
}

// MARK: - 网络错误扩展
extension NetworkError {
    static func encodingError(_ error: Error) -> NetworkError {
        return .requestFailed(error)
    }
    
    static func decodingError(_ error: Error) -> NetworkError {
        return .decodingFailed(error)
    }
    
    static func httpError(_ statusCode: Int) -> NetworkError {
        return .httpStatusError(statusCode)
    }
}

