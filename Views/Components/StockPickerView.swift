/*
 StockPickerView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Stock Picker View
 // Stock search and selection interface
struct StockPickerView: View {
    @Binding var selectedSymbol: String
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var popularStocks = ["000001.SZ", "000002.SZ", "600000.SH", "600036.SH"]
    @State private var recentStocks = ["000858.SZ", "002415.SZ"]
    
    var filteredStocks: [String] {
        if searchText.isEmpty {
            return popularStocks + recentStocks
        } else {
            return (popularStocks + recentStocks).filter { 
                $0.lowercased().contains(searchText.lowercased()) 
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding()
                
                // 股票列表
                List {
                    if !searchText.isEmpty {
                        // Section("搜索结果") {
                            ForEach(filteredStocks, id: \.self) { stock in
                                StockRowView(
                                    symbol: stock,
                                    isSelected: stock == selectedSymbol
                                ) {
                                    selectedSymbol = stock
                                    isPresented = false
                                }
                            }
                        }
                    } else {
                        // Section("热门股票") {
                            ForEach(popularStocks, id: \.self) { stock in
                                StockRowView(
                                    symbol: stock,
                                    isSelected: stock == selectedSymbol
                                ) {
                                    selectedSymbol = stock
                                    isPresented = false
                                }
                            }
                        }
                        
                        if !recentStocks.isEmpty {
                            // Section("最近选择") {
                                ForEach(recentStocks, id: \.self) { stock in
                                    StockRowView(
                                        symbol: stock,
                                        isSelected: stock == selectedSymbol
                                    ) {
                                        selectedSymbol = stock
                                        isPresented = false
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            // .navigationTitle("选择股票")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                // trailing: Button("取消") {
                    isPresented = false
                }
            )
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            // TextField("搜索股票代码或名称", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                // Button("清除") {
                    text = ""
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
    }
}

struct StockRowView: View {
    let symbol: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(getStockName(symbol))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("¥12.34")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("+2.35%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getStockName(_ symbol: String) -> String {
        let stockNames = [
            // "000001.SZ": "平安银行",
            // "000002.SZ": "万科A",
            // "600000.SH": "浦发银行",
            // "600036.SH": "招商银行",
            // "000858.SZ": "五粮液",
            // "002415.SZ": "海康威视"
        ]
            return stockNames[symbol] ?? "股票名称"
    }
}

#Preview {
    StockPickerView(
        selectedSymbol: .constant("000001.SZ"),
        isPresented: .constant(true)
    )
}