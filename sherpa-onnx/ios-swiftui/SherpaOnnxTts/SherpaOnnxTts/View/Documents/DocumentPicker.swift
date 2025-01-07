//
//  DocumentPicker.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 10/8/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var importedPdfs: [URL]
    @EnvironmentObject var DB: Database
    var fileDirectory: FileDirectory
    
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    var onPdfPicked: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                // Start accessing the security-scoped resource - Andy
                guard url.startAccessingSecurityScopedResource() else {
                    DispatchQueue.main.async {
                        self.parent.errorMessage = "Unable to access the selected file."
                        self.parent.showError = true
                    }
                    return
                }
                
                // Ensure that we stop accessing the resource when done - Andy
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    // First ensure documents directory exists - Andy
                    try FileManager.default.createDirectory(at: parent.fileDirectory.documentsDirectory,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                    
                    print("Documents directory: \(parent.fileDirectory.documentsDirectory.path)")
                    
                    // Check file size - Andy
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    // 50MB limit
                    let maxSize: Int64 = 50 * 1024 * 1024
                    
                    guard fileSize <= maxSize else {
                        DispatchQueue.main.async {
                            self.parent.errorMessage = "File is too large. Maximum size is 50MB."
                            self.parent.showError = true
                        }
                        return
                    }
                    
                    let uniqueFilename = self.generateUniqueFilename(originalName: url.lastPathComponent)
                    let destinationUrl = parent.fileDirectory.documentsDirectory.appendingPathComponent(uniqueFilename)
                    
                    print("Copying file to: \(destinationUrl.path)")
                    
                    if FileManager.default.fileExists(atPath: destinationUrl.path) {
                        try FileManager.default.removeItem(at: destinationUrl)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: destinationUrl)
                    
                    // Verify file was copied - Andy
                    guard FileManager.default.fileExists(atPath: destinationUrl.path) else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to copy file"])
                    }
                    
                    // kevin: Get the relative path using FileDirectory
                    let relativePath = parent.fileDirectory.relativePath(for: destinationUrl)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    let uploadDate = dateFormatter.string(from: Date())
                    
                    print("Inserting document into database with relative path: \(relativePath)")
                    parent.DB.insertDocument(
                        documentName: url.lastPathComponent,
                        uploadDate: uploadDate,
                        // kevin: updated to use the relative path here
                        filePath: relativePath,
                        fileType: "pdf"
                    )
                    
                    DispatchQueue.main.async {
                        self.parent.onPdfPicked(destinationUrl)
                    }
                    
                } catch {
                    print("Error processing document: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.parent.errorMessage = "Error importing document: \(error.localizedDescription)"
                        self.parent.showError = true
                    }
                }
            }
        }
        
        private func generateUniqueFilename(originalName: String) -> String {
            let fileManager = FileManager.default
            let documentsDirectory = parent.fileDirectory.documentsDirectory
            let originalNameWithoutExtension = (originalName as NSString).deletingPathExtension
            let fileExtension = (originalName as NSString).pathExtension
            
            // First try with the original name - Andy
            var finalName = originalName
            var counter = 1
            
            // Keep trying until we find a name that doesn't exist - Andy
            while fileManager.fileExists(atPath: documentsDirectory.appendingPathComponent(finalName).path) {
                finalName = "\(originalNameWithoutExtension) (\(counter)).\(fileExtension)"
                counter += 1
            }
            
            return finalName
        }
    }
}
