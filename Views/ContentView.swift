/*
 // 主界面
 // 作者: MiniMax Agent
 */

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var marketDataService: MarketDataService
    @EnvironmentObject private var tradingService: TradingService
    @EnvironmentObject private var strategyEngine: StrategyEngine
    
    @State private var selectedTab: Int = 0
    @State private var showingSettings: Bool = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 主面板
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("主面板")
                    }
                    .tag(0)
                
                // 交易界面
                TradingView()
                    .tabItem {
                        Image(systemName: "dollarsign.circle")
                        Text("交易")
                    }
                    .tag(1)
                
                // 策略管理
                NavigationView {
                    VStack {
                        // 原有策略管理
                        StrategyView()
                        
                        // 新增单只股票分析入口
                        NavigationLink(destination: SingleStockAnalysisView()) {
                            HStack {
                                Image(systemName: "magnifyingglass.circle")
                                Text("单只股票分析")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("策略")
                }
                .tag(2)
                
                // 持仓管理
                PositionView()
                    .tabItem {
                        Image(systemName: "briefcase")
                        Text("持仓")
                    }
                    .tag(3)
                
                // 设置
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("设置")
                    }
                    .tag(4)
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ConnectionStatusView()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    MarketStatusView()
                }
            }
        }
        .alert("错误", isPresented: .constant(appState.errorMessage != nil)) {
            Button("确定") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
        .overlay {
            if appState.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    /// 当前标签页标题
    private var tabTitle: String {
        switch selectedTab {
        case 0:
            return "交易面板"
        case 1:
            return "交易操作"
        case 2:
            return "策略管理"
        case 3:
            return "持仓管理"
        case 4:
            return "系统设置"
        default:
            return "股票交易系统"
        }
    }
}

// 注意：ConnectionStatusView, MarketStatusView, LoadingOverlay 现在从 Views/Components 导入
// 移除重复定义，使用共享组件

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
        .environmentObject(MarketDataService())
        .environmentObject(TradingService())
        .environmentObject(StrategyEngine())
}
