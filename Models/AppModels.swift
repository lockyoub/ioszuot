/*
 AppModels
 // 作者: MiniMax Agent
 */

import Combine
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var currentMarketStatus: MarketStatus = .closed
    @Published var notifications: [AppNotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// 添加通知
    func addNotification(_ notification: AppNotification) {
        DispatchQueue.main.async {
            self.notifications.append(notification)
        }
    }
    
    /// 清除通知
    func clearNotifications() {
        notifications.removeAll()
    }
    
    /// 设置错误消息
    func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
    
    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - 市场状态
enum MarketStatus {
    case beforeOpen    // 开盘前
    case open         // 开盘中
    case pause        // 暂停
    case closed       // 收盘
    case afterClose   // 收盘后
    
    var displayName: String {
        switch self {
        case .beforeOpen:
            return "开盘前"
        case .open:
            return "开盘中"
        case .pause:
            return "暂停"
        case .closed:
            return "收盘"
        case .afterClose:
            return "收盘后"
        }
    }
    
    var color: Color {
        switch self {
        case .beforeOpen:
            return .orange
        case .open:
            return .green
        case .pause:
            return .yellow
        case .closed:
            return .red
        case .afterClose:
            return .gray
        }
    }
}

// MARK: - 应用通知
struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date = Date()
    
    enum NotificationType {
        case info
        case warning
        case error
        case trading
    }
}
