# FlowerFriend

A screensharing extension that captures frames for machine learning.

## Accessing Captured Frames

FlowerFriend saves captured frames in a way that makes them accessible through both the Files app on iOS and the Finder on macOS. Here's how to access them:

### On iPhone/iPad:

1. Open the **Files** app
2. Navigate to **On My iPhone** or **On My iPad**
3. Tap on the **FlowerFriend** folder
4. The **captured_frames** folder contains all saved frames

Alternatively, you can tap the "Files" button (folder icon) in the app's navigation bar to open the Files app directly to the app's documents directory.

### On Mac via Finder:

To access the captured frames on your Mac:

1. Connect your iPhone to your Mac with a cable
2. Open **Finder**
3. Select your iPhone in the sidebar
4. Click on the **Files** tab
5. Select **FlowerFriend** from the list of apps
6. Navigate to the **captured_frames** folder

You can also use AirDrop, iCloud Drive, or any other method to share the files from your device to your Mac.

### Using the App

The app provides two ways to ensure files are accessible:

1. Files are saved directly to the app's Documents directory, which is shared with the Files app
2. A "Refresh" button in the app syncs any files from the broadcast extension to the Documents directory

If you don't see your files, try tapping the "Refresh" button in the app's navigation bar.

## Development

This app uses an App Group container to share data between the main app and the broadcast extension. Files are automatically copied from the App Group container to the app's Documents directory to ensure they're accessible through Finder.

## Important Notes
- Files are saved in the app Documents directory to ensure they are accessible via File Sharing
- If you don't see the FlowerFriend app in Finder, you might need to rebuild and reinstall the app after the recent changes 