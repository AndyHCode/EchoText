//
//  ViewModel.swift
//  SherpaOnnxTts
//
//  Created by fangjun on 2023/11/23.
//

import Foundation

// used to get the path to espeak-ng-data
func resourceURL(to path: String) -> String {
    return URL(string: path, relativeTo: Bundle.main.resourceURL)!.path
}

func getResource(_ forResource: String, _ ofType: String) -> String {
    let path = Bundle.main.path(forResource: forResource, ofType: ofType)
    precondition(
        path != nil,
        "\(forResource).\(ofType) does not exist!\n" + "Remember to change \n"
        + "  Build Phases -> Copy Bundle Resources\n" + "to add it!"
    )
    return path!
}

let builtInModelMapping: [String: String] = [
    "amy": "en_US-amy-medium",
    "kristin": "en_US-kristin-medium",
    "arctic": "en_US-arctic-medium",
]

func loadBuiltInModel(modelName: String) -> SherpaOnnxOfflineTtsWrapper {
    guard let modelFileName = builtInModelMapping[modelName] else {
        fatalError("Built-in model mapping not found for \(modelName)")
    }
    
    let model = getResource(modelFileName, "onnx")
    let tokens = getResource("tokens", "txt")
    let dataDir = resourceURL(to: "espeak-ng-data")
    
    let vits = sherpaOnnxOfflineTtsVitsModelConfig(
        model: model, lexicon: "", tokens: tokens, dataDir: dataDir)
    let modelConfig = sherpaOnnxOfflineTtsModelConfig(vits: vits)
    var config = sherpaOnnxOfflineTtsConfig(model: modelConfig)
    
    return SherpaOnnxOfflineTtsWrapper(config: &config)
}

func loadUserImportedModel(modelName: String) -> SherpaOnnxOfflineTtsWrapper {
    let fileDirectory = FileDirectory()
    let modelFileURL = fileDirectory.userModelsDirectory.appendingPathComponent("\(modelName).onnx")
    let fileManager = FileManager.default
    
    // check if the .onnx model file exists
    guard fileManager.fileExists(atPath: modelFileURL.path) else {
        fatalError("Model file not found in user models directory")
    }
    
    // load tokens and dataDir from the default locations
    let tokens = getResource("tokens", "txt")
    let dataDir = resourceURL(to: "espeak-ng-data")
    
    let vits = sherpaOnnxOfflineTtsVitsModelConfig(
        model: modelFileURL.path, lexicon: "", tokens: tokens, dataDir: dataDir)
    let modelConfig = sherpaOnnxOfflineTtsModelConfig(vits: vits)
    var config = sherpaOnnxOfflineTtsConfig(model: modelConfig)
    
    return SherpaOnnxOfflineTtsWrapper(config: &config)
}


// kevin: edit to read from TtsLogic instead of string after env obj merge is complete
func createOfflineTts(model: String) -> SherpaOnnxOfflineTtsWrapper {
    let modelManager = ModelManager.shared
    if builtInModelMapping.keys.contains(model) {
        // built-in model
        return loadBuiltInModel(modelName: model)
    } else if modelManager.userModels.contains(where: { $0.name == model }) {
        // user imported model
        return loadUserImportedModel(modelName: model)
    } else {
        // default to amy if model not found
        return loadBuiltInModel(modelName: "amy")
    }
}
