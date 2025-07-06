/*
 LoadingOverlay
 // 作者: MiniMax Agent
 */

import SwiftUI

/// 加载覆盖层组件
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                // Text("加载中...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
        }
    }
}

#Preview {
    LoadingOverlay()
}
