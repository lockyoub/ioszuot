import Combine
import Darwin.C
import Foundation
import OSLog
import UIKit
#if canImport(ifaddrs)
import ifaddrs
#endif

@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - 发布属性
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: MemoryInfo = MemoryInfo()
    @Published var diskUsage: DiskInfo = DiskInfo()
    @Published var networkStats: NetworkStats = NetworkStats()
    @Published var frameRate: Double = 60.0
    @Published var isMonitoring = false
    
    // MARK: - 私有属性
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "StockTradingApp", category: "Performance")
    
    // 性能历史记录
    private var performanceHistory: [PerformanceSnapshot] = []
    private let maxHistoryCount = 100
    
    // 单例
    static let shared = PerformanceMonitor()
    
    private init() {
        setupPerformanceObservers()
    }
    
    // MARK: - 监控控制
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
        
        // logger.info("性能监控已启动")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        // 停止帧率监控
        stopDisplayLink()
        
        // logger.info("性能监控已停止")
    }
    
    // MARK: - 性能指标更新
    private func updatePerformanceMetrics() {
        // 更新CPU使用率
        cpuUsage = getCurrentCPUUsage()
        
        // 更新内存使用情况
        memoryUsage = getCurrentMemoryInfo()
        
        // 更新磁盘使用情况
        diskUsage = getCurrentDiskInfo()
        
        // 更新网络统计
        networkStats = getCurrentNetworkStats()
        
        // 更新帧率
        frameRate = getCurrentFrameRate()
        
        // 记录性能快照
        recordPerformanceSnapshot()
        
        // 检查性能警告
        checkPerformanceWarnings()
    }
    
    // MARK: - CPU监控
    private func getCurrentCPUUsage() -> Double {
        var threadsList = thread_array_t.allocate(capacity: 1)
        var threadsCount = mach_msg_type_number_t(0)
        var totalUsageOfCPU: Double = 0.0
        
        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        if result == KERN_SUCCESS {
            for i in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else { continue }
                
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0)
                }
            }
            
            // 释放内存
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }
        
        return totalUsageOfCPU
    }
    
    // MARK: - 内存监控
    private func getCurrentMemoryInfo() -> MemoryInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            
            return MemoryInfo(
                usedMemoryMB: usedMemory / 1024.0 / 1024.0,
                totalMemoryMB: totalMemory / 1024.0 / 1024.0,
                usagePercentage: (usedMemory / totalMemory) * 100.0
            )
        }
        
        return MemoryInfo()
    }
    
    // MARK: - 磁盘监控
    private func getCurrentDiskInfo() -> DiskInfo {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return DiskInfo()
        }
        
        do {
            let resourceValues = try documentsPath.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])
            
            let availableCapacity = resourceValues.volumeAvailableCapacity ?? 0
            let totalCapacity = resourceValues.volumeTotalCapacity ?? 0
            let usedCapacity = totalCapacity - availableCapacity
            
            return DiskInfo(
                usedSpaceGB: Double(usedCapacity) / 1024.0 / 1024.0 / 1024.0,
                totalSpaceGB: Double(totalCapacity) / 1024.0 / 1024.0 / 1024.0,
                availableSpaceGB: Double(availableCapacity) / 1024.0 / 1024.0 / 1024.0,
                usagePercentage: Double(usedCapacity) / Double(totalCapacity) * 100.0
            )
            
        } catch {
            // logger.error("获取磁盘信息失败: \(error)")
            return DiskInfo()
        }
    }
    
    // MARK: - 网络监控
    // 网络监控相关属性
    private var previousNetworkStats: NetworkInterfaceStats?
    private var lastNetworkStatsTimestamp: Date?
    
    private func getCurrentNetworkStats() -> NetworkStats {
        let currentStats = getSystemNetworkStats()
        let currentTime = Date()
        
        if let previousStats = previousNetworkStats,
           let lastTime = lastNetworkStatsTimestamp {
            let timeDelta = currentTime.timeIntervalSince(lastTime)
            let downloadDelta = currentStats.bytesReceived - previousStats.bytesReceived
            let uploadDelta = currentStats.bytesSent - previousStats.bytesSent
            
            let downloadSpeedBps = Double(downloadDelta) / timeDelta
            let uploadSpeedBps = Double(uploadDelta) / timeDelta
            
            previousNetworkStats = currentStats
            lastNetworkStatsTimestamp = currentTime
            
            return NetworkStats(
                downloadSpeedKBps: downloadSpeedBps / 1024.0,
                uploadSpeedKBps: uploadSpeedBps / 1024.0,
                totalDownloadMB: Double(currentStats.bytesReceived) / (1024.0 * 1024.0),
                totalUploadMB: Double(currentStats.bytesSent) / (1024.0 * 1024.0)
            )
        } else {
            // 首次调用，保存初始状态
            previousNetworkStats = currentStats
            lastNetworkStatsTimestamp = currentTime
            
            return NetworkStats(
                downloadSpeedKBps: 0.0,
                uploadSpeedKBps: 0.0,
                totalDownloadMB: Double(currentStats.bytesReceived) / (1024.0 * 1024.0),
                totalUploadMB: Double(currentStats.bytesSent) / (1024.0 * 1024.0)
            )
        }
    }
    
    private func getSystemNetworkStats() -> NetworkInterfaceStats {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var totalBytesReceived: UInt64 = 0
        var totalBytesSent: UInt64 = 0
        
        #if canImport(ifaddrs)
        guard getifaddrs(&ifaddr) == 0 else {
            return NetworkInterfaceStats(bytesReceived: 0, bytesSent: 0)
        }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_LINK) {
                let name = String(cString: interface.ifa_name)
                
                // 只统计主要网络接口
                if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                    if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                        totalBytesReceived += UInt64(data.pointee.ifi_ibytes)
                        totalBytesSent += UInt64(data.pointee.ifi_obytes)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        #endif
        return NetworkInterfaceStats(bytesReceived: totalBytesReceived, bytesSent: totalBytesSent)
    }
    
    private struct NetworkInterfaceStats {
        let bytesReceived: UInt64
        let bytesSent: UInt64
    }
    
    // MARK: - 帧率监控
    // 帧率监控相关属性
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var currentFPS: Double = 60.0
    
    private func getCurrentFrameRate() -> Double {
        // 如果displayLink还没有启动，启动它
        if displayLink == nil {
            setupDisplayLink()
        }
        return currentFPS
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func displayLinkTick(_ displayLink: CADisplayLink) {
        let currentTimestamp = displayLink.timestamp
        
        if lastTimestamp > 0 {
            frameCount += 1
            let timeDelta = currentTimestamp - lastTimestamp
            
            // 每秒更新一次FPS计算
            if timeDelta >= 1.0 {
                currentFPS = Double(frameCount) / timeDelta
                frameCount = 0
                lastTimestamp = currentTimestamp
            }
        } else {
            lastTimestamp = currentTimestamp
        }
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - 性能快照记录
    private func recordPerformanceSnapshot() {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage.usagePercentage,
            diskUsage: diskUsage.usagePercentage,
            frameRate: frameRate
        )
        
        performanceHistory.append(snapshot)
        
        // 保持历史记录数量限制
        if performanceHistory.count > maxHistoryCount {
            performanceHistory.removeFirst()
        }
    }
    
    // MARK: - 性能警告检查
    private func checkPerformanceWarnings() {
        // CPU使用率过高警告
        if cpuUsage > 80.0 {
            // logger.warning("CPU使用率过高: \(cpuUsage)%")
            sendPerformanceAlert(.highCPU, value: cpuUsage)
        }
        
        // 内存使用率过高警告
        if memoryUsage.usagePercentage > 90.0 {
            // logger.warning("内存使用率过高: \(memoryUsage.usagePercentage)%")
            sendPerformanceAlert(.highMemory, value: memoryUsage.usagePercentage)
        }
        
        // 磁盘空间不足警告
        if diskUsage.usagePercentage > 95.0 {
            // logger.warning("磁盘空间不足: \(diskUsage.usagePercentage)%")
            sendPerformanceAlert(.lowDiskSpace, value: diskUsage.usagePercentage)
        }
        
        // 帧率过低警告
        if frameRate < 30.0 {
            // logger.warning("帧率过低: \(frameRate) FPS")
            sendPerformanceAlert(.lowFrameRate, value: frameRate)
        }
    }
    
    private func sendPerformanceAlert(_ type: PerformanceAlertType, value: Double) {
        NotificationCenter.default.post(
            name: .performanceAlert,
            object: PerformanceAlert(type: type, value: value, timestamp: Date())
        )
    }
    
    // MARK: - 性能分析
    func getPerformanceAnalysis() -> PerformanceAnalysis {
        guard !performanceHistory.isEmpty else {
            return PerformanceAnalysis()
        }
        
        let cpuValues = performanceHistory.map { $0.cpuUsage }
        let memoryValues = performanceHistory.map { $0.memoryUsage }
        let frameRateValues = performanceHistory.map { $0.frameRate }
        
        return PerformanceAnalysis(
            averageCPU: cpuValues.average,
            maxCPU: cpuValues.max() ?? 0,
            averageMemory: memoryValues.average,
            maxMemory: memoryValues.max() ?? 0,
            averageFrameRate: frameRateValues.average,
            minFrameRate: frameRateValues.min() ?? 60,
            totalSamples: performanceHistory.count,
            timeSpan: performanceHistory.last?.timestamp.timeIntervalSince(performanceHistory.first?.timestamp ?? Date()) ?? 0
        )
    }
    
    // MARK: - 设置观察者
    private func setupPerformanceObservers() {
        // 监听应用状态变化
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startMonitoring()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopMonitoring()
            }
            .store(in: &cancellables)
        
        // 监听内存警告
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func handleMemoryWarning() {
        // logger.warning("收到系统内存警告")
        
        // 触发内存清理
        MemoryOptimizer.shared.performEmergencyCleanup()
        
        // 发送内存警告通知
        sendPerformanceAlert(.memoryWarning, value: memoryUsage.usagePercentage)
    }
    
    // MARK: - 导出性能报告
    func exportPerformanceReport() -> String {
        let analysis = getPerformanceAnalysis()
        
        let report = """
        // # 性能监控报告
        
        // ## 生成时间
        \(Date().formatted(.dateTime))
        
        // ## 监控概要
        // - 监控时长: \(String(format: "%.1f", analysis.timeSpan / 60.0)) 分钟
        // - 采样数量: \(analysis.totalSamples) 个
        
        // ## CPU使用情况
        // - 平均使用率: \(String(format: "%.1f", analysis.averageCPU))%
        // - 最高使用率: \(String(format: "%.1f", analysis.maxCPU))%
        
        // ## 内存使用情况
        // - 平均使用率: \(String(format: "%.1f", analysis.averageMemory))%
        // - 最高使用率: \(String(format: "%.1f", analysis.maxMemory))%
        // - 当前使用量: \(String(format: "%.1f", memoryUsage.usedMemoryMB)) MB
        
        // ## 帧率表现
        // - 平均帧率: \(String(format: "%.1f", analysis.averageFrameRate)) FPS
        // - 最低帧率: \(String(format: "%.1f", analysis.minFrameRate)) FPS
        
        // ## 磁盘使用情况
        // - 已使用空间: \(String(format: "%.1f", diskUsage.usedSpaceGB)) GB
        // - 可用空间: \(String(format: "%.1f", diskUsage.availableSpaceGB)) GB
        // - 使用率: \(String(format: "%.1f", diskUsage.usagePercentage))%
        
        // ## 网络统计
        // - 下载速度: \(String(format: "%.1f", networkStats.downloadSpeedKBps)) KB/s
        // - 上传速度: \(String(format: "%.1f", networkStats.uploadSpeedKBps)) KB/s
        """
        
        return report
    }
}

// MARK: - 数据模型
struct MemoryInfo {
    let usedMemoryMB: Double
    let totalMemoryMB: Double
    let usagePercentage: Double
    
    init() {
        self.usedMemoryMB = 0
        self.totalMemoryMB = 0
        self.usagePercentage = 0
    }
    
    init(usedMemoryMB: Double, totalMemoryMB: Double, usagePercentage: Double) {
        self.usedMemoryMB = usedMemoryMB
        self.totalMemoryMB = totalMemoryMB
        self.usagePercentage = usagePercentage
    }
}

struct DiskInfo {
    let usedSpaceGB: Double
    let totalSpaceGB: Double
    let availableSpaceGB: Double
    let usagePercentage: Double
    
    init() {
        self.usedSpaceGB = 0
        self.totalSpaceGB = 0
        self.availableSpaceGB = 0
        self.usagePercentage = 0
    }
    
    init(usedSpaceGB: Double, totalSpaceGB: Double, availableSpaceGB: Double, usagePercentage: Double) {
        self.usedSpaceGB = usedSpaceGB
        self.totalSpaceGB = totalSpaceGB
        self.availableSpaceGB = availableSpaceGB
        self.usagePercentage = usagePercentage
    }
}

struct NetworkStats {
    let downloadSpeedKBps: Double
    let uploadSpeedKBps: Double
    let totalDownloadMB: Double
    let totalUploadMB: Double
    
    init() {
        self.downloadSpeedKBps = 0
        self.uploadSpeedKBps = 0
        self.totalDownloadMB = 0
        self.totalUploadMB = 0
    }
    
    init(downloadSpeedKBps: Double, uploadSpeedKBps: Double, totalDownloadMB: Double, totalUploadMB: Double) {
        self.downloadSpeedKBps = downloadSpeedKBps
        self.uploadSpeedKBps = uploadSpeedKBps
        self.totalDownloadMB = totalDownloadMB
        self.totalUploadMB = totalUploadMB
    }
}

struct PerformanceSnapshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let frameRate: Double
}

struct PerformanceAnalysis {
    let averageCPU: Double
    let maxCPU: Double
    let averageMemory: Double
    let maxMemory: Double
    let averageFrameRate: Double
    let minFrameRate: Double
    let totalSamples: Int
    let timeSpan: TimeInterval
    
    init() {
        self.averageCPU = 0
        self.maxCPU = 0
        self.averageMemory = 0
        self.maxMemory = 0
        self.averageFrameRate = 0
        self.minFrameRate = 0
        self.totalSamples = 0
        self.timeSpan = 0
    }
    
    init(averageCPU: Double, maxCPU: Double, averageMemory: Double, maxMemory: Double, averageFrameRate: Double, minFrameRate: Double, totalSamples: Int, timeSpan: TimeInterval) {
        self.averageCPU = averageCPU
        self.maxCPU = maxCPU
        self.averageMemory = averageMemory
        self.maxMemory = maxMemory
        self.averageFrameRate = averageFrameRate
        self.minFrameRate = minFrameRate
        self.totalSamples = totalSamples
        self.timeSpan = timeSpan
    }
}

enum PerformanceAlertType {
    case highCPU
    case highMemory
    case lowDiskSpace
    case lowFrameRate
    case memoryWarning
}

struct PerformanceAlert {
    let type: PerformanceAlertType
    let value: Double
    let timestamp: Date
}

extension Notification.Name {
    static let performanceAlert = Notification.Name("performanceAlert")
}

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0.0 }
        return reduce(0.0, +) / Double(count)
    }
}

