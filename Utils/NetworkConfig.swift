/*
 NetworkConfig
 // 作者: MiniMax Agent
 */

import Foundation

struct NetworkConfig {
    let baseURL: String
    let timeout: TimeInterval
    let maxRetries: Int
    let connectTimeout: TimeInterval
    let readTimeout: TimeInterval
    let apiKey: String?  // API密钥,应通过认证token替代
    
    static let `default` = NetworkConfig(
        // baseURL: "http://localhost:8000",  // 本地开发环境
        // timeout: 60.0,  // 增加超时时间以适应策略分析
        maxRetries: 3,
        connectTimeout: 10.0,
        // readTimeout: 60.0,  // 增加读取超时时间
        // apiKey: nil  // 移除硬编码API密钥，改用JWT认证
    )
    
    /// 生产环境配置
    static let production = NetworkConfig(
        // baseURL: "https://your-domain.com",  // 配置HTTPS后修改
        timeout: 30.0,
        maxRetries: 3,
        connectTimeout: 10.0,
        readTimeout: 30.0,
        // apiKey: nil  // 移除硬编码API密钥，改用JWT认证
    )
    
    /// WebSocket配置
    var webSocketURL: String {
        return baseURL.replacingOccurrences(of: "http", with: "ws") + "/ws"
    }
    
    /// API基础路径
    var apiBasePath: String {
        return baseURL + "/api"
    }
}

// MARK: - API端点配置
extension NetworkConfig {
    enum APIEndpoint {
        case health
        case stocks
        case stockDetail(String)
        case marketData
        
        func path(with config: NetworkConfig) -> String {
            switch self {
            case .health:
                return config.apiBasePath + "/health"
            case .stocks:
                return config.apiBasePath + "/stocks"
            case .stockDetail(let symbol):
                return config.apiBasePath + "/stocks/\(symbol)"
            case .marketData:
                return config.apiBasePath + "/market-data"
            }
        }
    }
}