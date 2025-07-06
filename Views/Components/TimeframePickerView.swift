/*
 TimeframePickerView
 // 作者: MiniMax Agent
 */

import SwiftUI

 // Timeframe Picker View
 // Select timeframe for candlestick chart
struct TimeframePickerView: View {
    @Binding var selectedTimeframe: String
    
    private let timeframes = [
        // ("1s", "1秒"),
        // ("1m", "1分钟"),
        // ("5m", "5分钟"),
        // ("15m", "15分钟"),
        // ("1h", "1小时"),
        // ("1d", "日线")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text("时间周期")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timeframes, id: \.0) { timeframe in
                        TimeframeButton(
                            code: timeframe.0,
                            name: timeframe.1,
                            isSelected: selectedTimeframe == timeframe.0
                        ) {
                            selectedTimeframe = timeframe.0
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TimeframeButton: View {
    let code: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TimeframePickerView(selectedTimeframe: .constant("1m"))
        .padding()
}