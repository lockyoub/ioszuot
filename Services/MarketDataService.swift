/*
 // 市场数据服务
 // 作者: MiniMax Agent
 */

import Combine
import CoreData
import Foundation
// ConfigurationManager将在Utils/ConfigurationManager.swift中定义

/// 市场数据服务类
@MainActor
class MarketDataService: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var stockData: [String: MarketStockData] = [:]
    @Published var klineData: [String: [KLineData]] = [:]
    @Published var orderBookData: [String: OrderBookData] = [:]
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let persistenceController = PersistenceController.shared
    private var dataUpdateTimer: Timer?
    
    // 配置参数
    
    private lazy var serverURL: String = {
        return ConfigurationManager.shared.marketDataWebSocketURL
    }()  // 使用WSS加密连接
    private let updateInterval: TimeInterval = 1.0  // 1秒更新一次
    
    // MARK: - 初始化
    init() {
        setupDataUpdateTimer()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - 公共方法
    
    /// 启动市场数据服务
    func start() async {
        await connectToWebSocket()
        await loadHistoricalData()
    }
    
    /// 停止市场数据服务
    func stop() {
        webSocketTask?.cancel()
        dataUpdateTimer?.invalidate()
        isConnected = false
    }
    
    /// 订阅股票数据
    func subscribe(symbols: [String]) async {
        let subscribeMessage = SubscribeMessage(action: "subscribe", symbols: symbols)
        await sendMessage(subscribeMessage)
    }
    
    /// 取消订阅股票数据
    func unsubscribe(symbols: [String]) async {
        let unsubscribeMessage = SubscribeMessage(action: "unsubscribe", symbols: symbols)
        await sendMessage(unsubscribeMessage)
    }
    
    /// 获取股票当前价格
    func getCurrentPrice(for symbol: String) -> Double? {
        return stockData[symbol]?.lastPrice
    }
    
    /// 获取股票K线数据
    func getKLineData(for symbol: String, timeframe: String) -> [KLineData] {
        let key = "\(symbol)_\(timeframe)"
        return klineData[key] ?? []
    }
    
    // MARK: - 私有方法
    
    /// 连接WebSocket
    private func connectToWebSocket() async {
        guard let url = URL(string: serverURL) else {
            return
        }
        
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        
        webSocketTask?.resume()
        isConnected = true
        
        // 开始监听消息
        await listenForMessages()
    }
    
    /// 监听WebSocket消息
    private func listenForMessages() async {
        guard let webSocketTask = webSocketTask, isConnected else { 
            // print("WebSocket任务不存在或连接已断开，停止监听")
            return 
        }
        
        var retryCount = 0
        let maxRetries = 5
        
        do {
            let message = try await webSocketTask.receive()
            await processMessage(message)
            // retryCount = 0 // 重置重试计数
            
            // 添加延迟并检查连接状态后继续监听
            if isConnected {
// try? await Task.sleep(nanoseconds: 100_000_000) // 100ms延迟
                await listenForMessages()
            }
        } catch {
            // print("WebSocket接收消息失败: \(error)")
            retryCount += 1
            
            if retryCount >= maxRetries {
                // print("达到最大重试次数，停止监听")
                isConnected = false
            } else {
                // 指数退避重试
                let delay = UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                if isConnected {
                    await listenForMessages()
                }
            }
        }
    }
    
    /// 处理接收到的消息
    private func processMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            await processStringMessage(text)
        case .data(let data):
            await processDataMessage(data)
        @unknown default:
            break
        }
    }
    
    /// 处理字符串消息
    private func processStringMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            if let marketData = try? JSONDecoder().decode(MarketDataMessage.self, from: data) {
                await updateStockData(marketData)
            } else if let klineData = try? JSONDecoder().decode(KLineDataMessage.self, from: data) {
                await updateKLineData(klineData)
            } else if let orderBookData = try? JSONDecoder().decode(OrderBookDataMessage.self, from: data) {
                await updateOrderBookData(orderBookData)
            }
        } catch {
            // print("解析消息失败: \(error)")
        }
    }
    
    /// 处理数据消息
    private func processDataMessage(_ data: Data) async {
        // 处理二进制数据（如果需要）
    }
    
    /// 发送消息到WebSocket
    private func sendMessage<T: Codable>(_ message: T) async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8) ?? ""
            let message = URLSessionWebSocketTask.Message.string(string)
            try await webSocketTask.send(message)
        } catch {
            // print("发送消息失败: \(error)")
        }
    }
    
    /// 更新股票数据
    private func updateStockData(_ data: MarketDataMessage) async {
        let stockData = MarketStockData(
            symbol: data.symbol,
            name: data.name ?? "",
            lastPrice: data.price,
            change: data.change,
            changePercent: data.changePercent,
            volume: data.volume,
            amount: data.amount,
            bidPrices: data.bidPrices ?? [],
            bidVolumes: data.bidVolumes ?? [],
            askPrices: data.askPrices ?? [],
            askVolumes: data.askVolumes ?? [],
            timestamp: Date()
        )
        
        self.stockData[data.symbol] = stockData
        
        // 保存到Core Data
        await saveStockDataToCoreData(stockData)
    }
    
    /// 更新K线数据
    private func updateKLineData(_ data: KLineDataMessage) async {
        let klineData = KLineData(
            symbol: data.symbol,
            timeframe: data.timeframe,
            timestamp: Date(timeIntervalSince1970: data.timestamp),
            open: data.open,
            high: data.high,
            low: data.low,
            close: data.close,
            volume: data.volume,
            amount: data.amount
        )
        
        let key = "\(data.symbol)_\(data.timeframe)"
        if self.klineData[key] == nil {
            self.klineData[key] = []
        }
        self.klineData[key]?.append(klineData)
        
        // 保存到Core Data
        await saveKLineDataToCoreData(klineData)
    }
    
    /// 更新订单簿数据
    private func updateOrderBookData(_ data: OrderBookDataMessage) async {
        let orderBookData = OrderBookData(
            symbol: data.symbol,
            bidPrices: data.bidPrices,
            bidVolumes: data.bidVolumes,
            askPrices: data.askPrices,
            askVolumes: data.askVolumes,
            timestamp: Date()
        )
        
        self.orderBookData[data.symbol] = orderBookData
    }
    
    /// 设置数据更新定时器
    private func setupDataUpdateTimer() {
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            Task {
                await self.requestDataUpdate()
            }
        }
    }
    
    /// 请求数据更新
    private func requestDataUpdate() async {
        // 向服务器请求最新数据
        let updateRequest = DataUpdateRequest(action: "update", timestamp: Date().timeIntervalSince1970)
        await sendMessage(updateRequest)
    }
    
    /// 加载历史数据
    private func loadHistoricalData() async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            // 加载股票数据
            let stockRequest = NSFetchRequest<StockEntity>(entityName: "StockEntity")
            stockRequest.sortDescriptors = [NSSortDescriptor(keyPath: \StockEntity.timestamp, ascending: false)]
            
            do {
                let stocks = try context.fetch(stockRequest)
                var tempStockData: [String: MarketStockData] = [:]
                
                for stock in stocks {
                    let data = MarketStockData(
                        symbol: stock.symbol ?? "",
                        name: stock.name ?? "",
                        lastPrice: stock.lastPrice,
                        change: stock.change,
                        changePercent: stock.changePercent,
                        volume: stock.volume,
                        amount: stock.amount,
                        bidPrices: stock.bidPricesArray.map { Double($0) },
                        bidVolumes: stock.bidVolumesArray,
                        askPrices: stock.askPricesArray.map { Double($0) },
                        askVolumes: stock.askVolumesArray,
                        timestamp: stock.timestamp ?? Date()
                    )
                    tempStockData[stock.symbol ?? ""] = data
                }
                
                // 切换到主线程更新UI数据
                await MainActor.run {
                    self.stockData = tempStockData
                }
                
            } catch {
                // print("加载股票数据失败: \(error)")
            }
        }
    }
    
    /// 保存股票数据到Core Data
    private func saveStockDataToCoreData(_ data: MarketStockData) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            // 查找已存在的股票记录
            let request = NSFetchRequest<StockEntity>(entityName: "StockEntity")
            request.predicate = NSPredicate(format: "symbol == %@", data.symbol)
            
            do {
                let existingStocks = try context.fetch(request)
                let stock = existingStocks.first ?? StockEntity(context: context)
                
                stock.symbol = data.symbol
                stock.name = data.name
                stock.lastPrice = data.lastPrice
                stock.change = data.change
                stock.changePercent = data.changePercent
                stock.volume = data.volume
                stock.amount = data.amount
                stock.timestamp = data.timestamp
                
                stock.updateOrderBook(
                    bidPrices: data.bidPrices,
                    bidVolumes: data.bidVolumes,
                    askPrices: data.askPrices,
                    askVolumes: data.askVolumes
                )
                
                try context.save()
            } catch {
                // print("保存股票数据失败: \(error)")
            }
        }
    }
    
    /// 保存K线数据到Core Data
    private func saveKLineDataToCoreData(_ data: KLineData) async {
        let context = persistenceController.container.newBackgroundContext()
        
        await context.perform {
            let kline = KLineEntity.create(
                in: context,
                symbol: data.symbol,
                timeframe: data.timeframe,
                timestamp: data.timestamp,
                open: data.open,
                high: data.high,
                low: data.low,
                close: data.close,
                volume: data.volume,
                amount: data.amount
            )
            
            do {
                try context.save()
            } catch {
                // print("保存K线数据失败: \(error)")
            }
        }
    }
}

// MARK: - 数据模型

// 注意: MarketStockData、OrderBookData、KLineData 已在 Models/DataModels.swift 中定义
// 这里只定义消息传输专用的结构体

// MARK: - 消息模型

/// 市场数据消息
struct MarketDataMessage: Codable {
    let symbol: String
    let name: String?
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let amount: Double
    let bidPrices: [Double]?
    let bidVolumes: [Int64]?
    let askPrices: [Double]?
    let askVolumes: [Int64]?
}

/// K线数据消息
struct KLineDataMessage: Codable {
    let symbol: String
    let timeframe: String
    let timestamp: Double
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let amount: Double
}

/// 订单簿数据消息
struct OrderBookDataMessage: Codable {
    let symbol: String
    let bidPrices: [Double]
    let bidVolumes: [Int64]
    let askPrices: [Double]
    let askVolumes: [Int64]
}

/// 订阅消息
struct SubscribeMessage: Codable {
    let action: String
    let symbols: [String]
}

/// 数据更新请求
struct DataUpdateRequest: Codable {
    let action: String
    let timestamp: Double
}

