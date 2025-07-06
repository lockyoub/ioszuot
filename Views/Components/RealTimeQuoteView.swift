/*
 RealTimeQuoteView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Real-time Quote View
 // Display real-time stock price and basic information
struct RealTimeQuoteView: View {
    let symbol: String
    
    @State private var quote = StockQuote.sample
    @State private var isUpdating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Text("实时行情")
                    .font(.headline)
                Spacer()
                
                if isUpdating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    // Button("刷新") {
                        refreshQuote()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // 价格信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(String(format: "%.2f", quote.currentPrice))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(quote.changePercent >= 0 ? .green : .red)
                    
                    HStack(spacing: 8) {
                        Text("\(quote.changePercent >= 0 ? "+" : "")\(String(format: "%.2f", quote.change))")
                        Text("\(quote.changePercent >= 0 ? "+" : "")\(String(format: "%.2f", quote.changePercent))%")
                    }
                    .font(.caption)
                    .foregroundColor(quote.changePercent >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Text("成交量")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(formatVolume(quote.volume))")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    // Text("成交额")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(formatAmount(quote.amount))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // 四项关键指标
            HStack(spacing: 16) {
                // QuoteInfoItem(title: "开盘", value: String(format: "%.2f", quote.openPrice))
                // QuoteInfoItem(title: "最高", value: String(format: "%.2f", quote.highPrice))
                // QuoteInfoItem(title: "最低", value: String(format: "%.2f", quote.lowPrice))
                // QuoteInfoItem(title: "昨收", value: String(format: "%.2f", quote.prevClose))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            if !isUpdating {
                updateQuote()
            }
        }
    }
    
    private func refreshQuote() {
        isUpdating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateQuote()
            isUpdating = false
        }
    }
    
    private func updateQuote() {
        // 模拟实时数据更新
        let change = Double.random(in: -0.1...0.1)
        quote.currentPrice += change
        quote.change = quote.currentPrice - quote.prevClose
        quote.changePercent = (quote.change / quote.prevClose) * 100
        
        if quote.currentPrice > quote.highPrice {
            quote.highPrice = quote.currentPrice
        }
        if quote.currentPrice < quote.lowPrice {
            quote.lowPrice = quote.currentPrice
        }
        
        quote.volume += Int(Double.random(in: 100...1000))
        quote.amount = Double(quote.volume) * quote.currentPrice
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume > 100000000 {
            return String(format: "%.2f亿", Double(volume) / 100000000)
        } else if volume > 10000 {
            return String(format: "%.2f万", Double(volume) / 10000)
        } else {
            return "\(volume)"
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount > 100000000 {
            return String(format: "%.2f亿", amount / 100000000)
        } else if amount > 10000 {
            return String(format: "%.2f万", amount / 10000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}

struct QuoteInfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StockQuote {
    var currentPrice: Double
    var change: Double
    var changePercent: Double
    var openPrice: Double
    var highPrice: Double
    var lowPrice: Double
    var prevClose: Double
    var volume: Int
    var amount: Double
    
    static let sample = StockQuote(
        currentPrice: 12.34,
        change: 0.23,
        changePercent: 1.90,
        openPrice: 12.11,
        highPrice: 12.45,
        lowPrice: 12.05,
        prevClose: 12.11,
        volume: 1234567,
        amount: 15234567.89
    )
}

#Preview {
    RealTimeQuoteView(symbol: "000001.SZ")
        .padding()
}