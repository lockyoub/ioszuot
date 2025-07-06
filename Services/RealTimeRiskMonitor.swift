/*
 RealTimeRiskMonitor
 // 作者: MiniMax Agent
 */

import Combine
import CoreData
import Foundation

/// 实时风险监控器
@MainActor
public class RealTimeRiskMonitor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isMonitoring: Bool = false
    @Published var riskAlerts: [RealTimeRiskAlert] = []
    @Published var accountStatus: AccountStatus = .normal
    @Published var positionRisks: [String: PositionRisk] = [:]
    @Published var emergencyStops: [EmergencyStop] = []
    @Published var monitoringMetrics: MonitoringMetrics = MonitoringMetrics()
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private var riskManager: RiskManager?
    private var tradingService: SecureTradingService?
    private var marketDataService: MarketDataService?
    
    private var monitoringTimer: Timer?
    private var riskThresholds: RiskThresholds
    private var alertHistory: [RealTimeRiskAlert] = []
    
    // MARK: - 初始化
    init(riskThresholds: RiskThresholds = RiskThresholds.defaultThresholds()) {
        self.riskThresholds = riskThresholds
        setupRiskMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 监控控制
    
    /// 开始监控
    /// - Parameters:
    ///   - riskManager: 风险管理器
    ///   - tradingService: 交易服务
    ///   - marketDataService: 市场数据服务
    public func startMonitoring(
        riskManager: RiskManager,
        tradingService: SecureTradingService,
        marketDataService: MarketDataService
    ) {
        self.riskManager = riskManager
        self.tradingService = tradingService
        self.marketDataService = marketDataService
        
        isMonitoring = true
        
        // 启动定时监控
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performRealTimeRiskCheck()
            }
        }
    }
    
    /// 停止监控
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - 实时资金监控
    
    /// 监控账户余额
    public func monitorAccountBalance() async {
        guard let tradingService = tradingService else { return }
        
        await tradingService.refreshAccountInfo()
        let accountInfo = tradingService.accountInfo
        
        // 检查可用资金
        if accountInfo.availableCash < riskThresholds.minCashReserve {
            let alert = RealTimeRiskAlert(
                type: .cashShortage,
                level: .high,
                // message: "可用资金不足",
                currentValue: accountInfo.availableCash,
                threshold: riskThresholds.minCashReserve,
                timestamp: Date(),
                action: .requireAttention
            )
            addRiskAlert(alert)
        }
        
        // 检查保证金使用率
        let marginUsageRatio = accountInfo.totalAssets > 0 ? accountInfo.marginUsed / accountInfo.totalAssets : 0
        if marginUsageRatio > riskThresholds.maxMarginUsage {
            let alert = RealTimeRiskAlert(
                type: .marginExcess,
                level: .critical,
                // message: "保证金使用过高",
                currentValue: marginUsageRatio,
                threshold: riskThresholds.maxMarginUsage,
                timestamp: Date(),
                action: .autoReduce
            )
            addRiskAlert(alert)
            
            // 触发自动减仓
            await triggerAutoPositionReduction()
        }
        
        // 检查账户总盈亏
        let totalPnLRatio = accountInfo.totalAssets > 0 ? accountInfo.totalPnL / accountInfo.totalAssets : 0
        if totalPnLRatio < -riskThresholds.maxTotalLossRatio {
            let alert = RealTimeRiskAlert(
                type: .totalLoss,
                level: .critical,
                // message: "账户总亏损过大",
                currentValue: abs(totalPnLRatio),
                threshold: riskThresholds.maxTotalLossRatio,
                timestamp: Date(),
                action: .emergencyStop
            )
            addRiskAlert(alert)
            
            // 触发紧急止损
            await triggerEmergencyStop()
        }
    }
    
    // MARK: - 仓位风险预警
    
    /// 检查仓位风险预警
    public func checkPositionRiskAlerts() async {
        guard let riskManager = riskManager else { return }
        
        let positions = getAllPositions()
        
        for position in positions {
            let symbol = position.symbol ?? ""
            let positionRisk = calculatePositionRisk(position: position)
            positionRisks[symbol] = positionRisk
            
            // 检查单仓位亏损
            if positionRisk.unrealizedLossRatio > riskThresholds.maxSinglePositionLoss {
                let alert = RealTimeRiskAlert(
                    type: .positionLoss,
                    level: .high,
                    // message: "\(symbol) 单仓位亏损过大",
                    currentValue: positionRisk.unrealizedLossRatio,
                    threshold: riskThresholds.maxSinglePositionLoss,
                    timestamp: Date(),
                    action: .autoStop
                )
                addRiskAlert(alert)
                
                // 自动止损
                await triggerAutoStopLoss(position: position)
            }
            
            // 检查持仓集中度
            if positionRisk.concentrationRatio > riskThresholds.maxPositionConcentration {
                let alert = RealTimeRiskAlert(
                    type: .concentration,
                    level: .medium,
                    // message: "\(symbol) 持仓集中度过高",
                    currentValue: positionRisk.concentrationRatio,
                    threshold: riskThresholds.maxPositionConcentration,
                    timestamp: Date(),
                    action: .requireAttention
                )
                addRiskAlert(alert)
            }
            
            // 检查价格波动异常
            if positionRisk.priceVolatility > riskThresholds.maxPriceVolatility {
                let alert = RealTimeRiskAlert(
                    type: .volatility,
                    level: .medium,
                    // message: "\(symbol) 价格波动异常",
                    currentValue: positionRisk.priceVolatility,
                    threshold: riskThresholds.maxPriceVolatility,
                    timestamp: Date(),
                    action: .requireAttention
                )
                addRiskAlert(alert)
            }
        }
    }
    
    // MARK: - 异常交易检测
    
    /// 检测异常交易
    /// - Returns: 异常交易警报数组
    public func detectAbnormalTrading() async -> [RealTimeRiskAlert] {
        guard let tradingService = tradingService else { return [] }
        
        var alerts: [RealTimeRiskAlert] = []
        
        // 获取最近的交易记录
        let recentTrades = getRecentTrades(minutes: 30)
        
        // 检测频繁交易
        if recentTrades.count > riskThresholds.maxTradesPerHour {
            let alert = RealTimeRiskAlert(
                type: .frequentTrading,
                level: .medium,
                // message: "交易频率过高",
                currentValue: Double(recentTrades.count),
                threshold: Double(riskThresholds.maxTradesPerHour),
                timestamp: Date(),
                action: .requireAttention
            )
            alerts.append(alert)
        }
        
        // 检测大额交易
        let totalTradeValue = recentTrades.reduce(0) { total, trade in
            total + trade.price * Double(trade.quantity)
        }
        
        if totalTradeValue > riskThresholds.maxHourlyTradeValue {
            let alert = RealTimeRiskAlert(
                type: .largeTrading,
                level: .high,
                // message: "单小时交易额过大",
                currentValue: totalTradeValue,
                threshold: riskThresholds.maxHourlyTradeValue,
                timestamp: Date(),
                action: .requireAttention
            )
            alerts.append(alert)
        }
        
        // 检测异常价格交易
        for trade in recentTrades {
            if let avgPrice = await getAveragePrice(symbol: trade.symbol ?? "", days: 5) {
                let priceDeviation = abs(trade.price - avgPrice) / avgPrice
                if priceDeviation > riskThresholds.maxPriceDeviation {
                    let alert = RealTimeRiskAlert(
                        type: .priceAnomaly,
                        level: .medium,
                        // message: "\(trade.symbol ?? "") 交易价格异常",
                        currentValue: priceDeviation,
                        threshold: riskThresholds.maxPriceDeviation,
                        timestamp: Date(),
                        action: .requireAttention
                    )
                    alerts.append(alert)
                }
            }
        }
        
        return alerts
    }
    
    // MARK: - 自动止损触发
    
    /// 触发自动止损
    /// - Parameter position: 持仓信息
    public func triggerAutoStopLoss(position: PositionEntity) async {
        guard let tradingService = tradingService,
              let riskManager = riskManager else { return }
        
        let symbol = position.symbol ?? ""
        
        // 检查是否应该触发止损
        if riskManager.shouldTriggerStopLoss(position: position) {
            let orderRequest = OrderRequest(
                symbol: symbol,
                type: .market,
                side: position.quantity > 0 ? .sell : .buy,
                quantity: abs(Int(position.quantity)),
                price: position.currentPrice,
                timeInForce: .immediateOrCancel,
                stopPrice: nil,
                clientOrderId: "AUTO_STOP_\(UUID().uuidString)"
            )
            
            let response = await tradingService.placeOrder(order: orderRequest)
            
            if response.success {
                let emergencyStop = EmergencyStop(
                    id: UUID(),
                    symbol: symbol,
                    triggerType: .stopLoss,
                    triggerPrice: position.stopLoss,
                    currentPrice: position.currentPrice,
                    quantity: Int(position.quantity),
                    orderId: response.orderId,
                    timestamp: Date(),
                    // reason: "触发自动止损"
                )
                
                emergencyStops.append(emergencyStop)
                
                let alert = RealTimeRiskAlert(
                    type: .autoStopLoss,
                    level: .critical,
                    // message: "\(symbol) 自动止损已执行",
                    currentValue: position.currentPrice,
                    threshold: position.stopLoss,
                    timestamp: Date(),
                    action: .completed
                )
                addRiskAlert(alert)
                
            } else {
            }
        }
    }
    
    /// 触发自动减仓
    private func triggerAutoPositionReduction() async {
        guard let tradingService = tradingService else { return }
        
        let positions = getAllPositions()
        let sortedPositions = positions.sorted { pos1, pos2 in
            let risk1 = calculatePositionRisk(position: pos1)
            let risk2 = calculatePositionRisk(position: pos2)
            return risk1.unrealizedLossRatio > risk2.unrealizedLossRatio
        }
        
        // 减少风险最高的仓位
        for position in sortedPositions.prefix(3) {
            let symbol = position.symbol ?? ""
            let reduceQuantity = Int(Double(position.quantity) * 0.5) // 减仓50%
            
            if reduceQuantity > 0 {
                let orderRequest = OrderRequest(
                    symbol: symbol,
                    type: .market,
                    side: position.quantity > 0 ? .sell : .buy,
                    quantity: reduceQuantity,
                    price: position.currentPrice,
                    timeInForce: .immediateOrCancel,
                    stopPrice: nil,
                    clientOrderId: "AUTO_REDUCE_\(UUID().uuidString)"
                )
                
                let response = await tradingService.placeOrder(order: orderRequest)
                
                if response.success {
                    let alert = RealTimeRiskAlert(
                        type: .autoReduce,
                        level: .high,
                        // message: "\(symbol) 自动减仓已执行",
                        currentValue: Double(reduceQuantity),
                        threshold: Double(position.quantity),
                        timestamp: Date(),
                        action: .completed
                    )
                    addRiskAlert(alert)
                    
                }
            }
        }
    }
    
    /// 触发紧急止损
    private func triggerEmergencyStop() async {
        accountStatus = .emergencyStop
        
        let positions = getAllPositions()
        
        for position in positions {
            await triggerAutoStopLoss(position: position)
        }
        
        let alert = RealTimeRiskAlert(
            type: .emergencyStop,
            level: .critical,
            // message: "触发账户紧急止损",
            currentValue: 0,
            threshold: 0,
            timestamp: Date(),
            action: .completed
        )
        addRiskAlert(alert)
    }
    
    // MARK: - 私有方法
    
    /// 设置风险监控
    private func setupRiskMonitoring() {
        // 初始化监控指标
        monitoringMetrics = MonitoringMetrics()
    }
    
    /// 执行实时风险检查
    private func performRealTimeRiskCheck() async {
        guard isMonitoring else { return }
        
        // 更新监控指标
        updateMonitoringMetrics()
        
        // 监控账户余额
        await monitorAccountBalance()
        
        // 检查仓位风险
        await checkPositionRiskAlerts()
        
        // 检测异常交易
        let abnormalAlerts = await detectAbnormalTrading()
        for alert in abnormalAlerts {
            addRiskAlert(alert)
        }
        
        // 清理过期警报
        cleanupExpiredAlerts()
    }
    
    /// 更新监控指标
    private func updateMonitoringMetrics() {
        monitoringMetrics.lastCheckTime = Date()
        monitoringMetrics.totalChecks += 1
        monitoringMetrics.activeAlerts = riskAlerts.count
        monitoringMetrics.emergencyStops = emergencyStops.count
    }
    
    /// 计算持仓风险
    private func calculatePositionRisk(position: PositionEntity) -> PositionRisk {
        let currentValue = Double(position.quantity) * position.currentPrice
        let costBasis = Double(position.quantity) * position.avgPrice
        let unrealizedPnL = currentValue - costBasis
        let unrealizedLossRatio = costBasis > 0 ? abs(min(unrealizedPnL, 0)) / costBasis : 0
        
        // 计算集中度（简化）
        let totalPortfolioValue = getAllPositions().reduce(0) { total, pos in
            total + Double(pos.quantity) * pos.currentPrice
        }
        let concentrationRatio = totalPortfolioValue > 0 ? abs(currentValue) / totalPortfolioValue : 0
        
        // 计算价格波动率（简化）
        let priceVolatility = calculatePriceVolatility(symbol: position.symbol ?? "")
        
        return PositionRisk(
            symbol: position.symbol ?? "",
            unrealizedPnL: unrealizedPnL,
            unrealizedLossRatio: unrealizedLossRatio,
            concentrationRatio: concentrationRatio,
            priceVolatility: priceVolatility,
            riskLevel: determineRiskLevel(unrealizedLossRatio: unrealizedLossRatio)
        )
    }
    
    /// 确定风险等级
    private func determineRiskLevel(unrealizedLossRatio: Double) -> RiskLevel {
        if unrealizedLossRatio > 0.15 {
            return .critical
        } else if unrealizedLossRatio > 0.10 {
            return .high
        } else if unrealizedLossRatio > 0.05 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// 添加风险警报
    private func addRiskAlert(_ alert: RealTimeRiskAlert) {
        // 避免重复添加相同的警报
        if !riskAlerts.contains(where: { $0.type == alert.type && $0.message == alert.message }) {
            riskAlerts.append(alert)
            alertHistory.append(alert)
            // 可以添加通知或日志记录
        }
    }
    
    /// 清理过期警报
    private func cleanupExpiredAlerts() {
        // 移除超过一定时间的警报，例如1小时
        let oneHourAgo = Date().addingTimeInterval(-3600)
        riskAlerts.removeAll { $0.timestamp < oneHourAgo }
    }
    
    /// 获取所有持仓
    private func getAllPositions() -> [PositionEntity] {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<PositionEntity>(entityName: "PositionEntity")
        do {
            return try context.fetch(request)
        } catch {
            // print("获取持仓失败: \(error)")
            return []
        }
    }
    
    /// 获取最近的交易记录
    private func getRecentTrades(minutes: Int) -> [TradeEntity] {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<TradeEntity>(entityName: "TradeEntity")
        let timeAgo = Date().addingTimeInterval(TimeInterval(-minutes * 60))
        request.predicate = NSPredicate(format: "timestamp >= %@", timeAgo as NSDate)
        do {
            return try context.fetch(request)
        } catch {
            // print("获取最近交易记录失败: \(error)")
            return []
        }
    }
    
    /// 获取平均价格
    private func getAveragePrice(symbol: String, days: Int) async -> Double? {
        // 这是一个模拟实现，实际应从市场数据服务获取历史K线数据计算
        // 为了编译通过，暂时返回一个固定值或随机值
            return 100.0 // 示例值
    }
    
    /// 计算价格波动率
    private func calculatePriceVolatility(symbol: String) -> Double {
        // 这是一个模拟实现，实际应从市场数据服务获取历史价格数据计算
        // 为了编译通过，暂时返回一个固定值或随机值
            return 0.02 // 示例值
    }
}

// MARK: - 数据模型

/// 实时风险警报
struct RealTimeRiskAlert: Identifiable, Equatable {
    let id = UUID()
    let type: RiskAlertType
    let level: RiskLevel
    let message: String
    let currentValue: Double
    let threshold: Double
    let timestamp: Date
    let action: RiskAction
}

/// 风险警报类型
enum RiskAlertType: String, Codable {
    case cashShortage = "资金不足"
    case marginExcess = "保证金过高"
    case totalLoss = "总亏损过大"
    case positionLoss = "单仓位亏损"
    case concentration = "持仓集中度过高"
    case volatility = "价格波动异常"
    case frequentTrading = "交易频率过高"
    case largeTrading = "大额交易"
    case priceAnomaly = "价格异常"
    case autoStopLoss = "自动止损"
    case autoReduce = "自动减仓"
    case emergencyStop = "紧急止损"
}

/// 风险等级
enum RiskLevel: String, Codable, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case critical = "关键"
}

/// 风险行动
enum RiskAction: String, Codable {
    case none = "无"
    case requireAttention = "需要关注"
    case autoReduce = "自动减仓"
    case autoStop = "自动止损"
    case emergencyStop = "紧急止损"
    case completed = "已完成"
}

/// 账户状态
enum AccountStatus: String, Codable {
    case normal = "正常"
    case warning = "警告"
    case critical = "危险"
    case emergencyStop = "紧急止损中"
}

/// 持仓风险
struct PositionRisk {
    let symbol: String
    let unrealizedPnL: Double
    let unrealizedLossRatio: Double
    let concentrationRatio: Double
    let priceVolatility: Double
    let riskLevel: RiskLevel
}

/// 紧急止损记录
struct EmergencyStop: Identifiable {
    let id: UUID
    let symbol: String
    let triggerType: RiskAlertType
    let triggerPrice: Double
    let currentPrice: Double
    let quantity: Int
    let orderId: String?
    let timestamp: Date
    let reason: String
}

/// 监控指标
struct MonitoringMetrics {
    var lastCheckTime: Date = Date()
    var totalChecks: Int = 0
    var activeAlerts: Int = 0
    var emergencyStops: Int = 0
}

/// 风险阈值
struct RiskThresholds {
    var minCashReserve: Double
    var maxMarginUsage: Double
    var maxTotalLossRatio: Double
    var maxSinglePositionLoss: Double
    var maxPositionConcentration: Double
    var maxPriceVolatility: Double
    var maxTradesPerHour: Int
    var maxHourlyTradeValue: Double
    var maxPriceDeviation: Double
    
    static func defaultThresholds() -> RiskThresholds {
        return RiskThresholds(
            minCashReserve: 1000.0,
            maxMarginUsage: 0.8,
            maxTotalLossRatio: 0.1,
            maxSinglePositionLoss: 0.05,
            maxPositionConcentration: 0.3,
            maxPriceVolatility: 0.03,
            maxTradesPerHour: 60,
            maxHourlyTradeValue: 100000.0,
            maxPriceDeviation: 0.05
        )
    }
}


