//
//  SpeechSettingsView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/4/24.
//  Kevin: This page will include settings related to speach generation, e.g. models, pitch, voice profiles etc
import SwiftUI

// Kevin: struct for the speech settings subpage
struct SpeechSettingsView: View {
    @EnvironmentObject var voiceProfileManager: VoiceProfileManager
    // Kevin: local state for the tone slider, change to use ttsLogic when implemented
    
    @EnvironmentObject var ttsLogic: TtsLogic
    @ObservedObject var modelManager = ModelManager.shared
    @EnvironmentObject var fileDirectory: FileDirectory
    
    @State private var isModelPickerPresented = false
    
    let defaultModels = ["amy", "kristin", "arctic"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 0) {
                    NavigationLink(destination: VoiceProfileSelectionView()) {
                        HStack {
                            Text("Voice Profile")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(voiceProfileManager.profileName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                
                VStack(spacing: 0) {
                    Menu {
                        let allModels = defaultModels.map { ModelItem(name: $0) } + modelManager.userModels
                        
                        ForEach(allModels) { modelItem in
                            Button(action: {
                                voiceProfileManager.model = modelItem.name
                                ttsLogic.changeModel(to: modelItem.name)
                            }) {
                                HStack {
                                    Text(modelItem.name)
                                    if modelItem.name == voiceProfileManager.model {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Select Model")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(voiceProfileManager.model)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // kevin: speed slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Speed: \(String(format: "%.1f", voiceProfileManager.speed))")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Slider(value: $voiceProfileManager.speed, in: 0.5...1.5, step: 0.1)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    // Kevin: tone slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Pitch: \(String(format: "%.1f", voiceProfileManager.pitch))")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Slider(value: $voiceProfileManager.pitch, in: 0.5...2.0, step: 0.1)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.top, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Speech Settings")
        .onAppear {
            validateCurrentModel()
        }
    }
    
    func validateCurrentModel() {
        let allModels = defaultModels + modelManager.userModels.map { $0.name }
        if !allModels.contains(voiceProfileManager.model) {
            voiceProfileManager.model = "amy"
        }
    }
}
