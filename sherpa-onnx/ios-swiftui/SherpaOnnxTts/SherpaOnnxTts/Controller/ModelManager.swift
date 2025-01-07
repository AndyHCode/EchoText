//
//  ModelManager.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/27/24.
//  kevin: handles user imported models

import Foundation
import SwiftUI

class ModelManager: ObservableObject {
    static let shared = ModelManager()
    @Published var userModels: [ModelItem] = []
    var fileDirectory = FileDirectory()
    init() {
        loadUserModels()
    }
    
    func loadUserModels() {
        DispatchQueue.global(qos: .background).async {
            let userModelsURL = self.fileDirectory.userModelsDirectory
            var models: [ModelItem] = []
            do {
                let modelURLs = try FileManager.default.contentsOfDirectory(
                    at: userModelsURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                models = modelURLs
                    .filter { $0.pathExtension == "onnx" }
                    .map { ModelItem(name: $0.deletingPathExtension().lastPathComponent) }
            } catch {
                print("Error fetching imported models: \(error)")
            }
            DispatchQueue.main.async {
                self.userModels = models
            }
        }
    }
}

