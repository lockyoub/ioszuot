//
//  OfflineQueueEntity+CoreDataProperties.swift
//  StockTradingApp
//
//  Created by Core Data Generator
//

import Foundation
import CoreData

extension OfflineQueueEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineQueueEntity> {
        return NSFetchRequest<OfflineQueueEntity>(entityName: "OfflineQueueEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var operationType: String?
    @NSManaged public var data: Data?
    @NSManaged public var timestamp: Date?
    @NSManaged public var retryCount: Int32
    @NSManaged public var status: String?
    @NSManaged public var errorMessage: String?
    @NSManaged public var processedAt: Date?
    @NSManaged public var nextRetryAt: Date?

}

extension OfflineQueueEntity : Identifiable {

}
