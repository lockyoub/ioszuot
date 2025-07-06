/*
 PortfolioCalculator
 // 作者: MiniMax Agent
 */

import CoreData
import Foundation

class PortfolioCalculator {
    
    // MARK: - 数据结构
    
    /// 成本基础记录（用于FIFO计算）
    struct CostBasis {
        let quantity: Int
        let price: Double
        let purchaseDate: Date
        let transactionId: String
    }
    
    /// 已实现盈亏详情
    struct RealizedPnLDetails {
        let realizedGain: Double
        let realizedLoss: Double
        let netRealized: Double
        let avgCostBasis: Double
        let remainingCostBasis: [CostBasis]
    }
    
    /// 未实现盈亏详情
    struct UnrealizedPnLDetails {
        let unrealizedGain: Double
        let unrealizedLoss: Double
        let netUnrealized: Double
        let currentValue: Double
        let costBasis: Double
    }
    
    // MARK: - 【P1功能实现】FIFO成本基础计算
    
    /// 计算卖出交易的已实现盈亏（使用FIFO方法）
    /// - Parameters:
    ///   - sellQuantity: 卖出数量
    ///   - sellPrice: 卖出价格
    ///   - sellDate: 卖出日期
    ///   - costBasisHistory: 成本基础历史（按购买时间排序）
    /// - Returns: 已实现盈亏详情
    func calculateRealizedPnL(
        sellQuantity: Int,
        sellPrice: Double,
        sellDate: Date,
        costBasisHistory: [CostBasis]
    ) -> RealizedPnLDetails {
        
        var remainingToSell = sellQuantity
        var totalCostBasis = 0.0
        var realizedGain = 0.0
        var realizedLoss = 0.0
        var updatedCostBasis: [CostBasis] = []
        
        // FIFO算法：从最早的购买记录开始处理
        for var costRecord in costBasisHistory.sorted(by: { $0.purchaseDate < $1.purchaseDate }) {
            
            if remainingToSell <= 0 {
                // 剩余的成本基础保持不变
                updatedCostBasis.append(costRecord)
                continue
            }
            
            let quantityToUse = min(remainingToSell, costRecord.quantity)
            let proportionalCost = costRecord.price * Double(quantityToUse)
            
            totalCostBasis += proportionalCost
            
            // 计算这部分的盈亏
            let saleValue = sellPrice * Double(quantityToUse)
            let gainLoss = saleValue - proportionalCost
            
            if gainLoss > 0 {
                realizedGain += gainLoss
            } else {
                realizedLoss += abs(gainLoss)
            }
            
            // 更新剩余数量
            remainingToSell -= quantityToUse
            
            // 如果这批成本基础还有剩余，更新数量
            if costRecord.quantity > quantityToUse {
                costRecord = CostBasis(
                    quantity: costRecord.quantity - quantityToUse,
                    price: costRecord.price,
                    purchaseDate: costRecord.purchaseDate,
                    transactionId: costRecord.transactionId
                )
                updatedCostBasis.append(costRecord)
            }
        }
        
        let avgCostBasis = sellQuantity > 0 ? totalCostBasis / Double(sellQuantity) : 0.0
        let netRealized = realizedGain - realizedLoss
        
        return RealizedPnLDetails(
            realizedGain: realizedGain,
            realizedLoss: realizedLoss,
            netRealized: netRealized,
            avgCostBasis: avgCostBasis,
            remainingCostBasis: updatedCostBasis
        )
    }
    
    /// 计算未实现盈亏
    /// - Parameters:
    ///   - currentPrice: 当前市场价格
    ///   - costBasisHistory: 当前持仓的成本基础
    /// - Returns: 未实现盈亏详情
    func calculateUnrealizedPnL(
        currentPrice: Double,
        costBasisHistory: [CostBasis]
    ) -> UnrealizedPnLDetails {
        
        let totalQuantity = costBasisHistory.reduce(0) { $0 + $1.quantity }
        let totalCostBasis = costBasisHistory.reduce(0.0) { $0 + (Double($1.quantity) * $1.price) }
        let currentValue = Double(totalQuantity) * currentPrice
        
        let unrealizedPnL = currentValue - totalCostBasis
        
        let unrealizedGain = max(0, unrealizedPnL)
        let unrealizedLoss = max(0, -unrealizedPnL)
        
        return UnrealizedPnLDetails(
            unrealizedGain: unrealizedGain,
            unrealizedLoss: unrealizedLoss,
            netUnrealized: unrealizedPnL,
            currentValue: currentValue,
            costBasis: totalCostBasis
        )
    }
    
    // MARK: - 【P1功能实现】持仓更新方法
    
    /// 处理买入交易后的持仓更新
    /// - Parameters:
    ///   - position: 要更新的持仓对象
    ///   - buyQuantity: 买入数量
    ///   - buyPrice: 买入价格
    ///   - buyDate: 买入日期
    ///   - transactionId: 交易ID
    func updatePositionAfterBuy(
        position: inout PositionEntity,
        buyQuantity: Int,
        buyPrice: Double,
        buyDate: Date,
        transactionId: String
    ) {
        // 更新持仓数量
        position.quantity += Int32(buyQuantity)
        
        // 更新平均成本（加权平均）
        let oldValue = Double(position.quantity - Int32(buyQuantity)) * position.avgCost
        let newValue = Double(buyQuantity) * buyPrice
        let totalValue = oldValue + newValue
        
        position.avgCost = totalValue / Double(position.quantity)
        position.lastModified = buyDate
        
        // 在实际实现中，这里应该将新的成本基础记录存储到数据库
        // 用于后续的FIFO计算
        // print("新增成本基础: 数量=\(buyQuantity), 价格=\(buyPrice), 日期=\(buyDate)") // 调试语句已注释
    }
    
    /// 处理卖出交易后的持仓更新
    /// - Parameters:
    ///   - position: 要更新的持仓对象
    ///   - sellQuantity: 卖出数量
    ///   - sellPrice: 卖出价格
    ///   - sellDate: 卖出日期
    ///   - costBasisHistory: 成本基础历史
    /// - Returns: 已实现盈亏详情
    func updatePositionAfterSell(
        position: inout PositionEntity,
        sellQuantity: Int,
        sellPrice: Double,
        sellDate: Date,
        costBasisHistory: [CostBasis]
    ) -> RealizedPnLDetails {
        
        // 计算已实现盈亏
        let pnlDetails = calculateRealizedPnL(
            sellQuantity: sellQuantity,
            sellPrice: sellPrice,
            sellDate: sellDate,
            costBasisHistory: costBasisHistory
        )
        
        // 更新持仓数量
        position.quantity -= Int32(sellQuantity)
        
        // 如果全部卖出，清零持仓
        if position.quantity <= 0 {
            position.quantity = 0
            position.avgCost = 0
        } else {
            // 重新计算平均成本（基于剩余的成本基础）
            let remainingCostBasis = pnlDetails.remainingCostBasis
            let totalQuantity = remainingCostBasis.reduce(0) { $0 + $1.quantity }
            let totalCost = remainingCostBasis.reduce(0.0) { $0 + (Double($1.quantity) * $1.price) }
            
            position.avgCost = totalQuantity > 0 ? totalCost / Double(totalQuantity) : 0
        }
        
        position.lastModified = sellDate
        
        return pnlDetails
    }
    
    // MARK: - 投资组合汇总计算
    
    /// 计算投资组合总体P&L
    /// - Parameters:
    ///   - positions: 所有持仓
    ///   - currentPrices: 当前价格字典 [股票代码: 价格]
    /// - Returns: 投资组合P&L汇总
    func calculatePortfolioPnL(
        positions: [PositionEntity],
        currentPrices: [String: Double]
    ) -> PortfolioPnLSummary {
        
        var totalUnrealizedPnL = 0.0
        var totalMarketValue = 0.0
        var totalCostBasis = 0.0
        var positionCount = 0
        
        for position in positions where position.quantity > 0 {
            guard let currentPrice = currentPrices[position.symbol ?? ""] else { continue }
            
            let quantity = Double(position.quantity)
            let costBasis = quantity * position.avgCost
            let marketValue = quantity * currentPrice
            let unrealizedPnL = marketValue - costBasis
            
            totalCostBasis += costBasis
            totalMarketValue += marketValue
            totalUnrealizedPnL += unrealizedPnL
            positionCount += 1
        }
        
        let totalReturnPct = totalCostBasis > 0 ? (totalUnrealizedPnL / totalCostBasis) * 100 : 0
        
        return PortfolioPnLSummary(
            totalMarketValue: totalMarketValue,
            totalCostBasis: totalCostBasis,
            totalUnrealizedPnL: totalUnrealizedPnL,
            totalReturnPercentage: totalReturnPct,
            positionCount: positionCount
        )
    }
}

// MARK: - 投资组合P&L汇总数据结构

/// 投资组合P&L汇总
struct PortfolioPnLSummary {
    let totalMarketValue: Double      // 总市值
    let totalCostBasis: Double        // 总成本基础
    let totalUnrealizedPnL: Double    // 总未实现盈亏
    let totalReturnPercentage: Double // 总收益率百分比
    let positionCount: Int            // 持仓数量
    
    /// 格式化显示文本
    var formattedSummary: String {
        let pnlColor = totalUnrealizedPnL >= 0 ? "🟢" : "🔴"
        let returnColor = totalReturnPercentage >= 0 ? "📈" : "📉"
        
        return """
        // \(pnlColor) 总盈亏: ¥\(String(format: "%.2f", totalUnrealizedPnL))
        // \(returnColor) 收益率: \(String(format: "%.2f", totalReturnPercentage))%
        // 💼 总市值: ¥\(String(format: "%.2f", totalMarketValue))
        // 🏷️ 持仓数: \(positionCount)
        """
    }
}

// MARK: - CoreData扩展支持

extension PositionEntity {
    /// 计算当前持仓的市值
    func marketValue(at currentPrice: Double) -> Double {
        return Double(quantity) * currentPrice
    }
    
    /// 计算当前持仓的未实现盈亏
    func unrealizedPnL(at currentPrice: Double) -> Double {
        let marketValue = self.marketValue(at: currentPrice)
        let costBasis = Double(quantity) * avgCost
        return marketValue - costBasis
    }
    
    /// 计算收益率百分比
    func returnPercentage(at currentPrice: Double) -> Double {
        guard avgCost > 0 else { return 0 }
        return ((currentPrice - avgCost) / avgCost) * 100
    }
}