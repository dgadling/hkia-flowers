import SwiftUI

struct BroadcastControlView: View {
    @Binding var isRecording: Bool
    @EnvironmentObject private var broadcastManager: BroadcastManager
    
    var body: some View {
        Button(action: {
            if isRecording {
                broadcastManager.stopBroadcast()
            } else {
                broadcastManager.startBroadcast()
            }
        }) {
            Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
                .font(.title)
                .foregroundColor(isRecording ? .red : .gray)
        }
    }
} 