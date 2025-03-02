import Foundation

extension FileManager {
    
    /// Get the documents directory for the app, which is accessible through Files app and Finder
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Creates a directory at the specified path if it doesn't exist
    /// - Parameter path: The path where to create the directory
    /// - Returns: Success or failure
    @discardableResult
    static func createDirectoryIfNeeded(at path: URL) -> Bool {
        do {
            if !FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                return true
            }
            return true
        } catch {
            print("❌ Error creating directory: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Move a file from the app group container to the documents directory
    /// - Parameters:
    ///   - sourceURL: Source file URL in the app group container
    ///   - destinationFolder: Folder in documents directory to move to
    /// - Returns: The URL of the moved file, or nil if failed
    static func moveToDocuments(from sourceURL: URL, toFolder destinationFolder: String) -> URL? {
        let docsDir = FileManager.documentsDirectory
        let destinationDirURL = docsDir.appendingPathComponent(destinationFolder, isDirectory: true)
        
        // Create the destination directory if needed
        if !FileManager.createDirectoryIfNeeded(at: destinationDirURL) {
            return nil
        }
        
        let fileName = sourceURL.lastPathComponent
        let destinationURL = destinationDirURL.appendingPathComponent(fileName)
        
        do {
            // Remove the file if it already exists at destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Move the file instead of copying
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("❌ Error moving file to documents: \(error.localizedDescription)")
            return nil
        }
    }
} 