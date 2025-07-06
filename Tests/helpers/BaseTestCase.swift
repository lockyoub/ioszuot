/*
 BaseTestCase
 // 作者: MiniMax Agent
 */

import Combine
import CoreData
import XCTest

 // 测试基类
 // 提供通用的测试设置和工具方法

@testable import StockTradingApp

// MARK: - 测试Core Data堆栈
class TestCoreDataStack {
    static let shared = TestCoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TradingDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        return container
    }()
    
    private init() {}
}

class BaseTestCase: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
        testContext = createInMemoryContext()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 测试工具方法
    
    /// 创建内存中的Core Data上下文用于测试
    func createInMemoryContext() -> NSManagedObjectContext {
        let persistentContainer = TestCoreDataStack.shared.persistentContainer
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            precondition(error == nil)
        }
        
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// 等待异步操作完成
    func waitForExpectation(timeout: TimeInterval = 5.0, handler: (() -> Void)? = nil) {
        let exp = expectation(description: "Async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: timeout)
        handler?()
    }
    
    /// 创建测试用的StockEntity
    func createTestStock(symbol: String = "AAPL", name: String = "Apple Inc.") -> StockEntity {
        let stock = StockEntity(context: testContext)
        stock.symbol = symbol
        stock.name = name
        stock.exchange = "NASDAQ"
        stock.lastPrice = 150.0
        stock.change = 2.5
        stock.changePercent = 1.67
        stock.volume = 1000000
        stock.amount = 150000000.0
        stock.timestamp = Date()
        
        try? testContext.save()
        return stock
    }
    
    /// 创建测试用的TradeEntity
    func createTestTrade(symbol: String = "AAPL", direction: String = "buy", quantity: Int32 = 100) -> TradeEntity {
        let trade = TradeEntity(context: testContext)
        trade.id = UUID().uuidString
        trade.symbol = symbol
        trade.direction = direction
        trade.quantity = quantity
        trade.price = 150.0
        trade.amount = Double(quantity) * 150.0
        trade.commission = 5.0
        trade.timestamp = Date()
        trade.pnl = 0.0
        
        try? testContext.save()
        return trade
    }
    
    /// 清理测试数据
    func cleanupTestData() {
        let context = testContext
        let fetchRequests: [NSFetchRequest<NSFetchRequestResult>] = [
            NSFetchRequest(entityName: "StockEntity"),
            NSFetchRequest(entityName: "TradeEntity"),
            NSFetchRequest(entityName: "PositionEntity"),
            NSFetchRequest(entityName: "OrderEntity")
        ]
        
        for request in fetchRequests {
            if let results = try? context.fetch(request) {
                for object in results {
                    if let managedObject = object as? NSManagedObject {
                        context.delete(managedObject)
                    }
                }
            }
        }
        
        try? context.save()
    }
    
    /// 创建测试用的PositionEntity
    func createTestPosition(symbol: String = "AAPL", quantity: Int32 = 100) -> PositionEntity {
        let position = PositionEntity(context: testContext)
        position.symbol = symbol
        position.quantity = quantity
        position.avgPrice = 150.0
        position.currentPrice = 155.0
        position.marketValue = Double(quantity) * 155.0
        position.unrealizedPnL = Double(quantity) * 5.0
        position.updateTime = Date()
        
        try? testContext.save()
        return position
    }
    
    /// 创建测试用的OrderEntity  
    func createTestOrder(symbol: String = "AAPL", direction: String = "buy", quantity: Int32 = 100) -> OrderEntity {
        let order = OrderEntity(context: testContext)
        order.id = UUID().uuidString
        order.symbol = symbol
        order.direction = direction
        order.orderType = "market"
        order.quantity = quantity
        order.filledQuantity = 0
        order.price = 150.0
        order.avgPrice = 0.0
        order.status = "pending"
        order.createTime = Date()
        order.updateTime = Date()
        
        try? testContext.save()
        return order
    }
}