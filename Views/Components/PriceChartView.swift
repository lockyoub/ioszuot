/*
 PriceChartView
 // 作者: MiniMax Agent
 */

import Charts as DGCharts
import SwiftUI

 // Price Chart View
 // Display stock price candlestick chart
struct PriceChartView: View {
    let symbol: String
    let timeframe: String
    
    @State private var chartData: [KLineData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(symbol) - \(timeframe)")
                    .font(.headline)
                Spacer()
                // Text("价格走势")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                    )
            } else {
                Chart(chartData, id: \.timestamp) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Price", data.close)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            loadChartData()
        }
        .onChange(of: symbol) { _ in
            loadChartData()
        }
        .onChange(of: timeframe) { _ in
            loadChartData()
        }
    }
    
    private func loadChartData() {
        isLoading = true
        
        // 模拟数据加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chartData = generateSampleData()
            isLoading = false
        }
    }
    
    private func generateSampleData() -> [KLineData] {
        let basePrice = 12.34
        var data: [KLineData] = []
        let now = Date()
        
        for i in 0..<50 {
            let timestamp = now.addingTimeInterval(TimeInterval(-i * 60))
            let price = basePrice + Double.random(in: -0.5...0.5)
            
            data.append(KLineData(
                timestamp: timestamp,
                open: price,
                high: price + 0.1,
                low: price - 0.1,
                close: price,
                volume: Double.random(in: 1000...10000)
            ))
        }
        
        return data.reversed()
    }
}

struct KLineData {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

#Preview {
    PriceChartView(symbol: "000001.SZ", timeframe: "1m")
}