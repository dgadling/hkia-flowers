import SwiftUI

struct NavigationControlView: View {
    @ObservedObject var viewModel: ImageAnnotationViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                Task {
                    await viewModel.previousImage()
                }
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
            }
            .disabled(viewModel.currentImageIndex <= 0)
            .keyboardShortcut(.leftArrow, modifiers: [])
            
            Text("\(viewModel.currentImageIndex + 1) / \(viewModel.imageURLs.count)")
                .font(.headline)
            
            Button(action: {
                Task {
                    await viewModel.nextImage()
                }
            }) {
                Image(systemName: "arrow.right")
                    .font(.title2)
            }
            .disabled(viewModel.currentImageIndex >= viewModel.imageURLs.count - 1)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }
} 