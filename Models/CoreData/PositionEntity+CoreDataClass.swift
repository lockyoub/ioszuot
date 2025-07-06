/*
 PositionEntity CoreDataClass
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

/*
 // PositionEntity Core Data类扩展
 // 持仓数据实体类
 */

@objc(PositionEntity)
public class PositionEntity: NSManagedObject {
    
    // MARK: - 便利属性
    
    /// 是否持仓
    var hasPosition: Bool {
        return quantity != 0
    }
    
    /// 计算未实现盈亏 (统一为计算属性)
    var unrealizedPnl: NSDecimalNumber {
        guard let currentPrice = currentPrice else { return NSDecimalNumber.zero }
        let priceDiff = currentPrice.subtracting(avgCost)
        let quantityDecimal = NSDecimalNumber(value: quantity)
        return priceDiff.multiplying(by: quantityDecimal)
    }
    
    /// 计算盈亏率
    var unrealizedPnlPercent: NSDecimalNumber {
        if avgCost.compare(NSDecimalNumber.zero) == .orderedDescending {
            let pnl = unrealizedPnl
            let totalCost = avgCost.multiplying(by: NSDecimalNumber(value: abs(quantity)))
            let rate = pnl.dividing(by: totalCost)
            return rate.multiplying(by: NSDecimalNumber(value: 100))
        }
        return NSDecimalNumber.zero
    }
    
    /// 获取当前市值
    var currentMarketValue: NSDecimalNumber {
        guard let currentPrice = currentPrice else { return NSDecimalNumber.zero }
        let quantityDecimal = NSDecimalNumber(value: abs(quantity))
        return currentPrice.multiplying(by: quantityDecimal)
    }
    
    // MARK: - 精度转换辅助方法
    
    /// 安全地将Double转换为NSDecimalNumber
    private func safeDecimalNumber(from value: Double) -> NSDecimalNumber {
        if value.isNaN || value.isInfinite {
            return NSDecimalNumber.zero
        }
        return NSDecimalNumber(value: value)
    }
    
    /// 安全地将NSDecimalNumber转换为Double
    private func safeDoubleValue(from decimal: NSDecimalNumber?) -> Double {
        guard let decimal = decimal else { return 0.0 }
        let doubleValue = decimal.doubleValue
        if doubleValue.isNaN || doubleValue.isInfinite {
            return 0.0
        }
        return doubleValue
    }
    
    // MARK: - 业务方法
    
    /// 更新止损价格
    func updateStopLoss(price: NSDecimalNumber?) {
        // 这里可以添加止损相关的业务逻辑
        // 目前先预留接口
    }
    
    /// 更新止盈价格
    func updateTakeProfit(price: NSDecimalNumber?) {
        // 这里可以添加止盈相关的业务逻辑
        // 目前先预留接口
    }
}