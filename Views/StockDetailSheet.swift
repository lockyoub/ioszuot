//
//  StockDetailSheet.swift
//  StockTradingApp
//
//  Created by MiniMax Agent
//  股票详情页面的基础实现
//

import SwiftUI

struct StockDetailSheet: View {
    let stock: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var marketDataService: MarketDataService
    @EnvironmentObject private var stockDataService: StockDataService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 股票基本信息
                    stockHeaderSection
                    
                    // 价格图表区域
                    chartSection
                    
                    // 基本面数据
                    fundamentalDataSection
                    
                    // 技术指标
                    technicalIndicatorsSection
                    
                    // 相关新闻
                    newsSection
                }
                .padding()
            }
            .navigationTitle(stockDataService.getStockName(for: stock))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var stockHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stock)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: addToWatchlist) {
                    Image(systemName: "star")
                        .foregroundColor(.blue)
                }
            }
            
            // Text("基本信息加载中...")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading) {
            // Text("价格走势")
                .font(.headline)
            
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    // Text("图表功能开发中...")
                        .foregroundColor(.secondary)
                )
                .cornerRadius(8)
        }
    }
    
    private var fundamentalDataSection: some View {
        VStack(alignment: .leading) {
            // Text("基本面数据")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // fundamentalDataItem("市盈率", value: "--")
                // fundamentalDataItem("市净率", value: "--")
                // fundamentalDataItem("股息率", value: "--")
                // fundamentalDataItem("市值", value: "--")
            }
        }
    }
    
    private func fundamentalDataItem(_ title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var technicalIndicatorsSection: some View {
        VStack(alignment: .leading) {
            // Text("技术指标")
                .font(.headline)
            
            // Text("技术指标功能开发中...")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var newsSection: some View {
        VStack(alignment: .leading) {
            // Text("相关新闻")
                .font(.headline)
            
            // Text("新闻功能开发中...")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private func addToWatchlist() {
        // TODO: 实现添加到自选股功能
        // print("添加 \(stock) 到自选股")
    }
}

#Preview {
    StockDetailSheet(stock: "AAPL")
        .environmentObject(MarketDataService())
        .environmentObject(StockDataService.shared)
}
