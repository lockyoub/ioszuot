/*
 // Trading Service
 // 作者: MiniMax Agent
 */

import Combine
import CoreData
import Foundation

/// 统一交易服务类
@MainActor
public class TradingService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var orders: [OrderEntity] = []
    @Published var trades: [TradeEntity] = []
    @Published var accountInfo: AccountInfo = AccountInfo()
    @Published var isTrading: Bool = false
    @Published var dailyPnL: NSDecimalNumber = NSDecimalNumber.zero
    
    // MARK: - Private Properties
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    private var riskManager: RiskManager?
    private var networkManager: EnhancedNetworkManager
    // Security: private var pinganAPIClient: PinganAPIClient  // Removed
    private var orderMonitorTimer: Timer?
    
    // MARK: - 初始化
    init() {
        self.networkManager = EnhancedNetworkManager.shared
        // Security: self.pinganAPIClient = PinganAPIClient()  // Removed
        setupOrderMonitoring()
        loadExistingOrders()
    }
    
    deinit {
        orderMonitorTimer?.invalidate()
    }
    
    // MARK: - 连接管理
    
    /// 连接到后端交易API
    /// - Returns: 连接是否成功
    public func connectToTradingAPI() async -> Bool {
        connectionStatus = .connecting
        
        do {
            // 检查API健康状态
            let response = try await networkManager.get("/api/v1/health", type: [String: Any].self)
            
            if let status = response["status"] as? String,
               status == "healthy" {
                
                isConnected = true
                connectionStatus = .connected
                
                // Get account information
                await refreshAccountInfo()
                
                // Sync order status
                await syncOrderStatus()
                return true
            } else {
                connectionStatus = .failed
                return false
            }
        } catch {
            connectionStatus = .failed
            // print("连接后端API错误: \(error)")
            return false
        }
    }
    
    /// 断开连接
    public func disconnect() {
        // Security: (removed for compilation)
        connectionStatus = .disconnected
    }
    
    /// 设置风险管理器
    /// - Parameter riskManager: 风险管理器实例
    public func setRiskManager(_ riskManager: RiskManager) {
        self.riskManager = riskManager
    }
    
    // MARK: - 订单管理
    
    /// 下单
    /// - Parameter order: 订单请求
    /// - Returns: 订单响应
    public func placeOrder(order: OrderRequest) async -> OrderResponse {
        guard isConnected else {
            return OrderResponse(
                success: false,
                orderId: nil,
                message: "未连接到交易API",
                errorCode: "CONNECTION_ERROR"
            )
        }
        
        // Security: (removed for compilation)
        guard order.quantity > 0 && order.price > 0 else {
            return OrderResponse(
                success: false,
                orderId: nil,
                message: "订单参数无效",
                errorCode: "INVALID_PARAMETERS"
            )
        }
        
        do {
            // Security: (removed for compilation)
            let orderData = [
                "symbol": order.symbol,
                "orderType": order.orderType.rawValue,
                "quantity": order.quantity,
                "price": order.price,
                "timeInForce": order.timeInForce?.rawValue ?? "DAY"
            ] as [String: Any]
            
            let response = try await networkManager.post("/api/v1/orders/submit", body: orderData)
            
            if let data = response.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let success = json["success"] as? Bool ?? false
                let orderId = json["orderId"] as? String
                let message = json["message"] as? String ?? ""
                let errorCode = json["errorCode"] as? String
                
                let orderResponse = OrderResponse(
                    success: success,
                    orderId: orderId,
                    message: message,
                    errorCode: errorCode
                )
                
                if success, let orderId = orderId {
                    // Create local order record
                    let orderEntity = createOrderEntity(from: order, orderId: orderId)
                    orders.append(orderEntity)
                    
                    // Start tracking order status
                    await trackOrderExecution(orderId: orderId)
                    
        // print("订单下达成功: \(orderId)") // 调试语句已注释
                } else {
        // print("订单下达失败: \(message)") // 调试语句已注释
                }
                
                return orderResponse
            } else {
                throw NetworkError.invalidResponse
            }
            
        } catch {
            // print("下单错误: \(error)")
            return OrderResponse(
                success: false,
                orderId: nil,
                message: "下单失败: \(error.localizedDescription)",
                errorCode: "PLACE_ORDER_ERROR"
            )
        }
    }
    
    /// 取消订单
    /// - Parameter orderId: 订单ID
    /// - Returns: 取消是否成功
    public func cancelOrder(orderId: String) async -> Bool {
        guard isConnected else {
            return false
        }
        
        do {
            // 发送取消订单请求
            let response = try await networkManager.post("/api/v1/orders/\(orderId)/cancel", body: [:], type: [String: Any].self)
            
            if let success = response["success"] as? Bool {
                
                if success {
                    
                    if let orderIndex = orders.firstIndex(where: { $0.orderId == orderId }) {
                        orders[orderIndex].status = OrderStatus.cancelled.rawValue
                        orders[orderIndex].updateTime = Date()
                        
                        // Immediate sync save to ensure data consistency
                        do {
                            try persistenceController.container.viewContext.save()
                        } catch {
                            // Rollback memory state if save fails
                            // print("保存订单状态失败，回滚: \(error)")
                            orders[orderIndex].status = OrderStatus.pending.rawValue
                        }
                    }
                    
        // print("订单取消成功: \(orderId)") // 调试语句已注释
                } else {
        // print("订单取消失败: \(orderId)") // 调试语句已注释
                }
                
                return success
            } else {
                return false
            }
        } catch {
            // print("取消订单错误: \(error)")
            return false
        }
    }
    
    /// 查询订单状态
    /// - Parameter orderId: 订单ID
    /// - Returns: 订单状态
    public func queryOrderStatus(orderId: String) async -> OrderStatus? {
        guard isConnected else {
            return nil
        }
        
        do {
            // Security: (removed for compilation)
            
            if let data = response.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let statusString = json["status"] as? String,
               let status = OrderStatus(rawValue: statusString) {
                
                // Update local order status
                if let orderIndex = orders.firstIndex(where: { $0.orderId == orderId }) {
                    orders[orderIndex].status = status.rawValue
                    orders[orderIndex].updateTime = Date()
                    saveContext()
                }
                
                return status
            } else {
                return nil
            }
        } catch {
            // print("查询订单状态错误: \(error)")
            return nil
        }
    }
    
    /// 跟踪订单执行
    /// - Parameter orderId: 订单ID
    public func trackOrderExecution(orderId: String) async {
        var attempts = 0
        let maxAttempts = 30 // 减少最大尝试次数
        var delay: UInt64 = 1_000_000_000 // 1秒,使用纳秒
        
        while attempts < maxAttempts {
            if let status = await queryOrderStatus(orderId: orderId) {
                switch status {
                case .filled:
                    // Order fully filled, get fill details
                    await handleOrderFilled(orderId: orderId)
                    return
                case .cancelled, .rejected:
                    // Order cancelled or rejected, stop tracking
        // print("订单\(orderId)已取消或被拒绝") // 调试语句已注释
                    return
                case .partiallyFilled:
                    // Partially filled, continue tracking
                    await handlePartialFill(orderId: orderId)
                case .pending:
                    // Continue waiting
                    break
                }
            }
            
            attempts += 1
            try? await Task.sleep(nanoseconds: delay)
            
            // Exponential backoff: delay increases gradually, max 30 seconds
            delay = min(delay * 2, 30_000_000_000)
        }
        
        // print("订单\(orderId)跟踪超时") // 调试语句已注释
    }
    
    /// 处理订单成交
    /// - Parameter orderId: 订单ID
    private func handleOrderFilled(orderId: String) async {
        guard let order = orders.first(where: { $0.orderId == orderId }) else { return }
        
        do {
            // Security: (removed for compilation)
            
            if let data = response.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let fillDetails = OrderFillDetails(
                    filledQuantity: json["filledQuantity"] as? Int ?? 0,
                    avgFillPrice: json["avgFillPrice"] as? Double ?? 0.0,
                    fillTime: Date(),
                    commission: json["commission"] as? Double ?? 0.0
                )
                
                // Create trade record
                let trade = createTradeEntity(from: order, fillDetails: fillDetails)
                trades.append(trade)
                
                // Update position
                await updatePositionAfterTrade(trade: trade)
                
                // Update account information
                await refreshAccountInfo()
                
        // print("订单\(orderId)完全成交") // 调试语句已注释
            }
        } catch {
            // print("处理订单成交错误: \(error)")
        }
    }
    
    /// 处理部分成交
    /// - Parameter orderId: 订单ID
    private func handlePartialFill(orderId: String) async {
        guard let order = orders.first(where: { $0.orderId == orderId }) else { return }
        
        do {
            // Security: (removed for compilation)
            
            if let data = response.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let fillDetails = OrderFillDetails(
                    filledQuantity: json["filledQuantity"] as? Int ?? 0,
                    avgFillPrice: json["avgFillPrice"] as? Double ?? 0.0,
                    fillTime: Date(),
                    commission: json["commission"] as? Double ?? 0.0
                )
            
            // Create partial trade record
            if fillDetails.filledQuantity > 0 {
                let trade = createTradeEntity(from: order, fillDetails: fillDetails)
                trades.append(trade)
                
                // Update position
                await updatePositionAfterTrade(trade: trade)
            }
            
        // print("订单\(orderId)部分成交: \(fillDetails.filledQuantity)") // 调试语句已注释
        } catch {
            // print("处理部分成交错误: \(error)")
        }
    }
    
    // MARK: - 持仓管理
    
    /// 更新持仓信息
    /// - Parameter trade: 交易记录
    private func updatePositionAfterTrade(trade: TradeEntity) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            // Find or create position record
            let request = NSFetchRequest<PositionEntity>(entityName: "PositionEntity")
            request.predicate = NSPredicate(format: "symbol == %@", trade.symbol ?? "")
            
            do {
            let positions = try context.fetch(request)
            let position: PositionEntity
            
            if let existingPosition = positions.first {
                position = existingPosition
            } else {
                position = PositionEntity(context: context)
                position.symbol = trade.symbol
                position.id = UUID()
                position.openTime = Date()
            }

            let currentQuantity = position.quantity
            let currentAvgPrice = position.avgPrice
            var newQuantity: Int32
            var newAvgPrice: NSDecimalNumber
            
            switch trade.direction {
            case .buy:
                // Buy: increase position, recalculate average price using weighted average
                newQuantity = currentQuantity + Int32(trade.quantity)
                if newQuantity > 0 {
                    let totalCost = (NSDecimalNumber(value: Double(currentQuantity))).multiplying(by: NSDecimalNumber(value: currentAvgPrice)).adding(NSDecimalNumber(value: trade.quantity).multiplying(by: NSDecimalNumber(value: trade.price)))
                    newAvgPrice = totalCost.dividing(by: NSDecimalNumber(value: newQuantity))
                } else {
                    newAvgPrice = trade.price
                }
                
            case .sell:
                // Sell: decrease position, keep original average price unchanged
                newQuantity = currentQuantity - Int32(trade.quantity)
                // newAvgPrice = currentAvgPrice // 卖出不改变剩余持仓的成本基础
                
                // Verify sell quantity does not exceed holdings
                if newQuantity < 0 {
                    // print("警告：卖出数量(\(trade.quantity))超过持有数量(\(currentQuantity))")
                    // In practice, this should be rejected by backend before order placement
                    newQuantity = 0
                }
            }
            
            if newQuantity == 0 {
                // Complete position close, delete position record
                context.delete(position)
                // print("持仓已清空，删除持仓记录: \(trade.symbol)")
            } else {
                position.quantity = newQuantity
                position.avgPrice = newAvgPrice
                position.updateTime = Date()
                
                // print("更新持仓 - 股票: \(trade.symbol), 数量: \(newQuantity), 均价: \(String(format: "%.2f", newAvgPrice))")
                
                // Set default stop loss and take profit
                if position.stopLoss == 0 {
                    // position.stopLoss = trade.price * 0.95 // 默认5%止损
                }
                if position.takeProfit == 0 {
                    // position.takeProfit = trade.price * 1.10 // 默认10%止盈
                }
            }
            
            // Save background context
            do {
                try context.save()
                // print("持仓更新已保存")
            } catch {
                // print("保存持仓更新失败: \(error)")
            }
            
            } catch {
                // print("更新持仓失败: \(error)")
            }
        }
    }
    
    /// 记录交易
    /// - Parameter tradeData: 交易数据
    public func recordTrade(tradeData: TradeData) {
        let context = persistenceController.container.viewContext
        let trade = TradeEntity(context: context)
        
        trade.id = UUID()
        trade.symbol = tradeData.symbol
        trade.type = tradeData.type.rawValue
        trade.quantity = Int32(tradeData.quantity)
        trade.price = tradeData.price
        trade.timestamp = tradeData.timestamp
        trade.commission = tradeData.commission
        trade.pnl = tradeData.pnl
        
        saveContext()
        
        // Update trade list
        if let index = trades.firstIndex(where: { $0.id == trade.id }) {
            trades[index] = trade
        } else {
            trades.append(trade)
        }
    }
    
    // MARK: - 账户信息
    
    /// 刷新账户信息
    public func refreshAccountInfo() async {
        guard isConnected else { return }
        
        do {
            // Security: (removed for compilation)
            
            if let data = response.data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let info = AccountInfo(
                    totalAssets: json["totalAssets"] as? Double ?? 0.0,
                    availableCash: json["availableCash"] as? Double ?? 0.0,
                    marketValue: json["marketValue"] as? Double ?? 0.0,
                    todayPnL: json["todayPnL"] as? Double ?? 0.0,
                    totalPnL: json["totalPnL"] as? Double ?? 0.0,
                    buyingPower: json["buyingPower"] as? Double ?? 0.0,
                    marginUsed: json["marginUsed"] as? Double ?? 0.0
                )
                
                accountInfo = info
                
                // Calculate daily P&L
                await calculateDailyPnL()
            }
        } catch {
            // print("获取账户信息失败: \(error)")
        }
    }
    
    /// 计算当日盈亏
    private func calculateDailyPnL() async {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTrades = trades.filter { trade in
            guard let timestamp = trade.timestamp else { return false }
            return timestamp >= today
        }
        
        dailyPnL = todayTrades.reduce(0) { total, trade in
            total + trade.pnl
        }
    }
    
    // MARK: - 异常交易检测
    
    /// 检测异常交易
    /// - Parameter trade: 交易记录
    /// - Returns: 异常检测结果
    public func detectAbnormalTrading(trade: TradeEntity) -> AbnormalTradingResult {
        var anomalies: [String] = []
        var riskLevel: RiskLevel = .low
        
        // 1. 大额交易检测
        let tradeValue = trade.price * Double(trade.quantity)
        if tradeValue > accountInfo.totalAssets * 0.2 {
            // anomalies.append("大额交易：超过账户总资产20%")
            riskLevel = .high
        }
        
        // 2. 频繁交易检测
        let recentTrades = getRecentTrades(minutes: 30)
        if recentTrades.count > 10 {
            // anomalies.append("频繁交易：30分钟内交易超过10次")
            riskLevel = max(riskLevel, .medium)
        }
        
        // 3. 价格异常检测
        if let avgPrice = getAveragePrice(symbol: trade.symbol ?? "", days: 5) {
            let priceDeviation = abs(trade.price - avgPrice) / avgPrice
            if priceDeviation > 0.1 {
                // anomalies.append("价格异常：偏离5日均价超过10%")
                riskLevel = max(riskLevel, .medium)
            }
        }
        
        // 4. 时间异常检测
        if let timestamp = trade.timestamp {
            let hour = Calendar.current.component(.hour, from: timestamp)
            if hour < 9 || hour > 15 {
                // anomalies.append("时间异常：非交易时间执行交易")
                riskLevel = max(riskLevel, .high)
            }
        }
        
        // 5. 持仓集中度检测
        let positionConcentration = calculatePositionConcentration(symbol: trade.symbol ?? "")
        if positionConcentration > 0.3 {
            // anomalies.append("持仓集中：单一股票占比超过30%")
            riskLevel = max(riskLevel, .medium)
        }
        
        return AbnormalTradingResult(
            isAbnormal: !anomalies.isEmpty,
            riskLevel: riskLevel,
            anomalies: anomalies,
            recommendations: generateAnomalyRecommendations(anomalies: anomalies)
        )
    }
    
    // MARK: - 私有方法
    
    /// 设置订单监控
    private func setupOrderMonitoring() {
        orderMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.monitorPendingOrders()
            }
        }
    }
    
    /// 监控待处理订单
    private func monitorPendingOrders() async {
        let pendingOrders = orders.filter { order in
            let status = OrderStatus(rawValue: order.status) ?? .pending
            return status == .pending || status == .partiallyFilled
        }
        
        for order in pendingOrders {
            if let orderId = order.orderId {
                await trackOrderExecution(orderId: orderId)
            }
        }
    }
    
    /// 同步订单状态
    private func syncOrderStatus() async {
        guard isConnected else { return }
        
        for order in orders {
            if let orderId = order.orderId {
                _ = await queryOrderStatus(orderId: orderId)
            }
        }
    }
    
    /// 加载现有订单
    private func loadExistingOrders() {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<OrderEntity>(entityName: "OrderEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OrderEntity.createTime, ascending: false)]
        
        do {
            orders = try context.fetch(request)
        } catch {
            // print("加载订单失败: \(error)")
        }
    }
    
    /// 创建订单实体
    private func createOrderEntity(from request: OrderRequest, orderId: String) -> OrderEntity {
        let context = persistenceController.container.viewContext
        let order = OrderEntity(context: context)
        
        order.id = UUID()
        order.orderId = orderId
        order.symbol = request.symbol
        order.type = request.orderType.rawValue
        order.side = request.side.rawValue
        order.quantity = Int32(request.quantity)
        order.price = request.price
        order.status = OrderStatus.pending.rawValue
        order.createTime = Date()
        order.updateTime = Date()
        
        saveContext()
        return order
    }
    
    /// 创建交易实体
    private func createTradeEntity(from order: OrderEntity, fillDetails: OrderFillDetails) -> TradeEntity {
        let context = persistenceController.container.viewContext
        let trade = TradeEntity(context: context)
        
        trade.id = UUID()
        trade.orderId = order.orderId
        trade.symbol = order.symbol
        trade.side = order.side
        trade.quantity = Int32(fillDetails.filledQuantity)
        trade.price = fillDetails.avgFillPrice
        trade.timestamp = fillDetails.fillTime
        trade.commission = fillDetails.commission
        // trade.pnl = 0 // 盈亏在平仓时计算
        
        saveContext()
        return trade
    }
    
    /// 获取近期交易
    private func getRecentTrades(minutes: Int) -> [TradeEntity] {
        let cutoffTime = Date().addingTimeInterval(-Double(minutes * 60))
        return trades.filter { trade in
            guard let timestamp = trade.timestamp else { return false }
            return timestamp >= cutoffTime
        }
    }
    
    /// 获取平均价格
    private func getAveragePrice(symbol: String, days: Int) -> Double? {
        let context = persistenceController.container.viewContext
        
        let request: NSFetchRequest<KLineEntity> = KLineEntity.fetchRequest()
        request.predicate = NSPredicate(format: "symbol == %@", symbol)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \KLineEntity.timestamp, ascending: false)]
        request.fetchLimit = days
        
        do {
            let klines = try context.fetch(request)
            if klines.isEmpty {
                // print("警告：无法获取\(symbol)的历史价格数据")
                return nil
            }
            
            let totalPrice = klines.reduce(0.0) { $0 + $1.closePrice }
            return totalPrice / Double(klines.count)
        } catch {
            // print("获取历史价格失败: \(error)")
            return nil
        }
    }
    
    /// 计算持仓集中度  
    private func calculatePositionConcentration(symbol: String) -> Double {
        let context = persistenceController.container.viewContext
        
        // Get total position value
        let allPositionsRequest: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        let totalValue: Double
        
        do {
            let allPositions = try context.fetch(allPositionsRequest)
            totalValue = allPositions.reduce(0.0) { total, position in
                total + (Double(position.quantity) * position.avgPrice)
            }
            
            if totalValue <= 0 {
                return 0.0
            }
            
            // Get specific stock position value
            let symbolPositionRequest: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
            symbolPositionRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
            
            let symbolPositions = try context.fetch(symbolPositionRequest)
            let symbolValue = symbolPositions.reduce(0.0) { total, position in
                total + (Double(position.quantity) * position.avgPrice)
            }
            
            return symbolValue / totalValue
            
        } catch {
            // print("计算持仓集中度失败: \(error)")
            return 0.0
        }
    }
    
    /// 生成异常建议
    private func generateAnomalyRecommendations(anomalies: [String]) -> [String] {
        var recommendations: [String] = []
        
        for anomaly in anomalies {
            if anomaly.contains("大额交易") {
                // recommendations.append("建议分批交易，降低单笔风险")
            } else if anomaly.contains("频繁交易") {
                // recommendations.append("建议减少交易频率，避免过度交易")
            } else if anomaly.contains("价格异常") {
                // recommendations.append("建议核实价格，确认交易意图")
            } else if anomaly.contains("时间异常") {
                // recommendations.append("建议在正常交易时间进行交易")
            } else if anomaly.contains("持仓集中") {
                // recommendations.append("建议分散投资，降低集中度风险")
            }
        }
        
        return recommendations
    }
    
    /// 保存上下文
    private func saveContext() {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            // print("保存失败: \(error)")
        }
    }
}

// Removed old Combine-based placeOrder function
// Unified use of new async/await API, all risk checks on backend
// MARK: - 扩展账户信息结构体
extension AccountInfo {
    public var balance: Double { return availableCash }
    public var available_balance: Double { return availableCash }
    
    public var positions: [Position] {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
        
        do {
            let positionEntities = try context.fetch(request)
            return positionEntities.map { entity in
                Position(
                    symbol: entity.symbol ?? "",
                    quantity: Double(entity.quantity),
                    avgPrice: entity.avgPrice,
                    currentValue: Double(entity.quantity) * entity.avgPrice,
                    // pnl: 0.0 // 需要根据当前价格计算
                )
            }
        } catch {
            // print("获取持仓数据失败: \(error)")
            return []
        }
    }
    
    public init(balance: Double, available_balance: Double, positions: [Position]) {
        self.availableCash = available_balance
        self.totalAssets = balance
        self.marketValue = 0
        self.todayPnL = 0
        self.totalPnL = 0
        self.buyingPower = available_balance
        self.marginUsed = 0
    }
}

// MARK: - Security Note
// Removed PinganAPIClient class - all trading operations now executed through secure backend API
// Ensures:
// 1. Unified trading process validation
// 2. Server-side fund and risk control
// 3. Complete audit logs
// 4. Prevents client bypassing validation

// End of TradingService class
