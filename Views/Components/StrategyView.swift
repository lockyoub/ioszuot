/*
 StrategyView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Strategy Management View
 // Strategy configuration and management interface
struct StrategyView: View {
    @EnvironmentObject private var strategyEngine: StrategyEngine
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 策略状态
                    StrategyStatusView()
                    
                    // 占位内容
                    VStack {
                        Image(systemName: "brain.head.profile")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        // Text("策略管理")
                            .font(.headline)
                        // Text("策略配置功能正在开发中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            // .navigationTitle("策略管理")
        }
    }
}

#Preview {
    StrategyView()
        .environmentObject(StrategyEngine())
}