//
//  ModelPicker.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/27/24.
//  kevin: struct that modifies the default document picker UI to import model folders

import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension UTType {
    static var onnx: UTType {
        UTType(filenameExtension: "onnx") ?? UTType.data
    }
}

struct ModelPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onModelPicked: (URL) -> Void
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.onnx])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: ModelPicker
        
        init(_ parent: ModelPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let sourceURL = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard sourceURL.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async {
                    self.parent.errorMessage = "Unable to access the selected file."
                    self.parent.showError = true
                }
                return
            }
            
            // Create a bookmark for persistent access - Andy
            do {
                let bookmarkData = try sourceURL.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                
                // Store the bookmark data - Andy
                UserDefaults.standard.set(bookmarkData, forKey: "ModelBookmark-\(sourceURL.lastPathComponent)")
                
                DispatchQueue.main.async {
                    self.parent.onModelPicked(sourceURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.parent.errorMessage = "Error creating persistent access: \(error.localizedDescription)"
                    self.parent.showError = true
                }
            }
            
            // Ensure we stop accessing the resource - Andy
            sourceURL.stopAccessingSecurityScopedResource()
            
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
