/*
 SecurityManager
 // 作者: MiniMax Agent
 */

import Foundation
import Security
import UIKit

// Security Manager - Simplified Version
// Removed all security detection features to avoid compilation and packaging issues

public class SecurityManager {
    
    static let shared = SecurityManager()
    
    private init() {
        // Simplified initialization, no security checks
    }
    
    // MARK: - 公共接口（保持兼容性）
    
    /// 执行安全检查 - 简化版本，不进行任何实际检查
    public func performSecurityChecks() {
        // Remove all security detection, return directly
    }
    
    /// SSL证书验证 - 使用系统默认验证
    public func validateServerTrust(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        // Use system default certificate validation, no certificate pinning
        return evaluateServerTrustUsingSystemRoots(serverTrust)
    }
    
    // MARK: - 简化的证书验证
    
    private func evaluateServerTrustUsingSystemRoots(_ serverTrust: SecTrust) -> Bool {
        let result = SecTrustEvaluateWithError(serverTrust, nil)
        return result
    }

}

// MARK: - 通知扩展（保持兼容性）

extension Notification.Name {
    static let securityThreatDetected = Notification.Name("SecurityThreatDetected")
    static let networkSecurityThreat = Notification.Name("NetworkSecurityThreat")
}

// MARK: - URLSessionDelegate 集成（简化版本）

extension SecurityManager: URLSessionDelegate {
    
    public func urlSession(_ session: URLSession, 
                          didReceive challenge: URLAuthenticationChallenge, 
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Simplified SSL handling, use system default validation
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Use system default validation
        if evaluateServerTrustUsingSystemRoots(serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}