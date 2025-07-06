/*
 PositionView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Position Management View
 // Position details and management interface
struct PositionView: View {
    @EnvironmentObject private var tradingService: TradingService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 持仓概览
                    PositionOverviewView()
                    
                    // 占位内容
                    VStack {
                        Image(systemName: "briefcase")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        // Text("持仓管理")
                            .font(.headline)
                        // Text("详细持仓管理功能正在开发中")
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
            // .navigationTitle("持仓管理")
        }
    }
}

#Preview {
    PositionView()
        .environmentObject(TradingService())
}