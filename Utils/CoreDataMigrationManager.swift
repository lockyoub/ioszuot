/*
 CoreDataMigrationManager
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

class CoreDataMigrationManager {
    
    static let shared = CoreDataMigrationManager()
    
    private init() {}
    
    /// 执行到统一模型的迁移
    func migrateToUnifiedModels() {
        let context = PersistenceController.shared.container.viewContext
        
        // 1. 迁移股票数据
        migrateStockEntities(context: context)
        
        // 2. 迁移K线数据
        migrateKLineEntities(context: context)
        
        // 3. 迁移交易数据
        migrateTradeEntities(context: context)
        
        // 4. 迁移持仓数据
        migratePositionEntities(context: context)
        
        // 5. 保存所有更改
        do {
            try context.save()
        } catch {
            // print("❌ 迁移保存失败: \(error)")
        }
    }
    
    private func migrateStockEntities(context: NSManagedObjectContext) {
        let request: NSFetchRequest<StockEntity> = StockEntity.fetchRequest()
        
        do {
            let oldStocks = try context.fetch(request)
            
            for oldStock in oldStocks {
                // 创建新的统一股票实体
                let unifiedStock = UnifiedStockEntity(context: context)
                
                // 迁移数据
                unifiedStock.code = oldStock.symbol
                unifiedStock.symbol = oldStock.symbol
                unifiedStock.name = oldStock.name
                unifiedStock.exchange = oldStock.exchange
                // unifiedStock.market = oldStock.exchange  // 使用exchange作为market
                
                // 价格数据 (确保高精度)
                unifiedStock.lastPrice = oldStock.lastPrice as? NSDecimalNumber ?? NSDecimalNumber.zero
                unifiedStock.change = oldStock.change as? NSDecimalNumber ?? NSDecimalNumber.zero
                unifiedStock.changePercent = oldStock.changePercent as? NSDecimalNumber ?? NSDecimalNumber.zero
                unifiedStock.amount = oldStock.amount as? NSDecimalNumber ?? NSDecimalNumber.zero
                
                // 成交量转换 (从Int64转为NSDecimalNumber)
                unifiedStock.volume = NSDecimalNumber(value: oldStock.volume)
                
                // 时间戳
                unifiedStock.timestamp = oldStock.timestamp
                unifiedStock.createdAt = Date()
                unifiedStock.updatedAt = Date()
                unifiedStock.lastModified = Date()
                
                // 迁移盘口数据
                migrateMarketDepthData(from: oldStock, to: unifiedStock, context: context)
                
        // print("📄 迁移股票: \(oldStock.symbol)") // 调试语句已注释
            }
            
        } catch {
            // print("❌ 股票数据迁移失败: \(error)")
        }
    }
    
    private func migrateMarketDepthData(from oldStock: StockEntity, to unifiedStock: UnifiedStockEntity, context: NSManagedObjectContext) {
        // 解析原有的JSON格式盘口数据
        if let bidPricesStr = oldStock.bidPrices,
           let bidPricesData = bidPricesStr.data(using: .utf8),
           let bidPrices = try? JSONDecoder().decode([String].self, from: bidPricesData),
           let bidVolumesStr = oldStock.bidVolumes,
           let bidVolumesData = bidVolumesStr.data(using: .utf8),
           let bidVolumes = try? JSONDecoder().decode([Int64].self, from: bidVolumesData) {
            
            // 创建买盘档位
            for (index, price) in bidPrices.enumerated() {
                if index < bidVolumes.count {
                    let depthEntity = UnifiedMarketDepthEntity(context: context)
                    depthEntity.price = NSDecimalNumber.fromString(price)
                    depthEntity.volume = bidVolumes[index]
                    depthEntity.side = "bid"
                    depthEntity.level = Int32(index + 1)
                    depthEntity.timestamp = unifiedStock.timestamp
                    depthEntity.stock = unifiedStock
                }
            }
        }
        
        // 类似地处理卖盘数据...
    }
    
    // 其他迁移方法...
}