import SwiftUI

struct HelpView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("FlowerLabeller Help")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    workflowSection
                    keyboardShortcutsSection
                    drawingInstructionsSection
                    exportInstructionsSection
                }
                .padding(.bottom, 20)
            }
            
            Button("Close") {
                isPresented = false
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
        .frame(width: 600, height: 500)
        .background(colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workflow")
                .font(.headline)
            
            Text("1. Select a directory of images using the \"Select Directory\" button")
            Text("2. For each image, draw rectangles around flowers by clicking and dragging")
            Text("3. Fill in the flower species, color, pattern, and quantity details")
            Text("4. Save each annotation and proceed to the next image")
            Text("5. When done, export the annotations as a JSON file")
        }
    }
    
    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Space").bold()
                    Text("Go to next image")
                }
                GridRow {
                    Text("← →").bold()
                    Text("Navigate between images")
                }
                GridRow {
                    Text("Return/Enter").bold()
                    Text("Save annotation and go to next image")
                }
                GridRow {
                    Text("Escape").bold()
                    Text("Cancel current annotation")
                }
                GridRow {
                    Text("⌘O").bold()
                    Text("Select new directory")
                }
                GridRow {
                    Text("⌘E").bold()
                    Text("Export annotations")
                }
                GridRow {
                    Text("?").bold()
                    Text("Show/hide this help")
                }
            }
        }
    }
    
    private var drawingInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drawing Annotations")
                .font(.headline)
            
            Text("• Click and drag on the image to draw a rectangle around a flower")
            Text("• The rectangle will be highlighted in yellow while drawing")
            Text("• Once you release the mouse, you'll be prompted to enter flower details")
            Text("• Saved annotations appear as green rectangles with labels")
            Text("• Very small rectangles (less than 10x10 pixels) are ignored")
        }
    }
    
    private var exportInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exporting Annotations")
                .font(.headline)
            
            Text("• Click the \"Export Annotations\" button to save your work")
            Text("• Annotations are saved in a format compatible with Create ML")
            Text("• The JSON file contains all annotations for all images in the directory")
            Text("• You can continue annotating after exporting")
        }
    }
}

#Preview {
    HelpView(isPresented: .constant(true))
} 