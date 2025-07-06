# 📱 股票交易应用 (StockTradingApp)

基于SwiftUI开发的iOS股票交易应用，支持实时行情、智能交易策略和投资组合管理。

## 🚀 自动编译

本项目支持GitHub Actions自动编译，无需Mac电脑和开发者账号即可生成IPA文件。

### 使用方法

1. **Fork或上传项目到GitHub**
2. **触发编译**：
   - 推送代码到main分支自动触发
   - 或在Actions页面手动触发"iOS Build and Export IPA"工作流
3. **下载IPA**：编译完成后在Actions的Artifacts中下载
4. **自助签名安装**：使用牛蛙助手等工具签名后安装到iPhone

### 📁 编译产物

- `StockTradingApp.ipa` - 主要安装文件
- `StockTradingApp-unsigned.ipa` - 未签名版本（备用）
- `Release-Info.md` - 编译信息说明

## 🛠 技术架构

- **框架**: SwiftUI + Combine
- **数据存储**: Core Data
- **图表显示**: Charts 5.0
- **最低版本**: iOS 16.0+
- **语言**: Swift 5.9+

## 📋 功能特性

### 🔍 市场数据
- 实时股价监控
- K线图表分析
- 技术指标计算
- 价格预警提醒

### 💰 交易功能
- 快速下单交易
- 订单历史管理
- 持仓成本计算
- 风险控制监控

### 🧠 智能策略
- 自动交易策略
- 策略回测分析
- 信号生成提醒
- 策略性能统计

### 📊 投资组合
- 持仓总览管理
- 收益率计算
- 资产配置分析
- 投资报告生成

## 🔧 开发环境

如果要本地开发，需要：

- macOS 12.0+
- Xcode 14.0+
- Swift 5.9+
- iOS 16.0+ SDK

### 本地编译

```bash
# 克隆项目
git clone [your-repo-url]
cd StockTradingApp

# 解析依赖
swift package resolve

# 生成Xcode项目
swift package generate-xcodeproj

# 用Xcode打开项目
open StockTradingApp.xcodeproj
```

## 📝 版本历史

### v1.0.0 (2025-06-30)
- ✅ 完整的股票交易功能
- ✅ SwiftUI现代化界面
- ✅ Core Data数据持久化
- ✅ 实时市场数据接入
- ✅ 智能交易策略引擎
- ✅ GitHub Actions自动编译

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交Issue和Pull Request来帮助改进项目！

## ⚠️ 免责声明

本应用仅供学习和研究使用，不构成投资建议。实际交易请谨慎操作，风险自负。

---

**作者**: MiniMax Agent  
**最后更新**: 2025-06-30
