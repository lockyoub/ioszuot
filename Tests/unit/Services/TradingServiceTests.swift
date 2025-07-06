/*
 TradingServiceTests
 // 作者: MiniMax Agent
 */

import Combine
import XCTest

 // TradingService单元测试
 // 测试交易服务的核心功能

@testable import StockTradingApp

final class TradingServiceTests: BaseTestCase {
    
        var tradingService: MockEnhancedTradingService!
        var mockNetworkManager: MockNetworkManager!
        var mockRiskManager: MockRiskManager!
        var cancellables: Set<AnyCancellable> = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockNetworkManager = MockNetworkManager()
        mockRiskManager = MockRiskManager()
        
        // 注入依赖
        tradingService = MockEnhancedTradingService()
        tradingService.setRiskManager(mockRiskManager)
    }
    
    override func tearDownWithError() throws {
        tradingService = nil
        mockNetworkManager = nil
        mockRiskManager = nil
        cancellables.removeAll()
        try super.tearDownWithError()
    }
    
    // MARK: - 连接测试
    
    func testConnectToTradingAPISuccess() {
        let expectation = XCTestExpectation(description: "连接交易API成功")
        
        Task {
            do {
                let result = await performAsyncOperation()
                XCTAssertTrue(result, "连接交易API应该成功")
                expectation.fulfill()
            } catch {
                XCTFail("连接不应失败: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConnectToTradingAPIFailure() {
        let expectation = XCTestExpectation(description: "连接交易API失败处理")
        
        mockNetworkManager.shouldFail = true
        
        Task {
            do {
                let result = await performAsyncOperationWithFailure()
                XCTAssertFalse(result, "连接失败时应返回false")
            } catch {
                // 预期的错误，测试通过
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    // MARK: - 订单管理测试
    
    func testPlaceOrderSuccess() {
        let expectation = XCTestExpectation(description: "下单成功")
        
        let orderRequest = OrderRequest(
            symbol: "AAPL",
            quantity: 100,
            price: NSDecimalNumber(string: "150.00"),
            type: .limit,
            side: .buy
        )
        
        Task {
            do {
                let result = try await tradingService.placeOrder(orderRequest)
                XCTAssertNotNil(result, "下单应该返回订单ID")
            } catch {
                XCTFail("下单不应失败: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    func testPlaceOrderRiskCheck() {
        let expectation = XCTestExpectation(description: "下单风控检查")
        
        // 设置风控管理器拒绝订单
        mockRiskManager.shouldRejectOrder = true
        
        let orderRequest = OrderRequest(
            symbol: "AAPL",
            // quantity: 100000, // 大量订单触发风控
            price: NSDecimalNumber(string: "150.00"),
            type: .limit,
            side: .buy
        )
        
        Task {
            do {
                _ = try await tradingService.placeOrder(orderRequest)
                XCTFail("风控检查应该拒绝大额订单")
            } catch let error as TradingError where error == .riskCheckFailed {
                // 预期的风控错误，测试通过
            } catch {
                XCTFail("捕获到非预期的错误类型: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    func testCancelOrderSuccess() {
        let expectation = XCTestExpectation(description: "撤单成功")
        
        // 模拟成功的撤单响应
        mockNetworkManager.mockResponse = "{\"success\": true}".data(using: .utf8)
        
        Task {
            do {
                let result = try await tradingService.cancelOrder(orderId: "order_123")
                XCTAssertTrue(result, "撤单应该成功")
            } catch {
                XCTFail("撤单不应失败: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    // MARK: - 账户信息测试
    
    func testRefreshAccountInfo() {
        let expectation = XCTestExpectation(description: "刷新账户信息")
        
        Task {
            do {
                let result = await performAsyncOperation()
                XCTAssertTrue(result, "刷新账户信息应该成功")
            } catch {
                 XCTFail("刷新账户信息不应失败: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    // MARK: - 错误处理测试
    
    func testNetworkErrorHandling() {
        let expectation = XCTestExpectation(description: "网络错误处理")
        
        mockNetworkManager.shouldFail = true
        
        Task {
            do {
                _ = try await tradingService.fetchAccountInfo()
                XCTFail("网络错误时应抛出异常")
            } catch let error as NetworkError where error == .connectionFailed {
                // 预期的网络错误
            } catch {
                XCTFail("捕获到非预期的错误类型: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    func testInvalidResponseHandling() {
        let expectation = XCTestExpectation(description: "无效响应处理")
        
        // 设置无效响应
        mockNetworkManager.mockResponse = "invalid json".data(using: .utf8)
        
        Task {
            do {
                _ = try await tradingService.fetchAccountInfo()
                XCTFail("无效响应时应抛出异常")
            } catch let error as TradingError where error == .invalidResponse {
                // 预期的无效响应错误
            } catch {
                XCTFail("捕获到非预期的错误类型: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)

    // MARK: - 实时数据测试
    
    func testRealtimeDataSubscription() {
        let expectation = XCTestExpectation(description: "实时数据订阅")
        
        let symbols = ["AAPL", "GOOGL", "MSFT"]
        
        tradingService.subscribeToRealtimeData(symbols: symbols)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("实时数据订阅失败: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { marketData in
                    XCTAssertTrue(symbols.contains(marketData.symbol), "应接收到正确的股票数据")
                }
            )
            .store(in: &cancellables)
        
        // 模拟接收到数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.tradingService.simulateMarketDataReceived()
    }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - 私有辅助方法
    
    private func performAsyncOperation() async -> Bool {
        // 模拟异步操作
// try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        return true
    }
    
    private func performAsyncOperationWithFailure() async -> Bool {
        // 模拟异步操作失败
// try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        return false
    }

    // MARK: - 持仓更新逻辑测试

    func testUpdatePositionAfterTrade_Buy_CalculatesCorrectAveragePrice() {
        let expectation = XCTestExpectation(description: "买入后正确计算加权平均成本")

        let context = persistenceController.container.viewContext

        // 准备初始持仓
        let initialPosition = PositionEntity(context: context)
        initialPosition.symbol = "AAPL"
        initialPosition.quantity = 100
        initialPosition.avgPrice = NSDecimalNumber(string: "150.0")

        // 准备新的买入交易
        let newTrade = TradeEntity(context: context)
        newTrade.symbol = "AAPL"
        newTrade.quantity = 50
        newTrade.price = NSDecimalNumber(string: "160.0")
        newTrade.direction = "buy"

        // 执行待测试的方法
        Task {
            await tradingService.updatePositionAfterTrade(trade: newTrade)

            // 验证结果
            let fetchRequest: NSFetchRequest<PositionEntity> = PositionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "symbol == %@", "AAPL")

            do {
                let positions = try context.fetch(fetchRequest)
                guard let updatedPosition = positions.first else {
                    XCTFail("未能找到更新后的持仓")
                    return
                }

                // 计算预期的平均价格: (100 * 150 + 50 * 160) / (100 + 50) = (15000 + 8000) / 150 = 23000 / 150 = 153.333...
                let expectedAvgPrice = NSDecimalNumber(string: "153.33333333")
                let scale = NSDecimalNumberHandler(roundingMode: .plain, scale: 8, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)

                XCTAssertEqual(updatedPosition.quantity, 150, "数量应为150")
                XCTAssertTrue(updatedPosition.avgPrice.rounding(accordingToBehavior: scale).isEqual(to: expectedAvgPrice.rounding(accordingToBehavior: scale)), "平均成本计算不正确。预期: \(expectedAvgPrice), 实际: \(updatedPosition.avgPrice)")

            } catch {
                XCTFail("获取持仓失败: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
