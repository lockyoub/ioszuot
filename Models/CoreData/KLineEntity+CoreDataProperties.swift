import CoreData
import Foundation

extension KLineEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KLineEntity> {
        return NSFetchRequest<KLineEntity>(entityName: "KLineEntity")
    }

    @NSManaged public var symbol: String
    @NSManaged public var timeframe: String
    @NSManaged public var timestamp: Date
    @NSManaged public var open: Double
    @NSManaged public var high: Double
    @NSManaged public var low: Double
    @NSManaged public var close: Double
    @NSManaged public var volume: Int64
    @NSManaged public var amount: Double
    @NSManaged public var stock: StockEntity?

}

