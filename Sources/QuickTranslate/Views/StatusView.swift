import SwiftUI

struct StatusView: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            Text(isConnected ? "Online" : "Offline")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
