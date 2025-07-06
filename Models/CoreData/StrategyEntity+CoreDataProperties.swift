import CoreData
import Foundation

extension StrategyEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StrategyEntity> {
        return NSFetchRequest<StrategyEntity>(entityName: "StrategyEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var timeframe: String
    @NSManaged public var parameters: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var signals: NSSet?
    @NSManaged public var trades: NSSet?

}

// MARK: Generated accessors for signals
extension StrategyEntity {

    @objc(addSignalsObject:)
    @NSManaged public func addToSignals(_ value: StrategySignalEntity)

    @objc(removeSignalsObject:)
    @NSManaged public func removeFromSignals(_ value: StrategySignalEntity)

    @objc(addSignals:)
    @NSManaged public func addToSignals(_ values: NSSet)

    @objc(removeSignals:)
    @NSManaged public func removeFromSignals(_ values: NSSet)

}

// MARK: Generated accessors for trades
extension StrategyEntity {

    @objc(addTradesObject:)
    @NSManaged public func addToTrades(_ value: TradeEntity)

    @objc(removeTradesObject:)
    @NSManaged public func removeFromTrades(_ value: TradeEntity)

    @objc(addTrades:)
    @NSManaged public func addToTrades(_ values: NSSet)

    @objc(removeTrades:)
    @NSManaged public func removeFromTrades(_ values: NSSet)

}
