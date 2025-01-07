//
//  AdvancedView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/4/24.
//  Kevin: This page will include settings for advanced features, e.g., reset application settings, etc.

import SwiftUI

struct AdvancedView: View {
    @State private var isModelPickerPresented = false
    @State private var activeAlert: AlertItem?
    @State private var showPickerError = false
    @State private var pickerErrorMessage = ""
    
    @ObservedObject var modelManager = ModelManager.shared
    @EnvironmentObject var voiceProfileManager: VoiceProfileManager
    @EnvironmentObject var fileDirectory: FileDirectory
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // kevin: First Section: Model Import
                Group {
                    Text("Model Import")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        Button(action: {
                            isModelPickerPresented = true
                        }) {
                            HStack {
                                Text("Import Model")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "plus")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // kevin: Second Section: Edit Models
                if !modelManager.userModels.isEmpty {
                    Group {
                        Text("Edit Models")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 0) {
                            ForEach(modelManager.userModels) { modelItem in
                                ModelRow(
                                    modelItem: modelItem,
                                    performRenameModel: performRenameModel,
                                    deleteModel: deleteModel
                                )
                                
                                if modelItem.id != modelManager.userModels.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
                // kevin: Third Section: Reset
                Group {
                    Text("Reset")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        Button(action: {
                            // kevin: implement reset logic later
                        }) {
                            HStack {
                                Text("Reset Settings")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Advanced")
        .sheet(isPresented: $isModelPickerPresented) {
            ModelPicker(
                onModelPicked: { sourceURL in
                    importModel(from: sourceURL)
                },
                showError: $showPickerError,
                errorMessage: $pickerErrorMessage
            )
        }
        .alert(item: $activeAlert) { alertItem in
            switch alertItem.type {
            case .deleteConfirmation(let modelName):
                return Alert(
                    title: Text("Delete Model"),
                    message: Text("Are you sure you want to delete the model \"\(modelName)\"?"),
                    primaryButton: .destructive(Text("Delete")) {
                        performDeleteModel(named: modelName)
                    },
                    secondaryButton: .cancel()
                )
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        // Add alert for picker errors - Andy
        .alert("Error", isPresented: $showPickerError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(pickerErrorMessage)
        }
    }
    
    func importModel(from sourceURL: URL) {
        let fileManager = FileManager.default
        let userModelsDir = fileDirectory.userModelsDirectory
        
        do {
            // kevin: Create UserModels directory if it doesn't exist
            if !fileManager.fileExists(atPath: userModelsDir.path) {
                try fileManager.createDirectory(at: userModelsDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            let modelName = sourceURL.deletingPathExtension().lastPathComponent
            let destinationURL = userModelsDir.appendingPathComponent("\(modelName).onnx")
            
            // kevin: Check if a model with the same name already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                self.activeAlert = AlertItem(type: .error(message: "A model with this name already exists."))
                return
            }
            
            // Attempt to restore access to the source URL using the bookmark - Andy
            if let bookmarkData = UserDefaults.standard.data(forKey: "ModelBookmark-\(sourceURL.lastPathComponent)") {
                var isStale = false
                let resolvedURL = try URL(resolvingBookmarkData: bookmarkData,
                                          options: .withoutUI,
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &isStale)
                
                if resolvedURL.startAccessingSecurityScopedResource() {
                    defer { resolvedURL.stopAccessingSecurityScopedResource() }
                    
                    // Kevin: Copy the .onnx file
                    try fileManager.copyItem(at: resolvedURL, to: destinationURL)
                    
                    // Clean up the bookmark after successful copy - Andy
                    UserDefaults.standard.removeObject(forKey: "ModelBookmark-\(sourceURL.lastPathComponent)")
                    
                    // Kevin: Refresh model list
                    modelManager.loadUserModels()
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to access the model file."])
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate the model file."])
            }
            
        } catch {
            self.activeAlert = AlertItem(type: .error(message: "Failed to import model: \(error.localizedDescription)"))
        }
    }
    func performRenameModel(modelItem: ModelItem) {
        let oldName = modelItem.originalName
        let newName = modelItem.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !newName.isEmpty else {
            // kevin: handle empty name by resetting to original name
            modelItem.name = oldName
            return
        }
        
        guard newName != oldName else {
            return
        }
        
        // kevin: check if newName already exists
        if modelManager.userModels.contains(where: { $0.name == newName && $0.id != modelItem.id }) {
            self.activeAlert = AlertItem(type: .error(message: "A model with the name \"\(newName)\" already exists."))
            modelItem.name = oldName
            return
        }
        
        let fileManager = FileManager.default
        let userModelsDir = fileDirectory.userModelsDirectory
        
        let oldURL = userModelsDir.appendingPathComponent("\(oldName).onnx")
        let newURL = userModelsDir.appendingPathComponent("\(newName).onnx")
        
        do {
            // kevin: rename the file
            try fileManager.moveItem(at: oldURL, to: newURL)
            
            modelItem.originalName = newName
            
            // kevin: if the renamed model was selected, update the selection
            if voiceProfileManager.model == oldName {
                voiceProfileManager.model = newName
            }
            
        } catch {
            self.activeAlert = AlertItem(type: .error(message: "Failed to rename model: \(error.localizedDescription)"))
            // kevin: reset to original name
            modelItem.name = oldName
        }
    }
    
    func deleteModel(modelItem: ModelItem) {
        print("deleteModel called for model: \(modelItem.name)")
        self.activeAlert = AlertItem(type: .deleteConfirmation(modelName: modelItem.name))
    }
    
    func performDeleteModel(named modelName: String) {
        let fileManager = FileManager.default
        let userModelsDir = fileDirectory.userModelsDirectory
        
        let modelURL = userModelsDir.appendingPathComponent("\(modelName).onnx")
        
        do {
            try fileManager.removeItem(at: modelURL)
            
            modelManager.loadUserModels()
            
            if voiceProfileManager.model == modelName {
                voiceProfileManager.model = "amy"
            }
            
        } catch {
            self.activeAlert = AlertItem(type: .error(message: "Failed to delete model: \(error.localizedDescription)"))
        }
    }
}

struct AlertItem: Identifiable {
    enum AlertType {
        case deleteConfirmation(modelName: String)
        case error(message: String)
    }
    
    let id = UUID()
    let type: AlertType
}
