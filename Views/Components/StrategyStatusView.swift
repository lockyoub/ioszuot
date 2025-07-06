/*
 StrategyStatusView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Strategy Status View
 // Display current strategy running status and statistics
struct StrategyStatusView: View {
    @EnvironmentObject private var strategyEngine: StrategyEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                // Text("策略状态")
                    .font(.headline)
                Spacer()
                
                // 策略开关
                Toggle("", isOn: .constant(strategyEngine.isRunning))
                    .scaleEffect(0.8)
            }
            
            // 策略统计
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                StrategyStatItem(
                    // title: "活跃策略",
                    value: "\(strategyEngine.activeStrategies.count)",
                    icon: "play.circle.fill",
                    color: .green
                )
                
                StrategyStatItem(
                    // title: "今日信号",
                    value: "\(strategyEngine.todaySignals)",
                    icon: "bell.fill",
                    color: .orange
                )
                
                StrategyStatItem(
                    // title: "成功率",
                    value: "\(String(format: "%.1f", strategyEngine.successRate))%",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StrategyStatItem(
                    // title: "收益率",
                    value: "\(String(format: "%.2f", strategyEngine.totalReturn))%",
                    icon: "arrow.up.right",
                    color: strategyEngine.totalReturn >= 0 ? .green : .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StrategyStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    StrategyStatusView()
        .environmentObject(StrategyEngine())
}