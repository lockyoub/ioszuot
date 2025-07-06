/*
 AccessibilityGuide
 // 作者: MiniMax Agent
 */

import Foundation

 // UI测试Accessibility指南
 // 为UI测试提供一致的accessibility identifiers

// MARK: - Accessibility Identifiers
struct AccessibilityIdentifiers {
    
    // MARK: - 主要界面
    static let mainView = "MainView"
    static let tradingView = "TradingView"
    static let dashboardView = "DashboardView" 
    static let portfolioView = "PortfolioView"
    static let settingsView = "SettingsView"
    
    // MARK: - 交易相关
    // static let stockSearchField = "股票搜索"
    // static let searchResults = "搜索结果"
    // static let buyButton = "买入"
    // static let sellButton = "卖出"
    // static let quantityField = "数量"
    // static let priceField = "价格"
    // static let confirmBuyButton = "确认买入"
    // static let confirmSellButton = "确认卖出"
    
    // MARK: - 投资组合相关
    // static let positionsList = "持仓列表"
    // static let totalValueLabel = "总市值"
    // static let totalPnLLabel = "总盈亏"
    // static let dayPnLLabel = "日盈亏"
    
    // MARK: - 订单相关
    static let orderHistoryView = "OrderHistoryView"
    // static let ordersList = "订单列表"
    // static let orderStatusLabel = "订单状态"
    
    // MARK: - 实时数据
    static let realTimePriceLabel = "RealTimePrice"
    // static let connectionStatusLabel = "连接状态"
    
    // MARK: - 设置相关
    // static let notificationSettings = "通知设置"
    // static let tradingSettings = "交易设置"
    static let aboutView = "AboutView"
}

// MARK: - Accessibility Labels (中文)
struct AccessibilityLabels {
    // static let stockSearch = "股票搜索输入框"
    // static let buyOrder = "买入订单按钮"
    // static let sellOrder = "卖出订单按钮"
    // static let positionDetail = "持仓详情"
    // static let realTimePrice = "实时股价"
    // static let orderHistory = "订单历史"
}

// MARK: - UI测试辅助扩展
extension XCUIElement {
    /// 等待元素出现并可交互
    func waitForInteraction(timeout: TimeInterval = 5.0) -> Bool {
        return self.waitForExistence(timeout: timeout) && self.isHittable
    }
    
    /// 安全点击（确保元素可交互）
    func safeTap() {
        if self.waitForInteraction() {
            self.tap()
        }
    }
}