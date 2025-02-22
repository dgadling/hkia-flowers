# 1. Setup Training Environment
First, create our directory structure:
```
mkdir -p ~/FlowerTraining/{raw_screenshots,labeled_data,training,testing}
cd ~/FlowerTraining
```

# 2. Gather Training Data
1. Launch the game on your iOS device
2. Enable screen recording in Control Center:
    - Settings → Control Center → Add Screen Recording
3. Use our `BroadcastControlView `to capture frames:
4. For each flower type:
    1. Navigate to the flower in game
    2. Start recording (red button)
    3. Wait 2-3 seconds
    4. Stop recording
    5. The frames will be processed by `FrameProcessor`
5. Export the captured frames:
```bash
# From your iOS device, AirDrop the images to your Mac
# Move them to the raw_screenshots directory
mv ~/Downloads/*.{jpg,png} ~/FlowerTraining/raw_screenshots/
```

# 3. Label Training Data
1. Launch `FlowerLabeler` app
2. Click "Select Images Folder" and choose `~/FlowerTraining/raw_screenshots`
3. For each image:
    1. Draw box around each flower (click and drag)
    2. Label each box with flower type (e.g., "red_rose", "white_lily")
    3. Click "Next Image" after labeling all flowers
    4. Repeat until all images are labeled
4. Export annotations:
    1. Click "Export Annotations"
    2. This creates `annotations.json` in Create ML format

# 4. Prepare Training/Testing Split
```bash
cd ~/FlowerTraining

# Create directories
mkdir -p training/images testing/images

# Split data (80/20)
ls raw_screenshots/*.jpg | sort -R | head -n $(ls raw_screenshots/*.jpg | wc -l | xargs -I {} echo "{} * 0.8" | bc) | xargs -I {} cp {} training/images/
ls raw_screenshots/*.jpg | sort -R | tail -n $(ls raw_screenshots/*.jpg | wc -l | xargs -I {} echo "{} * 0.2" | bc) | xargs -I {} cp {} testing/images/

# Copy annotations
cp annotations.json training/
cp annotations.json testing/
```

# 5. Train Model
1. Open Create ML app: `open -a "Create ML"`
2. In Create ML:
    1. New Document → Object Detection
    2. Project Name: FlowerDetector
    3. Add training data:
        - Drag `~/FlowerTraining/training/images` folder
        - Drag `~/FlowerTraining/training/annotations.json`
    4. Add testing data:
        - Drag `~/FlowerTraining/testing/images` folder
        - Drag `~/FlowerTraining/testing/annotations.json`
    5. Configure training:
        - **Algorithm**: Transfer Learning
        - **Iterations**: 2000
        - **Training Steps per Iteration**: 20
        - **Neural Network**: Vision Feature Print
3. Click "Train"
4. When complete, review metrics:
    - Precision
    - Recall
    - Training Error
    - Validation Error

# 6. Export and Integrate Model
1. In Create ML
    1. Click "Get"
    2. Save as `FlowerDetector.mlmodel` in `~/FlowerTraining`
2. Add to Xcode project:
    1. Drag `FlowerDetector.mlmodel` into `FlowerBreeder` project
    2. Check "Copy items if needed"
    3. Add to main target
    4. The model will be used by `FlowerMLDetector`
