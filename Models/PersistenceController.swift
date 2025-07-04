/*
 // Data persistence
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create preview data
        createPreviewData(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            // fatalError("预览数据创建失败: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TradingDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure persistent storage
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true

            // Set file protection to complete protection, data inaccessible when device locked
            storeDescription.setOption(FileProtectionType.complete as NSObject, 
                                     forKey: NSPersistentStoreFileProtectionKey)
            
            // Optional: enable WAL mode for better performance and security
            storeDescription.setOption("WAL" as NSObject, forKey: "journal_mode")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // print("Core Data迁移或加载失败: \(error), \(error.userInfo)")
                
                // If migration error, consider resetting database (use with caution)
                if error.code == NSPersistentStoreIncompatibleVersionHashError ||
                   error.code == NSMigrationMissingSourceModelError {
                    // In production, should provide user choice: backup data or reset
                    // fatalError("数据库迁移失败，请联系技术支持")
                } else {
                    // fatalError("Core Data加载失败: \(error), \(error.userInfo)")
                }
            } else {
            }
        })
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// 保存上下文
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                // print("Core Data保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// 创建后台上下文
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// 批量删除实体
    func batchDelete<T: NSManagedObject>(_ entity: T.Type) throws {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}

// MARK: - 预览数据创建
extension PersistenceController {
    static func createPreviewData(in context: NSManagedObjectContext) {
        // Create sample stock data - using NSDecimalNumber
        let sampleStock = StockEntity(context: context)
        sampleStock.symbol = "000001.SZ"
        sampleStock.name = "平安银行"
        sampleStock.exchange = "SZ"
        sampleStock.lastPrice = NSDecimalNumber(string: "12.50").doubleValue
        sampleStock.change = NSDecimalNumber(string: "0.28").doubleValue
        sampleStock.changePercent = NSDecimalNumber(string: "2.35").doubleValue
        sampleStock.volume = 1000000
        sampleStock.amount = NSDecimalNumber(string: "12500000.00").doubleValue
        sampleStock.timestamp = Date()
        
        // Create sample K-line data - using NSDecimalNumber
        let sampleKLine = KLineEntity(context: context)
        sampleKLine.symbol = "000001.SZ"
        sampleKLine.timeframe = "1m"
        sampleKLine.timestamp = Date()
        sampleKLine.open = NSDecimalNumber(string: "12.30").doubleValue
        sampleKLine.high = NSDecimalNumber(string: "12.55").doubleValue
        sampleKLine.low = NSDecimalNumber(string: "12.25").doubleValue
        sampleKLine.close = NSDecimalNumber(string: "12.50").doubleValue
        sampleKLine.volume = 50000
        sampleKLine.amount = NSDecimalNumber(string: "620000.00").doubleValue
        
        // Create sample trade records - using NSDecimalNumber
        let sampleTrade = TradeEntity(context: context)
        sampleTrade.id = UUID().uuidString
        sampleTrade.symbol = "000001.SZ"
        sampleTrade.direction = "buy"
        sampleTrade.quantity = 1000
        sampleTrade.price = NSDecimalNumber(string: "12.30").doubleValue
        sampleTrade.amount = NSDecimalNumber(string: "12300.00").doubleValue
        sampleTrade.commission = NSDecimalNumber(string: "5.00").doubleValue
        sampleTrade.timestamp = Date()
        sampleTrade.strategy = "High-frequency strategy"
        sampleTrade.pnl = NSDecimalNumber(string: "200.00").doubleValue
        
        // Create sample positions - using NSDecimalNumber
        let samplePosition = PositionEntity(context: context)
        samplePosition.symbol = "000001.SZ"
        samplePosition.quantity = 1000
        samplePosition.avgCost = NSDecimalNumber(string: "12.30")
        samplePosition.currentPrice = NSDecimalNumber(string: "12.50")
        samplePosition.marketValue = NSDecimalNumber(string: "12500.00")
        samplePosition.pnl = NSDecimalNumber(string: "200.00")
        samplePosition.pnlPercent = NSDecimalNumber(string: "1.63")
        samplePosition.lastUpdate = Date()
    }
}