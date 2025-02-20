# Project Blueprint
## Step 1: Set up the Development Environment
- Install Xcode and Swift
- Set up Core ML for image recognition
- Create a new Xcode project for the companion app
## Step 2: Design the Data Model
- Define the data structure for storing flower information (species, color, pattern, quantity)
- Create a data model using a suitable database (e.g., SQLite)
## Step 3: Implement Inventory Management
- Create a UI for displaying the user's flower inventory
- Implement filtering, searching, and sorting features
- Allow users to manually add and edit flower entries
## Step 4: Develop the Core ML Model
- Collect and label ~1,000-2,000 flower images
- Train a custom Core ML model for image recognition
- Integrate the model into the app
## Step 5: Implement Broadcast Screen Integration
- Use iOS screen recording feature to capture game screens
- Process captured images to detect and extract flower information
- Update existing flower entries in the inventory
## Step 6: Implement Combination Logic and Suggestions
- Define flower combination rules based on species, color, and pattern
- Provide suggestions for possible combinations based on user's inventory
## Step 7: Implement Wishlist and Favorites
- Allow users to mark flowers as favorites or add to wishlist
- Display wishlist and favorites separately
## Step 8: Implement Analytics, Crash Reporting, and Feedback
- Integrate analytics tools (e.g., Google Analytics)
- Implement crash reporting (e.g., Crashlytics)
- Add in-app feedback mechanism
## Step 9: Test and Refine the App
- Perform unit testing, integration testing, and UI testing
- Refine the app based on testing results

# Iterative Chunks
## Chunk 1: Set up Development Environment and Data Model
### Step 1.1: Install Xcode and Swift
```swift
// Install Xcode and Swift
// Verify installation
```
### Step 1.2: Set up Core ML
```swift
// Import Core ML framework
import CoreML

// Verify Core ML setup
```
### Step 1.3: Create Data Model
```swift
// Define data structure for flower information
struct Flower {
    let species: String
    let color: String
    let pattern: String
    let quantity: Int
}

// Create data model using SQLite
// Verify data model creation
```
## Chunk 2: Implement Inventory Management
### Step 2.1: Create UI for Inventory Display
```swift
// Create UI for displaying flower inventory
// Verify UI creation
```
### Step 2.2: Implement Filtering and Sorting
```swift
// Implement filtering and sorting features
// Verify filtering and sorting functionality
```
### Step 2.3: Allow Manual Entry and Editing
```swift
// Allow users to manually add and edit flower entries
// Verify manual entry and editing functionality
```
## Chunk 3: Develop Core ML Model
### Step 3.1: Collect and Label Flower Images
```swift
// Collect and label ~1,000-2,000 flower images
// Verify image collection and labeling
```
### Step 3.2: Train Core ML Model
```swift
// Train custom Core ML model for image recognition
// Verify model training
```
### Step 3.3: Integrate Core ML Model
```swift
// Integrate trained Core ML model into the app
// Verify model integration
```
## Chunk 4: Implement Broadcast Screen Integration
### Step 4.1: Use iOS Screen Recording Feature
```swift
// Use iOS screen recording feature to capture game screens
// Verify screen recording functionality
```
### Step 4.2: Process Captured Images
```swift
// Process captured images to detect and extract flower information
// Verify image processing functionality
```
### Step 4.3: Update Existing Flower Entries
```swift
// Update existing flower entries in the inventory
// Verify flower entry updating functionality
```
## Chunk 5: Implement Combination Logic and Suggestions
### Step 5.1: Define Flower Combination Rules
```swift
// Define flower combination rules based on species, color, and pattern
// Verify rule definition
```
### Step 5.2: Provide Suggestions
```swift
// Provide suggestions for possible combinations based on user's inventory
// Verify suggestion functionality
```
## Chunk 6: Implement Wishlist and Favorites
### Step 6.1: Allow Users to Mark Favorites
```swift
// Allow users to mark flowers as favorites
// Verify favorite marking functionality
```
### Step 6.2: Display Wishlist and Favorites
```swift
// Display wishlist and favorites separately
// Verify wishlist and favorite display functionality
```
## Chunk 7: Implement Analytics, Crash Reporting, and Feedback
### Step 7.1: Integrate Analytics Tools
```swift
// Integrate analytics tools (e.g., Google Analytics)
// Verify analytics integration
```
### Step 7.2: Implement Crash Reporting
```swift
// Implement crash reporting (e.g., Crashlytics)
// Verify crash reporting functionality
```
### Step 7.3: Add In-App Feedback Mechanism
```swift
// Add in-app feedback mechanism
// Verify feedback mechanism functionality
```
## Chunk 8: Test and Refine the App
### Step 8.1: Perform Unit Testing
```swift
// Perform unit testing for each feature
// Verify unit testing results
```
### Step 8.2: Perform Integration Testing
```swift
// Perform integration testing for each feature
// Verify integration testing results
```
### Step 8.3: Perform UI Testing
```swift
// Perform UI testing for each feature
// Verify UI testing results
```
### Step 8.4: Refine the App
```swift
// Refine the app based on testing results
// Verify app refinement
```
# Code Generation Prompts
## Prompt 1: Set up Development Environment
```swift
// Set up Xcode and Swift development environment
// Import Core ML framework
import CoreML
```
## Prompt 2: Create Data Model
```swift
// Define data structure for flower information
struct Flower {
    let species: String
    let color: String
    let pattern: String
    let quantity: Int
}

// Create data model using SQLite
```
## Prompt 3: Implement Inventory Management

```swift
// Create UI for displaying flower inventory
// Implement filtering and sorting features
// Allow users to manually add and edit flower entries
```
## Prompt 4: Develop Core ML Model
```swift
// Collect and label ~1,000-2,000 flower images
// Train custom Core ML model for image recognition
// Integrate trained Core ML model into the app
```
## Prompt 5: Implement Broadcast Screen Integration
```swift
// Use iOS screen recording feature to capture game screens
// Process captured images to detect and extract flower information
// Update existing flower entries in the inventory
```
## Prompt 6: Implement Combination Logic and Suggestions
```swift
// Define flower combination rules based on species, color, and pattern
// Provide suggestions for possible combinations based on user's inventory
```
## Prompt 7: Implement Wishlist and Favorites
```swift
// Allow users to mark flowers as favorites
// Display wishlist and favorites separately
```
## Prompt 8: Implement Analytics, Crash Reporting, and Feedback
```swift
// Integrate analytics tools (e.g., Google Analytics)
// Implement crash reporting (e.g., Crashlytics)
// Add in-app feedback mechanism
```

## Prompt 9: Test and Refine the App
```swift
// Perform unit testing, integration testing, and UI testing
// Refine the app based on testing results
```
