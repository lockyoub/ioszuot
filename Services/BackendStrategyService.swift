/*
 BackendStrategyService
 // 后端策略服务集成
 // 作者: MiniMax Agent
 */

import Combine
import Foundation

/// 后端策略服务
@MainActor
class BackendStrategyService: ObservableObject {
    
    // MARK: - 属性
    
    @Published var isAvailable: Bool = false
    @Published var lastError: NetworkError?
    
    private let networkManager: NetworkManager
    private let config: NetworkConfig
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    init(networkManager: NetworkManager, config: NetworkConfig) {
        self.networkManager = networkManager
        self.config = config
        setupHealthCheck()
    }
    
    // MARK: - 多周期策略选股
    
    /// 调用后端多周期策略选股API
    func performMultiTimeframeScreen(
        request: MultiTimeframeScreenRequest
    ) async throws -> [BackendStockScreenResult] {
        
        let endpoint = "/api/strategy/multi-timeframe/screen"
        let url = config.baseURL + endpoint
        
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 编码请求体
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // 解码响应
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let results = try decoder.decode([BackendStockScreenResult].self, from: data)
        
        return results
    }
    
    /// 获取支持的时间周期
    func getSupportedTimeframes() async throws -> [String] {
        let endpoint = "/api/strategy/timeframes"
        let url = config.baseURL + endpoint
        
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: requestURL)
        let timeframes = try JSONDecoder().decode([String].self, from: data)
        
        return timeframes
    }
    
    /// 获取支持的技术指标
    func getSupportedIndicators() async throws -> [String] {
        let endpoint = "/api/strategy/indicators"
        let url = config.baseURL + endpoint
        
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: requestURL)
        let indicators = try JSONDecoder().decode([String].self, from: data)
        
        return indicators
    }
    
    // MARK: - 健康检查
    
    private func setupHealthCheck() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkBackendHealth()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBackendHealth() async {
        do {
            let endpoint = "/health"
            let url = config.baseURL + endpoint
            
            guard let requestURL = URL(string: url) else {
                isAvailable = false
                return
            }
            
            let (_, response) = try await URLSession.shared.data(from: requestURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                isAvailable = httpResponse.statusCode == 200
            } else {
                isAvailable = false
            }
            
            lastError = nil
            
        } catch {
            isAvailable = false
            lastError = error as? NetworkError ?? .unknown
        }
    }
}

// MARK: - 数据模型

/// 多周期策略选股请求
struct MultiTimeframeScreenRequest: Codable {
    let strategy_name: String
    let timeframes: [String]
    let indicators: [String]
    let min_confidence: Double
    let max_results: Int
    let market_filter: String?
    
    init(
        // strategyName: String = "多周期综合策略",
        timeframes: [String] = ["5m", "15m", "1h", "1d"],
        indicators: [String] = ["RSI", "MACD", "BOLL"],
        minConfidence: Double = 0.6,
        maxResults: Int = 20,
        marketFilter: String? = nil
    ) {
        self.strategy_name = strategyName
        self.timeframes = timeframes
        self.indicators = indicators
        self.min_confidence = minConfidence
        self.max_results = maxResults
        self.market_filter = marketFilter
    }
}

/// 后端股票筛选结果
struct BackendStockScreenResult: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let current_price: Double
    let signals: [BackendTradingSignal]
    let overall_score: Double
    let recommendation: String
    
    private enum CodingKeys: String, CodingKey {
        case symbol, name, current_price, signals, overall_score, recommendation
    }
}

/// 后端交易信号
struct BackendTradingSignal: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let signal_type: String
    let confidence: Double
    let price: Double
    let timeframe: String
    let strategy_name: String
    let timestamp: String
    let reasoning: String
    
    private enum CodingKeys: String, CodingKey {
        case symbol, signal_type, confidence, price, timeframe, strategy_name, timestamp, reasoning
    }
    
    /// 转换为本地信号类型
    var localSignalType: SignalType {
        switch signal_type.uppercased() {
        case "BUY":
            return .buy
        case "SELL":
            return .sell
        default:
            return .hold
        }
    }
    
    /// 转换为本地时间戳
    var localTimestamp: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp) ?? Date()
    }
}

// MARK: - 扩展方法

extension BackendStockScreenResult {
    /// 转换为本地股票筛选结果
    func toLocalResult() -> StockScreenResult {
        let localSignals = signals.map { backendSignal in
            TradingSignal(
                id: UUID(),
                symbol: backendSignal.symbol,
                signalType: backendSignal.localSignalType,
                confidence: backendSignal.confidence,
                price: backendSignal.price,
                strategy: backendSignal.strategy_name,
                timeframe: backendSignal.timeframe,
                timestamp: backendSignal.localTimestamp,
                reasoning: backendSignal.reasoning
            )
        }
        
        return StockScreenResult(
            symbol: symbol,
            name: name,
            currentPrice: current_price,
            signals: localSignals,
            overallScore: overall_score,
            recommendation: recommendation,
            source: .remote
        )
    }
}

/// 策略结果来源
enum StrategySource: String, CaseIterable {
    case remote = "后端计算"
    case local = "本地计算"
    case hybrid = "混合计算"
    
    var icon: String {
        switch self {
        case .remote:
            return "cloud.fill"
        case .local:
            return "iphone"
        case .hybrid:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .remote:
            return .blue
        case .local:
            return .green
        case .hybrid:
            return .orange
        }
    }
}

/// 扩展本地股票筛选结果
extension StockScreenResult {
    var source: StrategySource {
        get { _source ?? .local }
        set { _source = newValue }
    }
    
    private var _source: StrategySource?
}

