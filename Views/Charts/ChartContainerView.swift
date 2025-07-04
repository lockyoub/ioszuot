/*
 ChartContainerView
 // 作者: MiniMax Agent
 */

import SwiftUI

struct ChartContainerView: View {
    @StateObject private var chartDataManager = ChartDataManager()
    @StateObject private var watchlistService = WatchlistService()
    @StateObject private var chartShareService = ChartShareService()
    @StateObject private var dataExportService = DataExportService()
    
    @State private var selectedTimestamp: Date?
    @State private var isFullScreen = false
    @State private var showIndicators = true
    @State private var showVolume = true
    @State private var showingPriceAlert = false
    @State private var showingExportOptions = false
    
    let stockCode: String
    let stockName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 股票信息头部
            stockHeader
            
            // 主图表区域
            mainChartArea
            
            // 控制面板
            if !isFullScreen {
                controlPanel
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                fullScreenToggle
            }
        }
        .sheet(isPresented: $showingPriceAlert) {
            PriceAlertSetupView(
                stockCode: stockCode,
                stockName: stockName,
                currentPrice: chartDataManager.candlestickData.last?.close ?? 0.0
            )
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                // title: Text("选择导出格式"),
                // message: Text("将当前图表数据导出为文件"),
                buttons: [
                    // .default(Text("CSV格式")) {
                        exportDataWithFormat(.csv)
                    },
                    // .default(Text("Excel格式")) {
                        exportDataWithFormat(.excel)
                    },
                    // .cancel(Text("取消"))
                ]
            )
        }
    }
    
    // MARK: - 股票信息头部
    private var stockHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stockName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(stockCode)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let latestPrice = chartDataManager.candlestickData.last {
                    HStack {
                        Text(String(format: "%.2f", latestPrice.close))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        let change = calculatePriceChange(latestPrice)
                        Text(String(format: "%+.2f (%.2f%%)", change.absolute, change.percentage))
                            .font(.caption)
                            .foregroundColor(change.absolute >= 0 ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            // 实时状态指示器
            realTimeStatusIndicator
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - 主图表区域
    private var mainChartArea: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 1) {
                // K线图表
                CandlestickChartView(stockCode: stockCode) { price, date in
                    selectedTimestamp = date
                }
                .frame(height: isFullScreen ? 400 : 300)
                
                // 成交量图表
                if showVolume {
                    VolumeChartView(
                        volumeData: chartDataManager.volumeData,
                        selectedTimestamp: selectedTimestamp
                    )
                    .frame(height: 100)
                }
                
                // 技术指标图表
                if showIndicators && !chartDataManager.indicatorData.isEmpty {
                    IndicatorChartView(
                        indicatorData: chartDataManager.indicatorData,
                        selectedTimestamp: selectedTimestamp
                    )
                    .frame(height: 120)
                }
                
                // 成交量指标
                if showVolume && !chartDataManager.volumeData.isEmpty {
                    VolumeIndicatorView(volumeData: chartDataManager.volumeData)
                        .frame(height: 60)
                }
            }
        }
    }
    
    // MARK: - 控制面板
    private var controlPanel: some View {
        VStack(spacing: 8) {
            // 图表选项开关
            HStack {
                // Toggle("成交量", isOn: $showVolume)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Spacer()
                
                // Toggle("技术指标", isOn: $showIndicators)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .foregroundColor(.white)
            
            // 快速操作按钮
            HStack(spacing: 12) {
                QuickActionButton(
                    // title: "添加自选",
                    icon: "star",
                    action: addToWatchlist
                )
                
                QuickActionButton(
                    // title: "价格提醒",
                    icon: "bell",
                    action: setupPriceAlert
                )
                
                QuickActionButton(
                    // title: "分享图表",
                    icon: "square.and.arrow.up",
                    action: shareChart
                )
                
                QuickActionButton(
                    // title: "导出数据",
                    icon: "square.and.arrow.down",
                    action: exportData
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - 实时状态指示器
    private var realTimeStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: UUID())
            
            // Text("实时")
                .font(.caption2)
                .foregroundColor(.green)
        }
    }
    
    // MARK: - 全屏切换按钮
    private var fullScreenToggle: some View {
        Button(action: toggleFullScreen) {
            Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 计算价格变化
    private func calculatePriceChange(_ latestPrice: CandlestickData) -> (absolute: Double, percentage: Double) {
        guard chartDataManager.candlestickData.count > 1 else {
            return (0, 0)
        }
        
        let previousPrice = chartDataManager.candlestickData[chartDataManager.candlestickData.count - 2].close
        let absolute = latestPrice.close - previousPrice
        let percentage = (absolute / previousPrice) * 100
        
        return (absolute, percentage)
    }
    
    // MARK: - 操作方法
    private func toggleFullScreen() {
        withAnimation(.easeInOut) {
            isFullScreen.toggle()
        }
    }
    
    private func addToWatchlist() {
        // 实现添加自选股功能
        HapticFeedback.impact(.medium)
        
        Task {
            let success = await watchlistService.addToWatchlist(
                stockCode: stockCode,
                stockName: stockName
            )
            
            DispatchQueue.main.async {
                if success {
                    HapticFeedback.notification(.success)
                } else {
                    HapticFeedback.notification(.error)
                }
            }
        }
    }
    
    private func setupPriceAlert() {
        // 实现价格提醒设置
        HapticFeedback.impact(.medium)
        showingPriceAlert = true
    }
    
    private func shareChart() {
        // 实现图表分享功能
        HapticFeedback.impact(.light)
        
        Task {
            if let image = await chartShareService.generateStockChartImage(
                stockCode: stockCode,
                stockName: stockName,
                includeWatermark: true
            ) {
                await MainActor.run {
                    chartShareService.shareChart(
                        image: image,
                        stockCode: stockCode,
                        stockName: stockName
                    )
                }
            }
        }
    }
    
    private func exportData() {
        // 实现数据导出功能
        HapticFeedback.impact(.light)
        showingExportOptions = true
    }
    
    private func exportDataWithFormat(_ format: DataExportService.ExportFormat) {
        Task {
            if let fileURL = await dataExportService.exportCandlestickData(
                stockCode: stockCode,
                stockName: stockName,
                candlestickData: chartDataManager.candlestickData,
                format: format
            ) {
                await MainActor.run {
                    dataExportService.shareExportedFile(fileURL: fileURL)
                    HapticFeedback.notification(.success)
                }
            } else {
                await MainActor.run {
                    HapticFeedback.notification(.error)
                }
            }
        }
    }
}

// MARK: - 快速操作按钮
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
    }
}

// MARK: - 触觉反馈工具
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator.prepare()
        impactGenerator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
    
    static func selection() {
        let selectionGenerator = UISelectionFeedbackGenerator()
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }
}

// MARK: - 预览
struct ChartContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChartContainerView(
                stockCode: "000001",
                // stockName: "平安银行"
            )
        }
        .preferredColorScheme(.dark)
    }
}