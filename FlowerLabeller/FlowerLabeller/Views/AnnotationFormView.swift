import SwiftUI

struct AnnotationFormView: View {
    @ObservedObject var viewModel: ImageAnnotationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var speciesFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flower Annotation")
                .font(.headline)
            
            Group {
                TextField("Species", text: $viewModel.currentSpecies)
                    .focused($speciesFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Color", text: $viewModel.currentColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Pattern", text: $viewModel.currentPattern)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Stepper("Quantity: \(viewModel.currentQuantity)", value: $viewModel.currentQuantity, in: 1...100)
            }
            
            HStack {
                Button("Cancel") {
                    viewModel.clearCurrentDrawing()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save") {
                    Task {
                        await viewModel.saveCurrentAnnotation()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(viewModel.currentSpecies.isEmpty || viewModel.currentColor.isEmpty)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.darkGray).opacity(0.7) : Color(.white).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 5)
        .frame(width: 300)
        .onAppear {
            speciesFocused = true
        }
    }
} 