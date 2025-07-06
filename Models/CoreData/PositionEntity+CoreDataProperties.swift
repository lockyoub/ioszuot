//
//  PositionEntity+CoreDataProperties.swift
//  StockTradingApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData


extension PositionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PositionEntity> {
        return NSFetchRequest<PositionEntity>(entityName: "PositionEntity")
    }

    @NSManaged public var avgCost: NSDecimalNumber
    @NSManaged public var currentPrice: NSDecimalNumber?
    @NSManaged public var lastUpdate: Date
    @NSManaged public var marketValue: NSDecimalNumber?
    @NSManaged public var pnl: NSDecimalNumber?
    @NSManaged public var pnlPercent: NSDecimalNumber?
    @NSManaged public var quantity: Int32
    @NSManaged public var symbol: String
    @NSManaged public var stock: StockEntity?
    @NSManaged public var trades: NSSet?

}

// MARK: Generated accessors for trades
extension PositionEntity {

    @objc(addTradesObject:)
    @NSManaged public func addToTrades(_ value: TradeEntity)

    @objc(removeTradesObject:)
    @NSManaged public func removeFromTrades(_ value: TradeEntity)

    @objc(addTrades:)
    @NSManaged public func addToTrades(_ values: NSSet)

    @objc(removeTrades:)
    @NSManaged public func removeFromTrades(_ values: NSSet)

}

extension PositionEntity : Identifiable {
    // ID is already defined in PositionEntity+CoreDataClass.swift
}
