/*
 CoreDataCompatibility
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation
import XCTest

 // Core Data模型兼容性扩展
 // 解决测试环境中的模型版本问题
 
@testable import StockTradingApp

// MARK: - Core Data模型兼容性
extension NSManagedObjectModel {
    /// 创建测试兼容的模型
    static func testCompatibleModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // StockEntity定义
        let stockEntity = NSEntityDescription()
        stockEntity.name = "StockEntity"
        stockEntity.managedObjectClassName = "StockEntity"
        
        // 添加属性
        let symbolAttr = NSAttributeDescription()
        symbolAttr.name = "symbol"
        symbolAttr.attributeType = .stringAttributeType
        symbolAttr.isOptional = false
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        
        let lastPriceAttr = NSAttributeDescription()
        lastPriceAttr.name = "lastPrice"
        lastPriceAttr.attributeType = .doubleAttributeType
        lastPriceAttr.defaultValue = 0.0
        
        stockEntity.properties = [symbolAttr, nameAttr, lastPriceAttr]
        
        // TradeEntity定义
        let tradeEntity = NSEntityDescription()
        tradeEntity.name = "TradeEntity"
        tradeEntity.managedObjectClassName = "TradeEntity"
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false
        
        let quantityAttr = NSAttributeDescription()
        quantityAttr.name = "quantity"
        quantityAttr.attributeType = .integer32AttributeType
        quantityAttr.defaultValue = 0
        
        tradeEntity.properties = [idAttr, quantityAttr]
        
        model.entities = [stockEntity, tradeEntity]
        return model
    }
}

// MARK: - 测试用的Core Data栈
class TestCoreDataStack {
    static let shared = TestCoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TestModel")
        
        // 使用内存存储
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                // print("Core Data错误: \(error)")
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}