//
//  file_directory .swift
//  SherpaOnnxTts
//
//  Created by Harsh Bhagat on 10/20/24.
//  kevin 11/28: added UserModels folder to application support dir

import Foundation

// kevin: edited to conform to ObservableObject
class FileDirectory: ObservableObject {
    
    // kevin: URL vars for different directories
    
    var databaseDirectory: URL {
        return applicationSupportDirectory.appendingPathComponent("database", isDirectory: true)
    }
    var documentsDirectory: URL {
        return applicationSupportDirectory.appendingPathComponent("documents", isDirectory: true)
    }
    var audiofilesDirectory: URL {
        return applicationSupportDirectory.appendingPathComponent("audiofiles", isDirectory: true)
    }
    
    var userModelsDirectory: URL {
        return applicationSupportDirectory.appendingPathComponent("UserModels", isDirectory: true)
    }
    
    // New: Base Application Support directory
    private var applicationSupportDirectory: URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
    
    // Create necessary directories inside the Application Support directory
    // This method ensures that "database", "documents", and "audiofiles" directories are created for storing files.
    func createApplicationSupportDirectories() {
        let fileManager = FileManager.default
        let supportURL = applicationSupportDirectory
        
        let databaseDirectory = supportURL.appendingPathComponent("database", isDirectory: true)
        let documentsDirectory = supportURL.appendingPathComponent("documents", isDirectory: true)
        let audiofilesDirectory = supportURL.appendingPathComponent("audiofiles", isDirectory: true)
        let userModelsDirectory = supportURL.appendingPathComponent("UserModels", isDirectory: true)
        
        let protectionAttributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen]
        
        do {
            // Create the necessary directories if they don't exist
            try fileManager.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: protectionAttributes)
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: protectionAttributes)
            try fileManager.createDirectory(at: audiofilesDirectory, withIntermediateDirectories: true, attributes: protectionAttributes)
            try fileManager.createDirectory(at: userModelsDirectory, withIntermediateDirectories: true, attributes: protectionAttributes)

        } catch {
            print("Failed to create Application Support directories: \(error)")
        }
    }
    // kevin: Initialize and create directories when FileDirectory is instantiated
    init() {
        createApplicationSupportDirectories()
    }
    
    // kevin: function to get relative path from a full URL
    func relativePath(for url: URL) -> String {
        let relativePath = url.path.replacingOccurrences(of: applicationSupportDirectory.path + "/", with: "")
        return relativePath
    }
    
    // kevin: Function to get full URL from a relative path
    func fullURL(for relativePath: String) -> URL {
        return applicationSupportDirectory.appendingPathComponent(relativePath)
    }
}
