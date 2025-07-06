//
//  CommonExtensions.swift
//  StockTradingApp
//
//  Created by MiniMax Agent
//  用于存放共享的扩展方法，避免代码重复
//

import Foundation
import UIKit

// MARK: - 数字格式化扩展
extension Double {
    /// 格式化成交量显示
    func formatVolume() -> String {
        if self >= 1_000_000_000 {
            return String(format: "%.1fB", self / 1_000_000_000)
        } else if self >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", self / 1_000)
        } else {
            return String(format: "%.0f", self)
        }
    }
    
    /// 格式化价格显示
    func formatPrice() -> String {
        return String(format: "%.2f", self)
    }
    
    /// 格式化百分比显示
    func formatPercent() -> String {
        return String(format: "%.2f%%", self)
    }
}

// MARK: - 日期扩展
extension Date {
    /// 计算相对于当前时间的时间差字符串
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - 颜色扩展
extension UIColor {
    /// 根据价格变化获取颜色
    static func priceColor(for change: Double) -> UIColor {
        if change > 0 {
            return .systemGreen
        } else if change < 0 {
            return .systemRed
        } else {
            return .label
        }
    }
    
    /// 主题颜色定义
    struct Theme {
        static let upColor = UIColor.systemGreen
        static let downColor = UIColor.systemRed
        static let neutralColor = UIColor.label
        static let backgroundGradientStart = UIColor.systemBlue.withAlphaComponent(0.1)
        static let backgroundGradientEnd = UIColor.systemPurple.withAlphaComponent(0.1)
    }
}

// MARK: - 交易所颜色扩展
extension String {
    /// 根据交易所代码获取颜色
    var exchangeColor: UIColor {
        switch self {
        case "NASDAQ":
            return UIColor.systemBlue
        case "NYSE":
            return UIColor.systemPurple
        case "AMEX":
            return UIColor.systemOrange
        default:
            return UIColor.systemGray
        }
    }
}
