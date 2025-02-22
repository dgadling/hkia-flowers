import SwiftUI
import ReplayKit

struct BroadcastControlView: View {
    @EnvironmentObject private var broadcastManager: BroadcastManager
    @StateObject private var frameProcessor = FrameProcessor()
    
    var body: some View {
        VStack {
            Button(action: {
                if broadcastManager.isRecording {
                    print("Stopping broadcast...")
                    broadcastManager.stopBroadcast()
                } else {
                    print("Starting broadcast...")
                    broadcastManager.frameDelegate = frameProcessor
                    broadcastManager.startBroadcast()
                }
            }) {
                Image(systemName: broadcastManager.isRecording ? "record.circle.fill" : "record.circle")
                    .font(.title)
                    .foregroundColor(broadcastManager.isRecording ? .red : .gray)
            }
            
            if let image = frameProcessor.lastProcessedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
}
