/*
 // 市场状态
 // 作者: MiniMax Agent
 */

import SwiftUI

struct MarketStatusView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(appState.currentMarketStatus.color)
                .frame(width: 8, height: 8)
            
            Text(appState.currentMarketStatus.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MarketStatusView()
        .environmentObject(AppState())
}