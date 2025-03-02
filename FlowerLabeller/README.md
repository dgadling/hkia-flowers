# FlowerLabeller

A macOS application for labeling images of flowers to train machine learning models with Create ML.

## Features

- Select a directory of JPG images
- Navigate through images using keyboard shortcuts or buttons
- Draw bounding boxes around flowers in images
- Add annotations with species, color, pattern, and quantity
- Export annotations in Create ML compatible format

## Usage

1. **Select Directory**: Open the app and click "Select Directory" to choose a folder of JPG images
2. **Draw Rectangles**: Click and drag to draw a rectangle around a flower
3. **Add Annotations**: Fill in the flower details in the form that appears
4. **Navigate Images**: Use left/right arrow keys or the navigation controls to move between images
5. **Export Data**: Click "Export Annotations" to save the data for Create ML

## Keyboard Shortcuts

- **Cmd+O**: Select directory
- **Cmd+E**: Export annotations
- **Left/Right Arrow**: Navigate between images
- **Space**: Move to next image
- **Enter**: Save current annotation and move to next image
- **Escape**: Cancel current annotation

## Create ML Integration

The exported annotations.json file is formatted for direct use with Create ML's object detection models. Follow these steps:

1. Open Create ML and create a new Object Detection project
2. Drag your images folder and the exported annotations.json file
3. Configure training settings and train your model

## Requirements

- macOS 11.0 or later
- Xcode 13.0 or later (for development) 