/*
 // 连接状态
 // 作者: MiniMax Agent
 */

import SwiftUI

struct ConnectionStatusView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
            
            Text(connectionText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var connectionColor: Color {
        appState.isConnected ? .green : .red
    }
    
    private var connectionText: String {
        // appState.isConnected ? "已连接" : "未连接"
    }
}

#Preview {
    ConnectionStatusView()
        .environmentObject(AppState())
}