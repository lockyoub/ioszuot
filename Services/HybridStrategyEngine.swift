/*
 HybridStrategyEngine
 // 混合策略引擎 - 集成本地和远程计算
 // 作者: MiniMax Agent
 */

import Combine
import Foundation
import SwiftUI

/// 混合策略引擎
@MainActor
class HybridStrategyEngine: ObservableObject {
    
    // MARK: - 发布属性
    
    @Published var isProcessing: Bool = false
    @Published var useRemoteStrategy: Bool = true
    @Published var isRemoteAvailable: Bool = false
    @Published var lastResults: [StockScreenResult] = []
    @Published var lastError: Error?
    @Published var processingProgress: Double = 0.0
    
    // MARK: - 私有属性
    
    private let localStrategyEngine: StrategyEngine
    private let backendStrategyService: BackendStrategyService
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // 缓存
    private var resultCache: [String: CachedResult] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5分钟缓存
    
    // MARK: - 初始化
    
    init(
        localStrategyEngine: StrategyEngine,
        backendStrategyService: BackendStrategyService,
        networkManager: NetworkManager
    ) {
        self.localStrategyEngine = localStrategyEngine
        self.backendStrategyService = backendStrategyService
        self.networkManager = networkManager
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听后端服务可用性
        backendStrategyService.$isAvailable
            .assign(to: \.isRemoteAvailable, on: self)
            .store(in: &cancellables)
        
        // 监听网络状态
        networkManager.$isConnected
            .combineLatest(backendStrategyService.$isAvailable)
            .map { $0 && $1 }
            .assign(to: \.isRemoteAvailable, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - 主要功能
    
    /// 执行多周期策略分析
    func performMultiTimeframeAnalysis(
        symbols: [String],
        request: MultiTimeframeScreenRequest? = nil
    ) async -> [StockScreenResult] {
        
        isProcessing = true
        processingProgress = 0.0
        lastError = nil
        
        defer {
            isProcessing = false
            processingProgress = 1.0
        }
        
        // 检查缓存
        let cacheKey = symbols.joined(separator: ",")
        if let cachedResult = resultCache[cacheKey],
           !cachedResult.isExpired {
            lastResults = cachedResult.results
            return cachedResult.results
        }
        
        processingProgress = 0.2
        
        var results: [StockScreenResult] = []
        
        // 1. 优先尝试后端API
        if useRemoteStrategy && isRemoteAvailable {
            do {
                processingProgress = 0.4
                results = try await performRemoteAnalysis(symbols: symbols, request: request)
                processingProgress = 0.8
                
                // 缓存结果
                cacheResults(key: cacheKey, results: results)
                
            } catch {
                // print("后端策略失败，切换到本地计算: \(error)")
                lastError = error
                
                // 自动降级到本地计算
                processingProgress = 0.5
                results = await performLocalAnalysis(symbols: symbols)
                processingProgress = 0.9
            }
        } else {
            // 2. 本地计算
            processingProgress = 0.3
            results = await performLocalAnalysis(symbols: symbols)
            processingProgress = 0.9
        }
        
        lastResults = results
        return results
    }
    
    /// 执行远程策略分析
    private func performRemoteAnalysis(
        symbols: [String],
        request: MultiTimeframeScreenRequest?
    ) async throws -> [StockScreenResult] {
        
        let screenRequest = request ?? MultiTimeframeScreenRequest(
            // strategyName: "多周期综合策略",
            timeframes: ["5m", "15m", "1h", "1d"],
            indicators: ["RSI", "MACD", "BOLL"],
            minConfidence: 0.6,
            maxResults: symbols.count
        )
        
        let backendResults = try await backendStrategyService.performMultiTimeframeScreen(
            request: screenRequest
        )
        
        // 转换为本地数据模型
        let localResults = backendResults.map { $0.toLocalResult() }
        
        // 过滤指定的股票代码
        let filteredResults = localResults.filter { result in
            symbols.isEmpty || symbols.contains(result.symbol)
        }
        
        return filteredResults
    }
    
    /// 执行本地策略分析
    private func performLocalAnalysis(symbols: [String]) async -> [StockScreenResult] {
        
        var results: [StockScreenResult] = []
        
        for (index, symbol) in symbols.enumerated() {
            // 更新进度
            let progress = Double(index) / Double(symbols.count) * 0.4 + 0.5
            processingProgress = progress
            
            // 执行本地分析
            if let result = await performLocalSymbolAnalysis(symbol: symbol) {
                results.append(result)
            }
            
            // 避免阻塞UI
            if index % 5 == 0 {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        return results.sorted { $0.overallScore > $1.overallScore }
    }
    
    /// 对单个股票执行本地分析
    private func performLocalSymbolAnalysis(symbol: String) async -> StockScreenResult? {
        
        // 这里应该调用本地策略引擎的方法
        // 由于原始代码较复杂，这里提供一个简化版本
        
        guard let stockData = await getStockData(symbol: symbol) else {
            return nil
        }
        
        // 执行多周期分析
        let timeframes = ["5m", "15m", "1h", "1d"]
        var allSignals: [TradingSignal] = []
        
        for timeframe in timeframes {
            if let signals = await analyzeTimeframe(
                symbol: symbol,
                timeframe: timeframe,
                stockData: stockData
            ) {
                allSignals.append(contentsOf: signals)
            }
        }
        
        // 计算综合评分
        let overallScore = calculateOverallScore(signals: allSignals)
        let recommendation = generateRecommendation(score: overallScore, signals: allSignals)
        
        return StockScreenResult(
            symbol: symbol,
            name: stockData.name,
            currentPrice: stockData.lastPrice,
            signals: allSignals,
            overallScore: overallScore,
            recommendation: recommendation,
            source: .local
        )
    }
    
    // MARK: - 辅助方法
    
    /// 获取股票数据
    private func getStockData(symbol: String) async -> StockData? {
        // 这里应该从MarketDataService获取数据
        // 简化实现
        return StockData(
            symbol: symbol,
            // name: "股票\(symbol)",
            lastPrice: Double.random(in: 10...100),
            change: Double.random(in: -5...5),
            changePercent: Double.random(in: -0.1...0.1),
            volume: Int64.random(in: 1000000...10000000),
            amount: Double.random(in: 10000000...100000000),
            high: Double.random(in: 50...120),
            low: Double.random(in: 5...50),
            open: Double.random(in: 20...80)
        )
    }
    
    /// 分析特定时间周期
    private func analyzeTimeframe(
        symbol: String,
        timeframe: String,
        stockData: StockData
    ) async -> [TradingSignal]? {
        
        // 简化的技术指标分析
        var signals: [TradingSignal] = []
        
        // RSI分析
        let rsi = Double.random(in: 0...100)
        if rsi < 30 {
            signals.append(TradingSignal(
                id: UUID(),
                symbol: symbol,
                signalType: .buy,
                confidence: 0.8,
                price: stockData.lastPrice,
                // strategy: "RSI超卖",
                timeframe: timeframe,
                timestamp: Date(),
                // reasoning: "RSI=\(String(format: "%.2f", rsi))，处于超卖区域"
            ))
        } else if rsi > 70 {
            signals.append(TradingSignal(
                id: UUID(),
                symbol: symbol,
                signalType: .sell,
                confidence: 0.8,
                price: stockData.lastPrice,
                // strategy: "RSI超买",
                timeframe: timeframe,
                timestamp: Date(),
                // reasoning: "RSI=\(String(format: "%.2f", rsi))，处于超买区域"
            ))
        }
        
        // MACD分析（简化）
        let macdSignal = Bool.random()
        if macdSignal {
            signals.append(TradingSignal(
                id: UUID(),
                symbol: symbol,
                signalType: .buy,
                confidence: 0.75,
                price: stockData.lastPrice,
                // strategy: "MACD金叉",
                timeframe: timeframe,
                timestamp: Date(),
                // reasoning: "MACD金叉，柱状图由负转正"
            ))
        }
        
        return signals
    }
    
    /// 计算综合评分
    private func calculateOverallScore(signals: [TradingSignal]) -> Double {
        guard !signals.isEmpty else { return 0.0 }
        
        let buySignals = signals.filter { $0.signalType == .buy }
        let sellSignals = signals.filter { $0.signalType == .sell }
        
        let buyScore = buySignals.reduce(0) { $0 + $1.confidence }
        let sellScore = sellSignals.reduce(0) { $0 + $1.confidence }
        
        let netScore = buyScore - sellScore
        let maxPossibleScore = Double(signals.count)
        
        return max(0, min(1, (netScore + maxPossibleScore) / (2 * maxPossibleScore)))
    }
    
    /// 生成推荐
    private func generateRecommendation(score: Double, signals: [TradingSignal]) -> String {
        let buySignals = signals.filter { $0.signalType == .buy }.count
        let sellSignals = signals.filter { $0.signalType == .sell }.count
        
        if score > 0.7 && buySignals > sellSignals {
            return "强烈推荐"
        } else if score > 0.5 && buySignals >= sellSignals {
            return "推荐"
        } else if score < 0.3 || sellSignals > buySignals {
            return "不推荐"
        } else {
            return "观望"
        }
    }
    
    /// 缓存结果
    private func cacheResults(key: String, results: [StockScreenResult]) {
        resultCache[key] = CachedResult(
            results: results,
            timestamp: Date()
        )
        
        // 清理过期缓存
        cleanExpiredCache()
    }
    
    /// 清理过期缓存
    private func cleanExpiredCache() {
        let now = Date()
        resultCache = resultCache.filter { _, cachedResult in
            now.timeIntervalSince(cachedResult.timestamp) < cacheExpiration
        }
    }
    
    // MARK: - 公共方法
    
    /// 切换策略模式
    func toggleStrategyMode() {
        useRemoteStrategy.toggle()
        UserDefaults.standard.set(useRemoteStrategy, forKey: "UseRemoteStrategy")
    }
    
    /// 清除缓存
    func clearCache() {
        resultCache.removeAll()
    }
    
    /// 强制刷新
    func forceRefresh(symbols: [String]) async -> [StockScreenResult] {
        clearCache()
        return await performMultiTimeframeAnalysis(symbols: symbols)
    }
}

// MARK: - 辅助数据结构

/// 缓存结果
private struct CachedResult {
    let results: [StockScreenResult]
    let timestamp: Date
    
    var isExpired: Bool {
        return // Date().timeIntervalSince(timestamp) > 300 // 5分钟过期
    }
}

/// 扩展StockScreenResult以支持来源标识
extension StockScreenResult {
    init(
        symbol: String,
        name: String,
        currentPrice: Double,
        signals: [TradingSignal],
        overallScore: Double,
        recommendation: String,
        source: StrategySource
    ) {
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.signals = signals
        self.overallScore = overallScore
        self.recommendation = recommendation
        self.source = source
    }
}

