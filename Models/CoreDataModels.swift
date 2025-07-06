/*
 CoreDataModels
 // 作者: MiniMax Agent
 */

import CoreData

// MARK: - 重要说明
// 本项目中的价格和金额相关字段统一使用NSDecimalNumber类型，确保高精度计算
// 所有涉及金融计算的方法都应该使用NSDecimalNumber，避免Double类型的精度问题

import Foundation

/*
 // Core Data数据模型扩展
 */

// MARK: - StockEntity 扩展
extension StockEntity {
    /// 创建新的股票实体
    static func create(in context: NSManagedObjectContext, 
                      symbol: String, 
                      name: String, 
                      exchange: String) -> StockEntity {
        let stock = StockEntity(context: context)
        stock.symbol = symbol
        stock.name = name
        stock.exchange = exchange
        stock.timestamp = Date()
        return stock
    }
    
    /// 更新股票价格数据
    func updatePrice(price: Double, 
                    change: Double, 
                    changePercent: Double,
                    volume: Int64,
                    amount: Double) {
        self.lastPrice = price
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.amount = amount
        self.timestamp = Date()
    }
    
    /// 兼容性方法 - 现在直接调用主方法
    func updatePriceFromDouble(price: Double, 
                              change: Double, 
                              changePercent: Double,
                              volume: Int64,
                              amount: Double) {
        updatePrice(price: price,
                   change: change,
                   changePercent: changePercent,
                   volume: volume,
                   amount: amount)
    }
    
    /// 更新盘口数据
    func updateOrderBook(bidPrices: [Double], 
                        bidVolumes: [Int64],
                        askPrices: [Double], 
                        askVolumes: [Int64]) {
        // 转换为JSON字符串存储
        if let bidPricesData = try? JSONEncoder().encode(bidPrices) {
            self.bidPrices = String(data: bidPricesData, encoding: .utf8)
        }
        if let bidVolumesData = try? JSONEncoder().encode(bidVolumes) {
            self.bidVolumes = String(data: bidVolumesData, encoding: .utf8)
        }
        if let askPricesData = try? JSONEncoder().encode(askPrices) {
            self.askPrices = String(data: askPricesData, encoding: .utf8)
        }
        if let askVolumesData = try? JSONEncoder().encode(askVolumes) {
            self.askVolumes = String(data: askVolumesData, encoding: .utf8)
        }
    }
    
    /// 获取买盘价格数组
    var bidPricesArray: [Double] {
        guard let bidPricesString = bidPrices,
              let data = bidPricesString.data(using: .utf8),
              let prices = try? JSONDecoder().decode([Double].self, from: data) else {
            return []
        }
        return prices
    }
    
    /// 获取买盘数量数组
    var bidVolumesArray: [Int64] {
        guard let bidVolumesString = bidVolumes,
              let data = bidVolumesString.data(using: .utf8),
              let volumes = try? JSONDecoder().decode([Int64].self, from: data) else {
            return []
        }
        return volumes
    }
    
    /// 获取卖盘价格数组
    var askPricesArray: [Double] {
        guard let askPricesString = askPrices,
              let data = askPricesString.data(using: .utf8),
              let prices = try? JSONDecoder().decode([Double].self, from: data) else {
            return []
        }
        return prices
    }
    
    /// 获取卖盘数量数组
    var askVolumesArray: [Int64] {
        guard let askVolumesString = askVolumes,
              let data = askVolumesString.data(using: .utf8),
              let volumes = try? JSONDecoder().decode([Int64].self, from: data) else {
            return []
        }
        return volumes
    }
}

// MARK: - KLineEntity 扩展
extension KLineEntity {
    /// 创建新的K线数据
    static func create(in context: NSManagedObjectContext,
                      symbol: String,
                      timeframe: String,
                      timestamp: Date,
                      open: NSDecimalNumber,
                      high: NSDecimalNumber,
                      low: NSDecimalNumber,
                      close: NSDecimalNumber,
                      volume: Int64,
                      amount: NSDecimalNumber) -> KLineEntity {
        let kline = KLineEntity(context: context)
        kline.symbol = symbol
        kline.timeframe = timeframe
        kline.timestamp = timestamp
        kline.open = open
        kline.high = high
        kline.low = low
        kline.close = close
        kline.volume = volume
        kline.amount = amount
        return kline
    }
    
    /// 兼容性方法 - 接受Double参数
    static func createFromDouble(in context: NSManagedObjectContext,
                                symbol: String,
                                timeframe: String,
                                timestamp: Date,
                                open: Double,
                                high: Double,
                                low: Double,
                                close: Double,
                                volume: Int64,
                                amount: Double) -> KLineEntity {
        return create(in: context,
                     symbol: symbol,
                     timeframe: timeframe,
                     timestamp: timestamp,
                     open: NSDecimalNumber(value: open),
                     high: NSDecimalNumber(value: high),
                     low: NSDecimalNumber(value: low),
                     close: NSDecimalNumber(value: close),
                     volume: volume,
                     amount: NSDecimalNumber(value: amount))
    }
    
    /// 计算涨跌幅
    var changePercent: NSDecimalNumber {
        guard open.compare(NSDecimalNumber.zero) == .orderedDescending else { 
            return NSDecimalNumber.zero 
        }
        let diff = close.subtracting(open)
        let rate = diff.dividing(by: open)
        let hundred = NSDecimalNumber(value: 100)
        return rate.multiplying(by: hundred)
    }
    
    /// 兼容性方法 - 返回Double
    var changePercentDouble: Double {
        return changePercent.doubleValue
    }
    
    /// 判断是否为阳线
    var isRising: Bool {
        return close.compare(open) == .orderedDescending
    }
    
    /// 获取K线颜色
    var color: String {
            return isRising ? "red" : "green"  // 中国股市：红涨绿跌
    }
}

// MARK: - TradeEntity 扩展
extension TradeEntity {
    /// 创建新的交易记录
    static func create(in context: NSManagedObjectContext,
                      symbol: String,
                      direction: String,
                      quantity: Int32,
                      price: NSDecimalNumber,
                      strategy: String) -> TradeEntity {
        let trade = TradeEntity(context: context)
        trade.id = UUID().uuidString
        trade.symbol = symbol
        trade.direction = direction
        trade.quantity = quantity
        trade.price = price
        trade.timestamp = Date()
        trade.strategy = strategy
        // trade.pnl = NSDecimalNumber.zero  // 初始PnL为0，后续更新
        
        // 计算交易金额
        let quantityDecimal = NSDecimalNumber(value: quantity)
        trade.amount = price.multiplying(by: quantityDecimal)
        
        return trade
    }
    
    /// 获取交易金额 - 返回NSDecimalNumber
    var amountDecimal: NSDecimalNumber {
        return amount
    }
    
    /// 获取交易金额 - 返回Double用于兼容
    var amountDouble: Double {
        return amount.doubleValue
    }
    
    /// 判断是否为买入
    var isBuy: Bool {
        return direction == "buy"
    }
    
    /// 获取交易方向显示文本
    var directionText: String {
            return isBuy ? "买入" : "卖出"
    }
    
    /// 格式化时间显示
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: timestamp ?? Date())
    }
}

// MARK: - PositionEntity 扩展
extension PositionEntity {
    /// 创建新的持仓记录
    static func create(in context: NSManagedObjectContext,
                      symbol: String,
                      quantity: Int32,
                      avgCost: NSDecimalNumber) -> PositionEntity {
        let position = PositionEntity(context: context)
        position.symbol = symbol
        position.quantity = quantity
        position.avgCost = avgCost
        position.currentPrice = avgCost
        position.marketValue = avgCost.multiplying(by: NSDecimalNumber(value: quantity))
        position.pnl = NSDecimalNumber.zero
        position.pnlPercent = NSDecimalNumber.zero
        position.lastUpdate = Date()
        return position
    }
    
    /// 更新持仓 - 修复参数类型匹配
    func updatePosition(quantity: Int32, avgCost: NSDecimalNumber, currentPrice: NSDecimalNumber) {
        self.quantity = quantity
        self.avgCost = avgCost
        self.currentPrice = currentPrice
        self.lastUpdate = Date()
        updateDerivedFields()
    }
    
    /// 更新当前价格和相关字段
    func updateCurrentPrice(_ price: NSDecimalNumber) {
        self.currentPrice = price
        self.lastUpdate = Date()
        updateDerivedFields()
    }
    
    /// 更新衍生字段
    private func updateDerivedFields() {
        let currentPriceDecimal = self.currentPrice ?? NSDecimalNumber.zero
        let quantityDecimal = NSDecimalNumber(value: self.quantity)
        
        // 更新市值
        self.marketValue = currentPriceDecimal.multiplying(by: quantityDecimal)
        
        // 更新未实现盈亏
        let priceDiff = currentPriceDecimal.subtracting(self.avgCost)
        self.pnl = priceDiff.multiplying(by: quantityDecimal)
        
        // 更新盈亏率
        if self.avgCost.compare(NSDecimalNumber.zero) == .orderedDescending {
            let rate = priceDiff.dividing(by: self.avgCost)
            let hundred = NSDecimalNumber(value: 100)
            self.pnlPercent = rate.multiplying(by: hundred)
        } else {
            self.pnlPercent = NSDecimalNumber.zero
        }
    }
    
    /// 获取总成本
    var totalCost: NSDecimalNumber {
        let quantityDecimal = NSDecimalNumber(value: abs(quantity))
        return avgCost.multiplying(by: quantityDecimal)
    }
}

// MARK: - StrategyEntity 扩展
extension StrategyEntity {
    /// 创建新的策略配置
    static func create(in context: NSManagedObjectContext,
                      name: String,
                      type: String,
                      timeframe: String) -> StrategyEntity {
        let strategy = StrategyEntity(context: context)
        strategy.id = UUID()
        strategy.name = name
        strategy.type = type
        strategy.timeframe = timeframe
        strategy.isEnabled = true
        // strategy.parameters = "{}"  // 默认空JSON参数
        strategy.createTime = Date()
        strategy.updateTime = Date()
        return strategy
    }
    
    /// 更新策略参数
    func updateParameters(_ params: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: params),
           let jsonString = String(data: data, encoding: .utf8) {
            self.parameters = jsonString
            self.updateTime = Date()
        }
    }
    
    /// 获取策略参数字典
    var parametersDict: [String: Any] {
        guard let parametersString = parameters,
              let data = parametersString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
    
    /// 启用策略
    func enable() {
        isEnabled = true
        updateTime = Date()
    }
    
    /// 禁用策略
    func disable() {
        isEnabled = false
        updateTime = Date()
    }
    
    /// 获取策略状态文本
    var statusText: String {
            return isEnabled ? "启用" : "禁用"
    }
}