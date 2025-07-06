/*
 // ConfigurationManager - 增强版配置管理器
 // 作者: MiniMax Agent
 */

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let configuration: [String: Any]
    
    private init() {
        // 根据构建配置加载不同的配置文件
        #if DEBUG
        let configFileName = "Config-Debug"
        #else
        let configFileName = "Config-Release"
        #endif
        
        guard let configPath = Bundle.main.path(forResource: configFileName, ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath) as? [String: Any] else {
            // 回退到默认配置
            self.configuration = self.defaultConfiguration()
            return
        }
        
        self.configuration = configData
    }
    
    private func defaultConfiguration() -> [String: Any] {
        return [
            "baseURL": "https://api.example.com",
            "marketDataWebSocketURL": "wss://api.example.com/ws/marketdata",
            "pushNotificationWebSocketURL": "wss://api.example.com/ws/notifications",
            "apiTimeout": 30.0,
            "retryAttempts": 3,
            "cacheEnabled": true,
            "logLevel": "info"
        ]
    }
    
    // MARK: - 网络配置
    
    var baseURL: String {
        return configuration["baseURL"] as? String ?? "https://api.example.com"
    }
    
    var marketDataWebSocketURL: String {
        return configuration["marketDataWebSocketURL"] as? String ?? "wss://api.example.com/ws/marketdata"
    }
    
    var pushNotificationWebSocketURL: String {
        return configuration["pushNotificationWebSocketURL"] as? String ?? "wss://api.example.com/ws/notifications"
    }
    
    var apiTimeout: TimeInterval {
        return configuration["apiTimeout"] as? TimeInterval ?? 30.0
    }
    
    var retryAttempts: Int {
        return configuration["retryAttempts"] as? Int ?? 3
    }
    
    // MARK: - 应用配置
    
    var cacheEnabled: Bool {
        return configuration["cacheEnabled"] as? Bool ?? true
    }
    
    var logLevel: String {
        return configuration["logLevel"] as? String ?? "info"
    }
    
    // MARK: - 交易配置
    
    var defaultStopLossPercentage: Double {
        return configuration["defaultStopLossPercentage"] as? Double ?? 0.05 // 5%
    }
    
    var defaultTakeProfitPercentage: Double {
        return configuration["defaultTakeProfitPercentage"] as? Double ?? 0.10 // 10%
    }
    
    var maxPositionSize: Double {
        return configuration["maxPositionSize"] as? Double ?? 100000.0
    }
    
    // MARK: - 费率配置
    
    var tradingFeeRate: Double {
        return configuration["tradingFeeRate"] as? Double ?? 0.0003 // 0.03%
    }
    
    var minimumTradingFee: Double {
        return configuration["minimumTradingFee"] as? Double ?? 5.0
    }
    
    // MARK: - 安全配置
    
    var sslPinningEnabled: Bool {
        return configuration["sslPinningEnabled"] as? Bool ?? false
    }
    
    var securityChecksEnabled: Bool {
        return configuration["securityChecksEnabled"] as? Bool ?? true
    }
    
    // MARK: - 开发配置
    
    var enableMockData: Bool {
        return configuration["enableMockData"] as? Bool ?? false
    }
}
