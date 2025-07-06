import CoreData
import Foundation

extension StrategySignalEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StrategySignalEntity> {
        return NSFetchRequest<StrategySignalEntity>(entityName: "StrategySignalEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var symbol: String
    @NSManaged public var signal: String
    @NSManaged public var confidence: NSDecimalNumber?
    @NSManaged public var price: NSDecimalNumber?
    @NSManaged public var timestamp: Date
    @NSManaged public var strategy: StrategyEntity?

}
