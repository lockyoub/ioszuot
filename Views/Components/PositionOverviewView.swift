/*
 PositionOverviewView
 // 作者: MiniMax Agent
 */

import SwiftUI

// Position Overview View
// Display current position and profit/loss statistics
struct PositionOverviewView: View {
    @EnvironmentObject private var tradingService: TradingService
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
                // Text("持仓概览")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    showingDetails.toggle()
                }) {
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            // 持仓统计
            HStack(spacing: 16) {
                PositionStatCard(
                    // title: "持仓数量",
                    value: "\(tradingService.positions.count)",
                    color: .blue
                )
                
                PositionStatCard(
                    // title: "总市值",
                    value: formatCurrency(tradingService.totalMarketValue),
                    color: .green
                )
                
                PositionStatCard(
                    // title: "浮动盈亏",
                    value: formatCurrency(tradingService.unrealizedPnL),
                    color: tradingService.unrealizedPnL >= 0 ? .green : .red
                )
            }
            
            if showingDetails {
                // 持仓详情
                if tradingService.positions.isEmpty {
                    // Text("暂无持仓")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(tradingService.positions.prefix(3), id: \.id) { position in
                            PositionRowView(position: position)
                        }
                        
                        if tradingService.positions.count > 3 {
                            // NavigationLink("查看全部持仓 (\(tradingService.positions.count))") {
                                PositionsView()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }
}

struct PositionStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PositionRowView: View {
    let position: Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                
                // Text("\(position.quantity)股")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(position.currentValue))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(position.pnlPercentage >= 0 ? "+" : "")\(String(format: "%.2f", position.pnlPercentage))%")
                    .font(.caption2)
                    .foregroundColor(position.pnlPercentage >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }
}

#Preview {
    PositionOverviewView()
        .environmentObject(TradingService())
}