/*
 SingleStockAnalysisView
 // 单只股票分析视图
 // 作者: MiniMax Agent
 */

import SwiftUI

/// 单只股票分析视图
struct SingleStockAnalysisView: View {
    @StateObject private var analysisService = SingleStockAnalysisService(
        networkManager: NetworkManager.shared,
        config: NetworkConfig.default
    )
    
    @State private var stockSymbol: String = ""
    @State private var showingResult: Bool = false
    @State private var selectedTimeframes: Set<String> = ["1d", "1h", "15m"]
    @State private var selectedIndicators: Set<String> = ["RSI", "MACD", "BOLL"]
    
    private let availableTimeframes = ["5m", "15m", "1h", "1d"]
    private let availableIndicators = ["RSI", "MACD", "BOLL", "MA", "KDJ"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 股票代码输入
                    stockInputSection
                    
                    // 分析参数配置
                    analysisConfigSection
                    
                    // 分析按钮
                    analyzeButton
                    
                    // 分析结果
                    if let result = analysisService.lastResult {
                        analysisResultSection(result)
                    }
                    
                    // 错误信息
                    if let error = analysisService.lastError {
                        errorSection(error)
                    }
                }
                .padding()
            }
            // .navigationTitle("股票分析")
            .disabled(analysisService.isLoading)
        }
    }
    
    // MARK: - 子视图
    
    private var stockInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text("股票代码")
                .font(.headline)
            
            HStack {
                // TextField("请输入股票代码，如：000001.XSHE", text: $stockSymbol)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                
                // Button("示例") {
                    stockSymbol = "000001.XSHE"
                }
                .buttonStyle(.bordered)
            }
            
            // Text("支持格式：000001.XSHE（深交所）、600000.XSHG（上交所）")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var analysisConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Text("分析参数")
                .font(.headline)
            
            // 时间周期选择
            VStack(alignment: .leading, spacing: 8) {
                // Text("时间周期")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableTimeframes, id: \\.self) { timeframe in
                        Toggle(timeframe, isOn: Binding(
                            get: { selectedTimeframes.contains(timeframe) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTimeframes.insert(timeframe)
                                } else {
                                    selectedTimeframes.remove(timeframe)
                                }
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }
            
            // 技术指标选择
            VStack(alignment: .leading, spacing: 8) {
                // Text("技术指标")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(availableIndicators, id: \\.self) { indicator in
                        Toggle(indicator, isOn: Binding(
                            get: { selectedIndicators.contains(indicator) },
                            set: { isSelected in
                                if isSelected {
                                    selectedIndicators.insert(indicator)
                                } else {
                                    selectedIndicators.remove(indicator)
                                }
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var analyzeButton: some View {
        Button(action: performAnalysis) {
            HStack {
                if analysisService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                // Text(analysisService.isLoading ? "分析中..." : "开始分析")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canAnalyze ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canAnalyze || analysisService.isLoading)
    }
    
    private func analysisResultSection(_ result: SingleStockAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 股票基本信息
            VStack(alignment: .leading, spacing: 8) {
                Text("\\(result.name) (\\(result.symbol))")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    // Text("综合建议:")
                        .fontWeight(.medium)
                    
                    Text(result.overallRecommendation)
                        .fontWeight(.bold)
                        .foregroundColor(recommendationColor(result.overallRecommendation))
                    
                    Spacer()
                    
                    // Text("置信度: \\(String(format: "%.1f%%", result.overallConfidence * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 时间周期分析结果
            ForEach(result.timeframeAnalyses) { analysis in
                timeframeAnalysisCard(analysis)
            }
            
            // 分析总结
            VStack(alignment: .leading, spacing: 8) {
                // Text("分析总结")
                    .font(.headline)
                
                Text(result.summary)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // 时间戳
            // Text("分析时间: \\(formatTimestamp(result.timestamp))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func timeframeAnalysisCard(_ analysis: TimeframeAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(analysis.timeframe)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(analysis.overallSignal)
                    .fontWeight(.bold)
                    .foregroundColor(recommendationColor(analysis.overallSignal))
                
                Text("(\\(String(format: "%.1f%%", analysis.confidence * 100)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 价格信息
            HStack {
                VStack(alignment: .leading) {
                    // Text("当前: ¥\\(String(format: "%.2f", analysis.priceData.current))")
                    // Text("最高: ¥\\(String(format: "%.2f", analysis.priceData.high))")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Text("最低: ¥\\(String(format: "%.2f", analysis.priceData.low))")
                    // Text("成交量: \\(formatVolume(analysis.priceData.volume))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // 技术指标
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(analysis.indicators) { indicator in
                    indicatorCard(indicator)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func indicatorCard(_ indicator: TechnicalIndicatorResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(indicator.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(indicator.signal)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(recommendationColor(indicator.signal))
            }
            
            Text(indicator.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    private func errorSection(_ error: NetworkError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                // Text("分析失败")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Text(error.localizedDescription)
                .font(.body)
            
            // Button("重试") {
                analysisService.clearLastResult()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 计算属性
    
    private var canAnalyze: Bool {
        return !stockSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedTimeframes.isEmpty &&
        !selectedIndicators.isEmpty
    }
    
    // MARK: - 方法
    
    private func performAnalysis() {
        Task {
            do {
                let _ = try await analysisService.analyzeStock(
                    symbol: stockSymbol.trimmingCharacters(in: .whitespacesAndNewlines),
                    timeframes: Array(selectedTimeframes),
                    indicators: Array(selectedIndicators)
                )
                showingResult = true
            } catch {
                // 错误已经在service中处理
                // print("分析失败: \\(error)")
            }
        }
    }
    
    private func recommendationColor(_ recommendation: String) -> Color {
        switch recommendation.uppercased() {
            case "BUY", "买入":
            return .green
            case "SELL", "卖出":
            return .red
            case "HOLD", "持有":
            return .orange
        default:
            return .primary
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 100000000 {
            return String(format: "%.2f亿", volume / 100000000)
        } else if volume >= 10000 {
            return String(format: "%.2f万", volume / 10000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        // 简单的时间格式化，可以根据需要改进
        return timestamp.replacingOccurrences(of: "T", with: " ").prefix(19).description
    }
}

#Preview {
    SingleStockAnalysisView()
}

