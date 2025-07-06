import CoreData
import Foundation

extension TradeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TradeEntity> {
        return NSFetchRequest<TradeEntity>(entityName: "TradeEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var symbol: String
    @NSManaged public var direction: String
    @NSManaged public var quantity: Int32
    @NSManaged public var price: Double
    @NSManaged public var amount: Double
    @NSManaged public var commission: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var strategy: String?
    @NSManaged public var pnl: Double
    @NSManaged public var stock: StockEntity?
    @NSManaged public var strategyEntity: StrategyEntity?

}
