//
//  ModelselectionView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/23/24.
//

import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject var voiceProfileManager: VoiceProfileManager
    @EnvironmentObject var ttsLogic: TtsLogic
    let models = ["amy", "kristin", "arctic"]
    
    var body: some View {
        List(models, id: \.self) { model in
            HStack {
                Text(model)
                Spacer()
                if model == voiceProfileManager.model {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                ttsLogic.changeModel(to: model)
            }
        }
        .navigationTitle("Select Model")
    }
}
