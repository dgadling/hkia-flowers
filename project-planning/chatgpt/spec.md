iOS Companion App for Hello Kitty Island Adventure: Developer Specification

---

## Overview
The iOS companion app will help players of *Hello Kitty Island Adventure* determine which flowers they can grow based on their current inventory. The app will use screen broadcasting to analyze the in-game flower inventory, suggest breeding combinations, and track progress toward collecting all flower types.

---

## Core Features

### 1. Inventory Recognition
- **Screen Broadcast Capture:** The app will utilize the iOS "broadcast screen" feature to capture inventory data.
- **Computer Vision:** Edge detection and template matching will be used to recognize flowers from images.
- **OCR Processing:** When users manually select a flower, OCR will extract additional details from text displayed in-game.
- **On-Device Processing:** All image and text recognition will be handled locally for performance and privacy.

### 2. Inventory Management
- **Categorization:** Flowers will be categorized by species, color, and pattern.
- **Filtering & Sorting:** Users can filter and sort their inventory based on these categories.
- **Automatic Inventory Updates:** New scans will be compared to previous data, highlighting any additions or removals.
- **Manual Adjustments:** Users can manually update items in case of recognition errors.
- **Persistent Storage:** The app will maintain a single up-to-date record of the user’s inventory across sessions.

### 3. Breeding Suggestions
- **Predefined Breeding Rules:** The app will use a programmed set of breeding rules to generate valid combinations.
- **Priority List Generation:** Breeding suggestions will be displayed in a prioritized order, ensuring prerequisite combinations are considered first.
- **Dependency Visualization:** A flowchart or similar visual representation will indicate when a flower type is blocked by another requirement.
- **Detailed Explanations:** Users can tap on a flower type to see possible ways to create it and understand why certain suggestions are made.

### 4. Progress Tracking
- **Completion Progress:** Users can track how many flower types they have collected.
- **Breeding Goals:** Users can save specific breeding goals for future reference.

### 5. User Interface & Experience
- **Inventory List View:** A structured list with search, filters, and sorting options.
- **Breeding Suggestion List:** A prioritized list of breeding recommendations.
- **Visual Dependency Tracking:** Flowchart or an alternative method to indicate breeding prerequisites.
- **Documentation Section:** A help section explaining app functionality.
- **Cute & Colorful UI (Optional):** Aesthetic inspired by *Hello Kitty Island Adventure*.

---

## Technical Architecture

### 1. Data Processing
- **Image Recognition:
  - Edge detection for boundary identification.
  - Template matching for flower type recognition.
  - Resilience to different screen resolutions and lighting conditions.
- **Text Recognition:
  - OCR to extract text from selected flower details.
  - Initial support for English only, with potential for multilingual expansion.
- **Data Comparison:
  - Detect changes between new scans and previous inventory.
  - Identify additions and removals.
- **Breeding Rule Engine:
  - Predefined breeding combinations and dependencies.
  - Algorithm to generate prioritized breeding paths.

### 2. Data Storage
- **Local Database:
  - Store the latest inventory state.
  - Maintain breeding goals and progress.
- **No Cloud Storage:
  - All data is stored on-device for privacy.

### 3. User Interaction & UI Components
- **SwiftUI / UIKit (Flexible Choice)
- **Views:
  - Inventory List View
  - Breeding Suggestion List View
  - Dependency Flowchart View
  - Documentation Section
- **Gestures & Navigation:
  - Tap to view breeding explanations.
  - Scroll through lists.
  - Manual inventory adjustments.

---

## Error Handling & Edge Cases

### 1. Recognition Errors
- **Image Recognition Uncertainty:
  - Provide a confidence score for detected flowers.
  - Allow manual correction if recognition is incorrect.
- **OCR Misreads:
  - Implement post-processing corrections for common errors.
  - Allow users to manually edit text-based data.

### 2. Inventory Mismatches
- **Handling Missing Flowers:
  - Notify users if expected flowers are missing after a scan.
- **Duplicate Entries:
  - Avoid double-counting flowers across multiple scans.

### 3. Breeding Logic Issues
- **Blocked Breeding Paths:
  - Clearly indicate dependencies preventing a flower from being bred.
- **Conflicting Data:
  - Resolve discrepancies between new scans and previously saved inventory.

### 4. App Functionality Failures
- **Screen Broadcast Failures:
  - Display troubleshooting steps if the app fails to receive screen data.
- **Crashes & Unexpected Behavior:
  - Implement error logging for debugging.

---

## Testing Plan

### 1. Unit Testing
- **OCR Accuracy:** Verify that extracted text matches the in-game display.
- **Computer Vision Performance:** Ensure correct flower detection under various conditions.
- **Breeding Rule Validation:** Confirm correct generation of prioritized breeding paths.

### 2. Integration Testing
- **Screen Broadcast Input Handling:** Validate that the app correctly receives and processes screen data.
- **Data Persistence:** Ensure that inventory and breeding goals are correctly saved between sessions.

### 3. User Testing
- **Usability Testing:** Gather feedback on UI and interactions.
- **Edge Case Testing:** Identify failure points in recognition and data handling.

---

## Future Considerations
- **Multilingual OCR support.
- **Additional filtering/sorting options for large inventories.
- **Expanded visualizations for breeding suggestions.
- **Periodic updates to accommodate new flowers and rule changes.

---
**iOS Companion App for Hello Kitty Island Adventure: Developer Specification & Implementation Blueprint**

---

## **Overview**
The iOS companion app will help players of *Hello Kitty Island Adventure* determine which flowers they can grow based on their current inventory. The app will use screen broadcasting to analyze the in-game flower inventory, suggest breeding combinations, and track progress toward collecting all flower types.

---

## **Core Features**

### **1. Inventory Recognition**
- **Screen Broadcast Capture:** The app will utilize the iOS "broadcast screen" feature to capture inventory data.
- **Computer Vision:** Edge detection and template matching will be used to recognize flowers from images.
- **OCR Processing:** When users manually select a flower, OCR will extract additional details from text displayed in-game.
- **On-Device Processing:** All image and text recognition will be handled locally for performance and privacy.

### **2. Inventory Management**
- **Categorization:** Flowers will be categorized by species, color, and pattern.
- **Filtering & Sorting:** Users can filter and sort their inventory based on these categories.
- **Automatic Inventory Updates:** New scans will be compared to previous data, highlighting any additions or removals.
- **Manual Adjustments:** Users can manually update items in case of recognition errors.
- **Persistent Storage:** The app will maintain a single up-to-date record of the user’s inventory across sessions.

### **3. Breeding Suggestions**
- **Predefined Breeding Rules:** The app will use a programmed set of breeding rules to generate valid combinations.
- **Priority List Generation:** Breeding suggestions will be displayed in a prioritized order, ensuring prerequisite combinations are considered first.
- **Dependency Visualization:** A flowchart or similar visual representation will indicate when a flower type is blocked by another requirement.
- **Detailed Explanations:** Users can tap on a flower type to see possible ways to create it and understand why certain suggestions are made.

### **4. Progress Tracking**
- **Completion Progress:** Users can track how many flower types they have collected.
- **Breeding Goals:** Users can save specific breeding goals for future reference.

### **5. User Interface & Experience**
- **Inventory List View:** A structured list with search, filters, and sorting options.
- **Breeding Suggestion List:** A prioritized list of breeding recommendations.
- **Visual Dependency Tracking:** Flowchart or an alternative method to indicate breeding prerequisites.
- **Documentation Section:** A help section explaining app functionality.
- **Cute & Colorful UI (Optional):** Aesthetic inspired by *Hello Kitty Island Adventure*.
