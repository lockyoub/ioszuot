import CoreData
import Foundation

extension OrderEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderEntity> {
        return NSFetchRequest<OrderEntity>(entityName: "OrderEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var symbol: String
    @NSManaged public var direction: String
    @NSManaged public var type: String
    @NSManaged public var quantity: Int32
    @NSManaged public var price: NSDecimalNumber
    @NSManaged public var status: String
    @NSManaged public var createTime: Date
    @NSManaged public var updateTime: Date?
    @NSManaged public var side: String
    @NSManaged public var stock: StockEntity?

}
